import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../notifications/notification_service.dart';
import '../utils/app_logger.dart';

/// Safely parse an int from a dynamic value (handles String, num, null).
int _safeInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// Safely parse a nullable int from a dynamic value.
int? _safeIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Analysis status enum
enum AnalysisStatus {
  pending,
  processing,
  completed,
  failed;

  static AnalysisStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'pending':
        return AnalysisStatus.pending;
      case 'processing':
        return AnalysisStatus.processing;
      case 'completed':
        return AnalysisStatus.completed;
      case 'failed':
        return AnalysisStatus.failed;
      default:
        return AnalysisStatus.pending;
    }
  }

  bool get isInProgress => this == pending || this == processing;
  bool get isCompleted => this == completed;
  bool get isFailed => this == failed;
}

/// Update emitted by the service-level polling loop
class AnalysisJobUpdate {
  final int analysisId;
  final AnalysisStatus status;
  final AnalysisResult? result;

  AnalysisJobUpdate({
    required this.analysisId,
    required this.status,
    this.result,
  });

  bool get isTerminal => status.isCompleted || status.isFailed;
}

/// Service for AI analysis operations
class AnalysisService {
  AnalysisService._();
  static final AnalysisService instance = AnalysisService._();
  final ApiClient _api = ApiClient.instance;

  /// Default polling interval
  static const Duration _pollInterval = Duration(seconds: 3);

  /// Default timeout for analysis completion
  static const Duration _analysisTimeout = Duration(minutes: 7);

  // ═══════════════════════════════════════════════════════════════════════════
  // SERVICE-LEVEL POLLING (survives navigation)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Broadcast stream for job updates — any screen can subscribe
  final _jobUpdates = StreamController<AnalysisJobUpdate>.broadcast();
  Stream<AnalysisJobUpdate> get jobUpdates => _jobUpdates.stream;

  /// Currently active polling futures (prevents GC + avoids duplicate polls)
  final Map<int, Future<void>> _activePolls = {};

  /// Active analysis IDs notifier for UI indicators
  final ValueNotifier<Set<int>> activeAnalysisIds = ValueNotifier<Set<int>>({});

  /// Start service-level polling for an analysis.
  /// The polling loop runs in the singleton, not in a widget.
  /// Listen to [jobUpdates] for progress/completion from any screen.
  void startServicePolling(int analysisId) {
    if (_activePolls.containsKey(analysisId)) return;

    activeAnalysisIds.value = {...activeAnalysisIds.value, analysisId};

    _activePolls[analysisId] = _servicePollLoop(analysisId).whenComplete(() {
      _activePolls.remove(analysisId);
      activeAnalysisIds.value = {...activeAnalysisIds.value}..remove(analysisId);
    });
  }

  Future<void> _servicePollLoop(int analysisId) async {
    final deadline = DateTime.now().add(_analysisTimeout);
    int consecutiveErrors = 0;

    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(_pollInterval);

      try {
        final response = await _api.get(Endpoints.analysisById(analysisId));
        consecutiveErrors = 0; // Reset on success

        // api.md §6.2: poll responses contain `status` directly (no `success`
        // envelope). Treat absence of `status` as a malformed response and
        // keep polling rather than terminating.
        final rawStatus = response['status'];
        if (rawStatus == null) continue;
        final status = AnalysisStatus.fromString(rawStatus.toString());

        if (status.isCompleted) {
          final data = response['data'] as Map<String, dynamic>?;
          final photoPrompts = (response['photo_prompts'] as List<dynamic>?)
                  ?.map((e) => PhotoPrompt.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [];

          final result = AnalysisResult.success(
            analysisId: analysisId,
            data: ProfileAnalysisData.fromJson(data ?? {}),
            photoPrompts: photoPrompts,
            rawData: data,
          );

          _jobUpdates.add(AnalysisJobUpdate(
            analysisId: analysisId,
            status: status,
            result: result,
          ));

          // Fire local notification
          await NotificationService.instance.showAnalysisComplete(
            jobId: analysisId.toString(),
            analysisId: analysisId,
            message: 'Your profile analysis is ready!',
          );
          return;
        }

        if (status.isFailed) {
          final errMsg = _extractString(response['error']) ?? 'analysis.failed';
          _jobUpdates.add(AnalysisJobUpdate(
            analysisId: analysisId,
            status: status,
            result: AnalysisResult.error(errMsg),
          ));
          return;
        }

        // Still in progress — emit progress
        _jobUpdates.add(AnalysisJobUpdate(
          analysisId: analysisId,
          status: status,
        ));
      } on NetworkException {
        consecutiveErrors++;
      } on TransientServerException {
        // 502/503/504 from the edge — job in worker is unaffected, retry.
        consecutiveErrors++;
      } on ApiException catch (e) {
        // 500 (app-emitted, terminal) is the only 5xx that ends polling.
        if (e.statusCode == 500) {
          _jobUpdates.add(AnalysisJobUpdate(
            analysisId: analysisId,
            status: AnalysisStatus.failed,
            result: AnalysisResult.error('analysis.server_error'),
          ));
          return;
        }
        consecutiveErrors++;
      } catch (e) {
        AppLogger.e('Service poll error for $analysisId', error: e);
        consecutiveErrors++;
      }

      if (consecutiveErrors >= 10) {
        _jobUpdates.add(AnalysisJobUpdate(
          analysisId: analysisId,
          status: AnalysisStatus.failed,
          result: AnalysisResult.error('analysis.network_error'),
        ));
        return;
      }
    }

    // Timeout
    _jobUpdates.add(AnalysisJobUpdate(
      analysisId: analysisId,
      status: AnalysisStatus.failed,
      result: AnalysisResult.error('analysis.timeout'),
    ));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROFILE ANALYSIS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Submit profile screenshots for AI analysis and poll until completion
  /// Cost: 1 credit
  ///
  /// [onProgress] callback is called during polling with current status
  Future<AnalysisResult> analyzeProfile({
    required List<String> screenshotUrls,
    String language = 'en',
    String? countryCode,
    String? countryName,
    void Function(AnalysisStatus status)? onProgress,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'screenshots': screenshotUrls,
        'language': language,
      };

      if (countryCode != null || countryName != null) {
        final countryInfo = <String, String>{};
        if (countryCode != null) countryInfo['code'] = countryCode;
        if (countryName != null) countryInfo['name'] = countryName;
        body['country_info'] = countryInfo;
      }

      // Submit analysis request - returns immediately with analysis_id
      // Use long-running timeout because the body contains large base64 images
      final submitResponse = await _api.postLongRunning(
        Endpoints.analysis,
        body: body,
        timeout: const Duration(minutes: 2),
      );

      if (submitResponse['success'] != true) {
        return AnalysisResult.error(
          _extractString(submitResponse['message']) ?? 'analysis.failed',
        );
      }

      final analysisId = _safeIntOrNull(submitResponse['analysis_id']);
      if (analysisId == null) {
        AppLogger.e('No analysis_id in response: $submitResponse');
        return AnalysisResult.error('analysis.failed');
      }

      AppLogger.i('Analysis submitted, id: $analysisId, starting polling...');

      // Poll until completion or timeout
      return await _pollForCompletion(
        analysisId: analysisId,
        onProgress: onProgress,
      );
    } on InsufficientCreditsException {
      return AnalysisResult.error('credits.insufficient');
    } on PayloadTooLargeException {
      return AnalysisResult.error('analysis.payload_too_large');
    } on NetworkException {
      AppLogger.e('Network error during profile analysis');
      return AnalysisResult.error('analysis.network_error');
    } on ApiException catch (e) {
      AppLogger.e('Profile analysis API error', error: e);
      if (e.statusCode == 429) {
        return AnalysisResult.error('analysis.in_progress');
      }
      if (e.statusCode != null && e.statusCode! >= 500) {
        return AnalysisResult.error('analysis.server_error');
      }
      return AnalysisResult.error('analysis.failed');
    } catch (e) {
      AppLogger.e('Profile analysis error', error: e);
      return AnalysisResult.error('analysis.failed');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CHAT ANALYSIS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Submit chat screenshots for AI analysis
  /// Cost: 1 credit
  ///
  /// Chat analysis is synchronous — the server returns data directly
  /// in the POST response (no polling needed).
  Future<ChatAnalysisResult> analyzeChat({
    required List<String> screenshotUrls,
    int? contextProfileId,
    String language = 'en',
    void Function(AnalysisStatus status)? onProgress,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'screenshots': screenshotUrls,
        'language': language,
      };

      if (contextProfileId != null) {
        body['context_profile_id'] = contextProfileId;
      }

      onProgress?.call(AnalysisStatus.processing);

      // Chat analysis returns data directly (synchronous)
      final response = await _api.postLongRunning(
        Endpoints.analysisChat,
        body: body,
        timeout: const Duration(minutes: 2),
      );

      if (response['success'] != true) {
        return ChatAnalysisResult.error(
          _extractString(response['message']) ?? 'analysis.failed',
        );
      }

      final analysisId = _safeIntOrNull(response['analysis_id']);
      if (analysisId == null) {
        AppLogger.e('No analysis_id in chat response: $response');
        return ChatAnalysisResult.error('analysis.failed');
      }

      final data = response['data'] as Map<String, dynamic>?;
      if (data == null) {
        AppLogger.e('No data in chat response: $response');
        return ChatAnalysisResult.error('analysis.failed');
      }

      AppLogger.i('Chat analysis completed synchronously, id: $analysisId');
      onProgress?.call(AnalysisStatus.completed);

      return ChatAnalysisResult.success(
        analysisId: analysisId,
        data: ChatAnalysisData.fromJson(data),
        contextUsed: response['context_used'] == true,
      );
    } on InsufficientCreditsException {
      return ChatAnalysisResult.error('credits.insufficient');
    } on PayloadTooLargeException {
      return ChatAnalysisResult.error('analysis.payload_too_large');
    } on NetworkException {
      AppLogger.e('Network error during chat analysis');
      return ChatAnalysisResult.error('analysis.network_error');
    } on ApiException catch (e) {
      AppLogger.e('Chat analysis API error', error: e);
      if (e.statusCode == 429) {
        return ChatAnalysisResult.error('analysis.in_progress');
      }
      if (e.statusCode != null && e.statusCode! >= 500) {
        return ChatAnalysisResult.error('analysis.server_error');
      }
      return ChatAnalysisResult.error('analysis.failed');
    } catch (e) {
      AppLogger.e('Chat analysis error', error: e);
      return ChatAnalysisResult.error('analysis.failed');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // POLLING LOGIC
  // ═══════════════════════════════════════════════════════════════════════════

  /// Poll GET /analysis/{id} until completed, failed, or timeout
  Future<AnalysisResult> _pollForCompletion({
    required int analysisId,
    Duration timeout = _analysisTimeout,
    Duration interval = _pollInterval,
    void Function(AnalysisStatus status)? onProgress,
  }) async {
    final startTime = DateTime.now();
    final timeoutTime = startTime.add(timeout);

    while (DateTime.now().isBefore(timeoutTime)) {
      try {
        final response = await _api.get(Endpoints.analysisById(analysisId));

        // api.md §6.2: poll responses are `{ status, data?, photo_prompts?,
        // error? }` — no `success` envelope. Missing `status` means a
        // malformed response; keep polling so transient backend issues don't
        // immediately fail the user's job.
        final statusRaw = response['status'];
        if (statusRaw == null) {
          await Future.delayed(interval);
          continue;
        }
        final status = AnalysisStatus.fromString(statusRaw.toString());
        onProgress?.call(status);

        AppLogger.d('Analysis $analysisId status: ${status.name}');

        if (status.isCompleted) {
          // Analysis completed successfully
          final data = response['data'] as Map<String, dynamic>?;
          final photoPrompts = (response['photo_prompts'] as List<dynamic>?)
                  ?.map((e) => PhotoPrompt.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [];

          AppLogger.i('Analysis $analysisId completed with ${photoPrompts.length} prompts');

          return AnalysisResult.success(
            analysisId: analysisId,
            data: ProfileAnalysisData.fromJson(data ?? {}),
            photoPrompts: photoPrompts,
            rawData: data,
          );
        }

        if (status.isFailed) {
          // Analysis failed on the server — error can be String or Map
          final errorMessage = _extractString(response['error']) ?? 'analysis.failed';
          AppLogger.e('Analysis $analysisId failed: $errorMessage');
          return AnalysisResult.error(errorMessage);
        }

        // Still pending/processing, wait and poll again
        await Future.delayed(interval);
      } on NotFoundException {
        AppLogger.e('Analysis $analysisId not found (404)');
        return AnalysisResult.error('analysis.not_found');
      } on NetworkException {
        AppLogger.e('Network error polling analysis $analysisId');
        // Continue polling on transient network errors
        await Future.delayed(interval);
      } on TransientServerException catch (e) {
        // 502/503/504 from edge — worker untouched, keep polling
        AppLogger.w('Transient edge error polling analysis $analysisId (${e.statusCode})');
        await Future.delayed(interval);
      } on ApiException catch (e) {
        // 500 is the only 5xx that's app-emitted + terminal
        if (e.statusCode == 500) {
          AppLogger.e('App-level server error polling $analysisId', error: e);
          return AnalysisResult.error('analysis.server_error');
        }
        AppLogger.e('API error polling analysis $analysisId', error: e);
        // Continue polling on other API errors
        await Future.delayed(interval);
      } catch (e) {
        AppLogger.e('Error polling analysis $analysisId', error: e);
        // Continue polling on transient errors
        await Future.delayed(interval);
      }
    }

    // Timeout reached
    AppLogger.e('Analysis $analysisId timed out after ${timeout.inSeconds}s');
    return AnalysisResult.error('analysis.timeout');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHOTO ENHANCEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Default polling interval for enhancement status
  static const Duration _enhancePollInterval = Duration(seconds: 5);

  /// Default timeout for enhancement completion
  static const Duration _enhanceTimeout = Duration(minutes: 5);

  /// Generate AI-enhanced photos from analysis (async submit + poll)
  /// Cost: 3 credits
  ///
  /// [onProgress] is called during polling with the current status string
  /// ("pending", "processing", "completed", "failed").
  Future<EnhanceResult> enhancePhotos({
    required int analysisId,
    required String referencePhotoUrl,
    void Function(String status)? onProgress,
  }) async {
    try {
      // Step 1: Submit enhancement request (returns immediately)
      final submitResponse = await _api.post(
        Endpoints.photosEnhance,
        body: {
          'analysis_id': analysisId,
          'reference_photo_url': referencePhotoUrl,
        },
      );

      if (submitResponse['success'] != true) {
        return EnhanceResult.error(
          _extractString(submitResponse['message']) ?? 'enhance.failed',
        );
      }

      // Check if photos are already available (cached — 12+ photos exist)
      final existingPhotos = submitResponse['photos'] as List<dynamic>?;
      if (existingPhotos != null && existingPhotos.isNotEmpty) {
        final photos = existingPhotos.map((e) => e.toString()).toList();
        return EnhanceResult.success(
          photos: photos,
          totalPhotos: photos.length,
        );
      }

      // Get job ID for polling
      final rawJobId = submitResponse['enhancement_job_id'];
      final jobId = rawJobId is int ? rawJobId : int.tryParse(rawJobId?.toString() ?? '');
      if (jobId == null) {
        AppLogger.e('No enhancement_job_id in response: $submitResponse');
        return EnhanceResult.error('enhance.failed');
      }

      AppLogger.i('Enhancement submitted, job: $jobId, starting polling...');
      final statusStr = _extractString(submitResponse['status']) ?? 'pending';
      onProgress?.call(statusStr);

      // Step 2: Poll for completion
      return await _pollEnhancement(
        jobId: jobId,
        onProgress: onProgress,
      );
    } on InsufficientCreditsException {
      return EnhanceResult.error('credits.insufficient');
    } on ApiException catch (e) {
      AppLogger.e('Enhance submit API error', error: e);
      if (e.statusCode == 429) {
        return EnhanceResult.error('enhance.in_progress');
      }
      if (e.statusCode == 404) {
        return EnhanceResult.error('enhance.analysis_not_found');
      }
      if (e.statusCode == 400) {
        return EnhanceResult.error('enhance.no_prompts');
      }
      return EnhanceResult.error('enhance.failed');
    } catch (e) {
      AppLogger.e('Enhance photos error', error: e);
      return EnhanceResult.error('enhance.failed');
    }
  }

  /// Poll GET /photos/enhance/status/:id until completed, failed, or timeout
  Future<EnhanceResult> _pollEnhancement({
    required int jobId,
    Duration timeout = _enhanceTimeout,
    Duration interval = _enhancePollInterval,
    void Function(String status)? onProgress,
  }) async {
    final deadline = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(interval);

      try {
        final response = await _api.get(Endpoints.enhanceStatus(jobId));

        // api.md §6.6: enhancement status responses are
        // `{ status, photos, total_photos, error?, credits_refunded? }`
        // with no `success` envelope. Read `status` directly.
        final status = _extractString(response['status']) ?? 'pending';
        onProgress?.call(status);

        AppLogger.d('Enhancement job $jobId status: $status');

        if (status == 'completed') {
          final photos = (response['photos'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];

          AppLogger.i('Enhancement job $jobId completed with ${photos.length} photos');

          final rawTotal = response['total_photos'];
          final totalPhotos = rawTotal is int
              ? rawTotal
              : int.tryParse(rawTotal?.toString() ?? '') ?? photos.length;

          return EnhanceResult.success(
            photos: photos,
            totalPhotos: totalPhotos,
          );
        }

        if (status == 'failed') {
          final errorMessage = _extractString(response['error']) ?? 'enhance.failed';
          final creditsRefunded = response['credits_refunded'] == true;
          AppLogger.e('Enhancement job $jobId failed: $errorMessage (refunded: $creditsRefunded)');
          return EnhanceResult.error(errorMessage, creditsRefunded: creditsRefunded);
        }

        // Still pending/processing — continue polling
      } on NotFoundException {
        AppLogger.e('Enhancement job $jobId not found (404)');
        return EnhanceResult.error('enhance.job_not_found');
      } on NetworkException {
        AppLogger.w('Network error polling enhancement $jobId, continuing...');
        // Continue polling on transient network errors
      } on TransientServerException catch (e) {
        AppLogger.w('Transient edge error polling enhancement $jobId (${e.statusCode})');
        // Continue polling — worker is unaffected
      } on ApiException catch (e) {
        if (e.statusCode == 500) {
          AppLogger.e('App-level server error polling enhancement $jobId', error: e);
          return EnhanceResult.error('enhance.failed');
        }
        AppLogger.w('API error polling enhancement $jobId: ${e.message}');
        // Continue polling on other transient errors
      }
    }

    // Timeout reached
    AppLogger.e('Enhancement job $jobId timed out after ${timeout.inSeconds}s');
    return EnhanceResult.error('enhance.timeout');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Safely extract a string from a server response value.
  /// Handles cases where the server returns a String, Map, or other type.
  static String? _extractString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) {
      // Server sometimes returns {"message": "..."} or {"error": "..."}
      return value['message']?.toString() ??
          value['error']?.toString() ??
          value.toString();
    }
    return value.toString();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ANALYSIS HISTORY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get analysis by ID.
  ///
  /// Per api.md §6.2 the server always includes `analysis_id`, `status`,
  /// `analysis_type`, `created_at`, `language` and (when completed) `data`
  /// and `photo_prompts`. Returns null only on fetch error.
  Future<StoredAnalysis?> getAnalysis(int analysisId) async {
    try {
      final response = await _api.get(Endpoints.analysisById(analysisId));
      if (response['status'] == null) return null;
      return StoredAnalysis.fromJson(response);
    } catch (e) {
      AppLogger.e('Get analysis error', error: e);
      return null;
    }
  }

  /// Find the user's current in-flight analysis (pending or processing).
  ///
  /// Per api.md §8: when `POST /analysis` returns `429 ANALYSIS_IN_PROGRESS`
  /// the body does not include the in-flight analysis_id, so the client
  /// must look it up via `/analysis/list` to resume polling.
  Future<int?> findInFlightAnalysisId() async {
    try {
      final result = await getAnalysisList(limit: 5, offset: 0);
      for (final a in result.analyses) {
        if (a.isPending) return a.id;
      }
      return null;
    } catch (e) {
      AppLogger.e('Find in-flight analysis error', error: e);
      return null;
    }
  }

  /// Get list of user's analyses
  Future<AnalysisListResult> getAnalysisList({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _api.get(
        Endpoints.analysisList,
        queryParams: {'limit': limit, 'offset': offset},
      );

      final analyses = (response['analyses'] as List<dynamic>?)
              ?.map((e) => AnalysisSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      final pagination = response['pagination'] as Map<String, dynamic>? ?? {};
      final total = _safeInt(pagination['total'], analyses.length);

      return AnalysisListResult(
        analyses: analyses,
        hasMore: offset + analyses.length < total,
        total: total,
      );
    } catch (e) {
      AppLogger.e('Get analysis list error', error: e);
      return AnalysisListResult(analyses: [], hasMore: false, total: 0);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VOICE SUMMARY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Request a voice summary for a completed analysis
  /// Returns immediately with processing status (async generation)
  Future<VoiceSummary?> requestVoiceSummary(int analysisId, {String? language}) async {
    try {
      final Map<String, dynamic> body = {};
      if (language != null) body['language'] = language;

      final response = await _api.post(
        Endpoints.analysisVoice(analysisId),
        body: body,
      );

      return VoiceSummary.fromJson(response);
    } on ApiException catch (e) {
      AppLogger.e('Request voice summary error', error: e);
      return null;
    } catch (e) {
      AppLogger.e('Request voice summary error', error: e);
      return null;
    }
  }

  /// Poll voice summary status
  Future<VoiceSummary?> getVoiceSummary(int analysisId, {String? language}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (language != null) queryParams['language'] = language;

      final response = await _api.get(
        Endpoints.analysisVoice(analysisId),
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      return VoiceSummary.fromJson(response);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      AppLogger.e('Get voice summary error', error: e);
      return null;
    } catch (e) {
      AppLogger.e('Get voice summary error', error: e);
      return null;
    }
  }

  /// Request voice summary and poll until completed or failed
  Future<VoiceSummary?> requestAndPollVoiceSummary(
    int analysisId, {
    String? language,
    void Function(VoiceSummary status)? onProgress,
  }) async {
    // Request generation
    final initial = await requestVoiceSummary(analysisId, language: language);
    if (initial == null) return null;

    // If already completed (cached), return immediately
    if (initial.isCompleted || initial.isFailed) return initial;

    onProgress?.call(initial);

    // Poll every 2 seconds, timeout after 60 seconds
    final deadline = DateTime.now().add(const Duration(seconds: 60));
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(seconds: 2));

      final status = await getVoiceSummary(analysisId, language: language);
      if (status == null) return null;

      onProgress?.call(status);

      if (status.isCompleted || status.isFailed) return status;
    }

    return VoiceSummary(
      voiceNoteId: 0,
      status: 'failed',
      audioFormat: 'mp3',
      language: language ?? 'en',
      error: 'Voice generation timed out',
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════

/// Body language intelligence from profile analysis
class BodyLanguageIntelligence {
  final String posture;
  final String eyeContact;
  final String gestures;
  final String proximity;
  final List<String> negativesAnalysis;
  final String territoryClaiming;
  final String armsAkimbo;
  final String triangleMethod;
  final String protectiveBodyLanguage;
  final String americanFour;

  BodyLanguageIntelligence({
    required this.posture,
    required this.eyeContact,
    required this.gestures,
    required this.proximity,
    required this.negativesAnalysis,
    required this.territoryClaiming,
    required this.armsAkimbo,
    required this.triangleMethod,
    required this.protectiveBodyLanguage,
    required this.americanFour,
  });

  factory BodyLanguageIntelligence.fromJson(Map<String, dynamic> json) {
    return BodyLanguageIntelligence(
      posture: json['posture']?.toString() ?? '',
      eyeContact: json['eye_contact']?.toString() ?? '',
      gestures: json['gestures']?.toString() ?? '',
      proximity: json['proximity']?.toString() ?? '',
      negativesAnalysis: (json['negatives_analysis'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      territoryClaiming: json['territory_claiming']?.toString() ?? '',
      armsAkimbo: json['arms_akimbo']?.toString() ?? '',
      triangleMethod: json['triangle_method']?.toString() ?? '',
      protectiveBodyLanguage:
          json['protective_body_language']?.toString() ?? '',
      americanFour: json['american_four']?.toString() ?? '',
    );
  }
}

/// Profile analysis data
class ProfileAnalysisData {
  final String personalitySummary;
  final List<String> keyTraits;
  final String communicationStrategy;
  final BodyLanguageIntelligence? bodyLanguageIntelligence;
  final List<String> conversationStarters;
  final String firstImpressionFormula;
  final String whatToWear;
  final String optimalTiming;
  final String platformIntelligence;
  final String successProbability;
  final String culturalReligious;
  final List<String> redFlags;
  final List<String> greenFlags;
  final String trustIndicators;
  final Map<String, String> aiImagePrompts;

  ProfileAnalysisData({
    required this.personalitySummary,
    required this.keyTraits,
    required this.communicationStrategy,
    this.bodyLanguageIntelligence,
    required this.conversationStarters,
    required this.firstImpressionFormula,
    required this.whatToWear,
    required this.optimalTiming,
    required this.platformIntelligence,
    required this.successProbability,
    required this.culturalReligious,
    required this.redFlags,
    required this.greenFlags,
    required this.trustIndicators,
    required this.aiImagePrompts,
  });

  factory ProfileAnalysisData.fromJson(Map<String, dynamic> json) {
    final promptsJson = json['ai_image_prompts'] as Map<String, dynamic>? ?? {};
    final bodyLangJson =
        json['body_language_intelligence'] as Map<String, dynamic>?;

    return ProfileAnalysisData(
      personalitySummary: json['personality_summary']?.toString() ?? '',
      keyTraits: (json['key_traits'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      communicationStrategy:
          json['communication_strategy']?.toString() ?? '',
      bodyLanguageIntelligence: bodyLangJson != null
          ? BodyLanguageIntelligence.fromJson(bodyLangJson)
          : null,
      conversationStarters:
          (json['conversation_starters'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
      firstImpressionFormula:
          json['first_impression_formula']?.toString() ?? '',
      whatToWear: json['what_to_wear']?.toString() ?? '',
      optimalTiming: json['optimal_timing']?.toString() ?? '',
      platformIntelligence:
          json['platform_intelligence']?.toString() ?? '',
      successProbability:
          json['success_probability']?.toString() ?? '',
      culturalReligious:
          json['cultural_religious']?.toString() ?? '',
      redFlags: (json['red_flags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      greenFlags: (json['green_flags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      trustIndicators: json['trust_indicators']?.toString() ?? '',
      aiImagePrompts: promptsJson.map((k, v) => MapEntry(k, v.toString())),
    );
  }
}

/// Chat analysis data — matches live backend flat string structure
class ChatAnalysisData {
  final String conversationAnalysis;
  final String communicationStyle;
  final List<String> trustIndicators;
  final List<String> recommendations;
  final String interactionQuality;
  final String respectLevel;
  final String compatibilityInsights;
  final List<String> riskFlags;
  final String successProbability;

  ChatAnalysisData({
    required this.conversationAnalysis,
    required this.communicationStyle,
    required this.trustIndicators,
    required this.recommendations,
    required this.interactionQuality,
    required this.respectLevel,
    required this.compatibilityInsights,
    required this.riskFlags,
    required this.successProbability,
  });

  factory ChatAnalysisData.fromJson(Map<String, dynamic> json) {
    return ChatAnalysisData(
      conversationAnalysis:
          json['conversation_analysis']?.toString() ?? '',
      communicationStyle:
          json['communication_style']?.toString() ?? '',
      trustIndicators: (json['trust_indicators'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      interactionQuality:
          json['interaction_quality']?.toString() ?? '',
      respectLevel:
          json['respect_level']?.toString() ?? '',
      compatibilityInsights:
          json['compatibility_insights']?.toString() ?? '',
      riskFlags: (json['risk_flags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      successProbability:
          json['success_probability']?.toString() ?? '',
    );
  }
}

/// Stored analysis with full details
class StoredAnalysis {
  final int id;
  final AnalysisStatus status;
  final DateTime createdAt;
  final String language;
  final int creditsSpent;
  final String analysisType;
  final bool contextUsed;
  final int? contextProfileId;
  final Map<String, dynamic>? data;
  final List<PhotoPrompt> photoPrompts;
  final String? error;

  StoredAnalysis({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.language,
    required this.creditsSpent,
    required this.analysisType,
    this.contextUsed = false,
    this.contextProfileId,
    this.data,
    required this.photoPrompts,
    this.error,
  });

  factory StoredAnalysis.fromJson(Map<String, dynamic> json) {
    final statusRaw = json['status'];
    final errorRaw = json['error'];
    return StoredAnalysis(
      id: _safeInt(json['analysis_id']),
      status: AnalysisStatus.fromString(
        statusRaw is String ? statusRaw : statusRaw?.toString(),
      ),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      language: json['language']?.toString() ?? 'en',
      creditsSpent: _safeInt(json['credits_spent'], 1),
      analysisType: json['analysis_type']?.toString() ?? 'profile',
      contextUsed: json['context_used'] == true,
      contextProfileId: _safeIntOrNull(json['context_profile_id']),
      data: json['data'] as Map<String, dynamic>?,
      photoPrompts: (json['photo_prompts'] as List<dynamic>?)
              ?.map((e) => PhotoPrompt.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      error: errorRaw is String
          ? errorRaw
          : (errorRaw is Map ? errorRaw['message']?.toString() : errorRaw?.toString()),
    );
  }

  bool get isCompleted => status.isCompleted;
  bool get isPending => status.isInProgress;
  bool get isFailed => status.isFailed;
  bool get isProfileAnalysis => analysisType == 'profile';
  bool get isChatAnalysis => analysisType == 'chat';
}

/// Photo generation prompt
class PhotoPrompt {
  final int id;
  final String? category;
  final String seedreamPrompt;
  final DateTime createdAt;

  PhotoPrompt({
    required this.id,
    this.category,
    required this.seedreamPrompt,
    required this.createdAt,
  });

  factory PhotoPrompt.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return PhotoPrompt(
      id: rawId is int ? rawId : (int.tryParse(rawId?.toString() ?? '') ?? 0),
      category: json['category']?.toString(),
      seedreamPrompt: json['seedream_prompt']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

/// Analysis summary for list view
class AnalysisSummary {
  final int id;
  final AnalysisStatus status;
  final String language;
  final int creditsSpent;
  final DateTime createdAt;
  final String analysisType;
  final int? screenshotCount;

  AnalysisSummary({
    required this.id,
    required this.status,
    required this.language,
    required this.creditsSpent,
    required this.createdAt,
    required this.analysisType,
    this.screenshotCount,
  });

  factory AnalysisSummary.fromJson(Map<String, dynamic> json) {
    return AnalysisSummary(
      id: _safeInt(json['id']),
      status: AnalysisStatus.fromString(json['status']?.toString()),
      language: json['language']?.toString() ?? 'en',
      creditsSpent: _safeInt(json['credits_spent'], 1),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      analysisType: json['analysis_type']?.toString() ?? 'profile',
      screenshotCount: _safeIntOrNull(json['screenshot_count']),
    );
  }

  bool get isProfileAnalysis => analysisType == 'profile';
  bool get isChatAnalysis => analysisType == 'chat';
  bool get isCompleted => status.isCompleted;
  bool get isPending => status.isInProgress;
  bool get isFailed => status.isFailed;
}

// ═══════════════════════════════════════════════════════════════════════════
// RESULT CLASSES
// ═══════════════════════════════════════════════════════════════════════════

class AnalysisResult {
  final bool isSuccess;
  final int? analysisId;
  final ProfileAnalysisData? data;
  final List<PhotoPrompt> photoPrompts;
  final Map<String, dynamic>? rawData;
  final String? errorKey;

  AnalysisResult._({
    required this.isSuccess,
    this.analysisId,
    this.data,
    this.photoPrompts = const [],
    this.rawData,
    this.errorKey,
  });

  factory AnalysisResult.success({
    required int analysisId,
    required ProfileAnalysisData data,
    List<PhotoPrompt> photoPrompts = const [],
    Map<String, dynamic>? rawData,
  }) {
    return AnalysisResult._(
      isSuccess: true,
      analysisId: analysisId,
      data: data,
      photoPrompts: photoPrompts,
      rawData: rawData,
    );
  }

  factory AnalysisResult.error(String errorKey) {
    return AnalysisResult._(isSuccess: false, errorKey: errorKey);
  }

  /// For backwards compatibility
  int get photoPromptsCount => photoPrompts.length;
}

class ChatAnalysisResult {
  final bool isSuccess;
  final int? analysisId;
  final ChatAnalysisData? data;
  final bool contextUsed;
  final String? errorKey;

  ChatAnalysisResult._({
    required this.isSuccess,
    this.analysisId,
    this.data,
    this.contextUsed = false,
    this.errorKey,
  });

  factory ChatAnalysisResult.success({
    required int analysisId,
    required ChatAnalysisData data,
    bool contextUsed = false,
  }) {
    return ChatAnalysisResult._(
      isSuccess: true,
      analysisId: analysisId,
      data: data,
      contextUsed: contextUsed,
    );
  }

  factory ChatAnalysisResult.error(String errorKey) {
    return ChatAnalysisResult._(isSuccess: false, errorKey: errorKey);
  }
}

class EnhanceResult {
  final bool isSuccess;
  final List<String> photos;
  final int totalPhotos;
  final String? errorKey;
  final bool creditsRefunded;

  EnhanceResult._({
    required this.isSuccess,
    this.photos = const [],
    this.totalPhotos = 0,
    this.errorKey,
    this.creditsRefunded = false,
  });

  factory EnhanceResult.success({
    required List<String> photos,
    int totalPhotos = 0,
  }) {
    return EnhanceResult._(
      isSuccess: true,
      photos: photos,
      totalPhotos: totalPhotos,
    );
  }

  factory EnhanceResult.error(String errorKey, {bool creditsRefunded = false}) {
    return EnhanceResult._(
      isSuccess: false,
      errorKey: errorKey,
      creditsRefunded: creditsRefunded,
    );
  }
}

class AnalysisListResult {
  final List<AnalysisSummary> analyses;
  final bool hasMore;
  final int total;

  AnalysisListResult({
    required this.analyses,
    required this.hasMore,
    required this.total,
  });
}

/// Voice summary for an analysis
class VoiceSummary {
  final int voiceNoteId;
  final String status;
  final String? audioUrl;
  final String audioFormat;
  final String language;
  final String? error;

  VoiceSummary({
    required this.voiceNoteId,
    required this.status,
    this.audioUrl,
    required this.audioFormat,
    required this.language,
    this.error,
  });

  factory VoiceSummary.fromJson(Map<String, dynamic> json) {
    return VoiceSummary(
      voiceNoteId: _safeInt(json['voice_note_id']),
      status: json['status']?.toString() ?? 'processing',
      audioUrl: json['audio_url']?.toString(),
      audioFormat: json['audio_format']?.toString() ?? 'mp3',
      language: json['language']?.toString() ?? 'en',
      error: json['error']?.toString(),
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isProcessing => status == 'processing';
  bool get isFailed => status == 'failed';
}
