import 'dart:async';
import 'package:workmanager/workmanager.dart';
import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../services/photos_service.dart';
import '../utils/app_logger.dart';
import 'analysis_job.dart';
import 'job_queue_storage.dart';
import '../notifications/notification_service.dart';

class EnhancementException implements Exception {
  final String message;
  EnhancementException(this.message);
  @override
  String toString() => 'EnhancementException: $message';
}

/// Unique task names
const String analysisTaskName = 'com.vibelytics.app.analysis';
const String analysisTaskTag = 'analysis';
const String enhancementTaskName = 'com.vibelytics.app.enhancement';
const String enhancementTaskTag = 'enhancement';

/// Background task callback dispatcher
/// This must be a top-level function
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    AppLogger.i('Background task started: $task');

    // Initialize notification service in background isolate
    // (separate isolate = fresh singleton, needs re-init)
    try {
      await NotificationService.instance.initializePlugin();
    } catch (e) {
      AppLogger.w('Failed to init notifications in background: $e');
    }

    try {
      switch (task) {
        case analysisTaskName:
          final jobId = inputData?['jobId']?.toString();
          if (jobId != null) {
            await _executeAnalysisJob(jobId);
          }
          break;

        case enhancementTaskName:
          final jobId = inputData?['jobId']?.toString();
          if (jobId != null) {
            await _executeEnhancementJob(jobId);
          }
          break;

        case Workmanager.iOSBackgroundTask:
          // iOS background fetch - process any pending jobs
          await _processAllPendingJobs();
          break;

        default:
          AppLogger.w('Unknown background task: $task');
      }

      return true;
    } catch (e, stackTrace) {
      AppLogger.e('Background task failed', error: e, stackTrace: stackTrace);
      return false;
    }
  });
}

/// Execute a specific analysis job
Future<void> _executeAnalysisJob(String jobId) async {
  final storage = JobQueueStorage.instance;
  final job = await storage.getJob(jobId);

  if (job == null) {
    AppLogger.w('Job $jobId not found');
    return;
  }

  if (!job.isPending && !job.isProcessing) {
    AppLogger.w('Job $jobId already completed or failed');
    return;
  }

  // Mark as processing
  await storage.updateJobStatus(jobId, status: AnalysisJobStatus.processing);

  try {
    // Show processing notification
    await NotificationService.instance.showAnalysisProgress(
      jobId: jobId,
      progress: 0,
      message: 'Analyzing your profile...',
    );

    // Call the analysis API
    final Map<String, dynamic> body = {
      'screenshots': job.base64Images,
      'language': job.language,
    };

    if (job.countryCode != null || job.countryName != null) {
      final countryInfo = <String, String>{};
      if (job.countryCode != null) countryInfo['code'] = job.countryCode!;
      if (job.countryName != null) countryInfo['name'] = job.countryName!;
      body['country_info'] = countryInfo;
    }

    if (job.type == AnalysisJobType.chat && job.contextProfileId != null) {
      body['context_profile_id'] = job.contextProfileId;
    }

    final endpoint = job.type == AnalysisJobType.profile
        ? Endpoints.analysis
        : Endpoints.analysisChat;

    AppLogger.i('Calling API for job $jobId');
    final response = await ApiClient.instance.post(endpoint, body: body);

    if (response['success'] == true) {
      final rawAnalysisId = response['analysis_id'];
      final analysisId = rawAnalysisId is int
          ? rawAnalysisId
          : int.tryParse(rawAnalysisId?.toString() ?? '');

      if (analysisId == null) {
        throw Exception('Missing or invalid analysis_id from server');
      }

      // Profile analysis is async — poll until completed or failed
      if (job.type == AnalysisJobType.profile) {
        await _pollUntilComplete(jobId, analysisId, storage);
      } else {
        // Chat analysis is synchronous — data returned in POST response
        await storage.updateJobStatus(
          jobId,
          status: AnalysisJobStatus.completed,
          analysisId: analysisId,
        );
        await NotificationService.instance.showAnalysisComplete(
          jobId: jobId,
          analysisId: analysisId,
          message: 'Your chat analysis is ready!',
        );
      }

      AppLogger.i('Job $jobId processed with analysisId $analysisId');
    } else {
      throw Exception(response['message'] ?? 'Analysis failed');
    }
  } on InsufficientCreditsException {
    await NotificationService.instance.cancelAnalysisNotifications();

    await storage.updateJobStatus(
      jobId,
      status: AnalysisJobStatus.failed,
      errorMessage: 'Insufficient credits',
    );

    await NotificationService.instance.showAnalysisFailed(
      jobId: jobId,
      message: 'Not enough credits to complete analysis',
    );
  } on ApiException catch (e) {
    await NotificationService.instance.cancelAnalysisNotifications();

    if (e.statusCode != null && e.statusCode! >= 500) {
      AppLogger.e('Job $jobId server error (${e.statusCode})', error: e);

      await storage.updateJobStatus(
        jobId,
        status: AnalysisJobStatus.failed,
        errorMessage: 'Server error, please try again',
      );

      await NotificationService.instance.showAnalysisFailed(
        jobId: jobId,
        message: 'Analysis failed due to a server error.',
      );
    } else {
      AppLogger.e('Job $jobId API error (${e.statusCode})', error: e);

      await storage.updateJobStatus(
        jobId,
        status: AnalysisJobStatus.failed,
        errorMessage: e.message,
      );

      await NotificationService.instance.showAnalysisFailed(
        jobId: jobId,
        message: 'Analysis failed. Tap to retry.',
      );
    }
  } catch (e, stackTrace) {
    AppLogger.e('Job $jobId failed', error: e, stackTrace: stackTrace);

    // Cancel any lingering progress notification
    await NotificationService.instance.cancelAnalysisNotifications();

    await storage.updateJobStatus(
      jobId,
      status: AnalysisJobStatus.failed,
      errorMessage: e.toString(),
    );

    final job = await storage.getJob(jobId);
    if (job != null && job.canRetry) {
      await NotificationService.instance.showAnalysisFailed(
        jobId: jobId,
        message: 'Analysis failed. Tap to retry.',
      );
    } else {
      await NotificationService.instance.showAnalysisFailed(
        jobId: jobId,
        message: 'Analysis failed after multiple attempts.',
      );
    }
  }
}

/// Poll GET /analysis/:id until completed or failed (for background jobs)
Future<void> _pollUntilComplete(
  String jobId,
  int analysisId,
  JobQueueStorage storage,
) async {
  const pollInterval = Duration(seconds: 5);
  const maxAttempts = 80; // ~6.5 minutes
  const maxConsecutiveErrors = 10;
  var consecutiveErrors = 0;

  for (var i = 0; i < maxAttempts; i++) {
    await Future<void>.delayed(pollInterval);

    // Update progress notification
    final progressPercent = ((i / maxAttempts) * 80).round() + 10;
    await NotificationService.instance.showAnalysisProgress(
      jobId: jobId,
      progress: progressPercent,
      message: 'Analyzing your profile... (${i * 5}s)',
    );

    try {
      final response = await ApiClient.instance.get(
        Endpoints.analysisById(analysisId),
      );
      consecutiveErrors = 0; // Reset on success

      final status = response['status']?.toString();

      if (status == 'completed') {
        await storage.updateJobStatus(
          jobId,
          status: AnalysisJobStatus.completed,
          analysisId: analysisId,
        );
        await NotificationService.instance.showAnalysisComplete(
          jobId: jobId,
          analysisId: analysisId,
          message: 'Your profile analysis is ready!',
        );
        return;
      }

      if (status == 'failed') {
        final error = response['error']?.toString() ?? 'Analysis failed';
        await storage.updateJobStatus(
          jobId,
          status: AnalysisJobStatus.failed,
          errorMessage: error,
        );
        await NotificationService.instance.cancelAnalysisNotifications();
        await NotificationService.instance.showAnalysisFailed(
          jobId: jobId,
          message: error,
        );
        return;
      }
    } on ApiException catch (e) {
      // Per api.md §8: 500 is app-emitted + terminal; 502/503/504 are edge
      // transients and the worker is unaffected — keep polling.
      if (e.statusCode == 500) {
        AppLogger.e('Background poll: terminal 500 for $jobId', error: e);
        throw Exception('Server error: ${e.message}');
      }
      consecutiveErrors++;
      AppLogger.w('Background poll API error for $jobId ($consecutiveErrors/$maxConsecutiveErrors): ${e.statusCode}');
      if (consecutiveErrors >= maxConsecutiveErrors) {
        throw Exception('Edge unavailable — $consecutiveErrors consecutive errors');
      }
    } catch (e) {
      consecutiveErrors++;
      AppLogger.w('Background poll error for $jobId ($consecutiveErrors/$maxConsecutiveErrors): $e');
      if (consecutiveErrors >= maxConsecutiveErrors) {
        throw Exception('Network unavailable — $consecutiveErrors consecutive errors');
      }
    }
  }

  // Timeout
  await storage.updateJobStatus(
    jobId,
    status: AnalysisJobStatus.failed,
    errorMessage: 'Analysis timed out',
  );
  await NotificationService.instance.showAnalysisFailed(
    jobId: jobId,
    message: 'Analysis took too long. Please try again.',
  );
}

/// Execute a photo enhancement job
Future<void> _executeEnhancementJob(String jobId) async {
  final storage = JobQueueStorage.instance;
  final job = await storage.getJob(jobId);

  if (job == null) {
    AppLogger.w('Enhancement job $jobId not found');
    return;
  }

  if (!job.isPending && !job.isProcessing) {
    AppLogger.w('Enhancement job $jobId already completed or failed');
    return;
  }

  // Mark as processing
  await storage.updateJobStatus(jobId, status: AnalysisJobStatus.processing);

  try {
    // Show processing notification
    await NotificationService.instance.showEnhancementProgress(
      jobId: jobId,
      progress: 10,
      message: 'Submitting enhancement request...',
    );

    // Step 1: Submit enhancement request (returns immediately)
    final referencePhotoBase64 = job.base64Images.isNotEmpty
        ? job.base64Images[0]
        : '';

    final submitResponse = await ApiClient.instance.post(
      Endpoints.photosEnhance,
      body: {
        'analysis_id': job.sourceAnalysisId,
        'reference_photo_url': referencePhotoBase64,
      },
    );

    if (submitResponse['success'] != true) {
      throw Exception(submitResponse['message'] ?? 'Enhancement submission failed');
    }

    // Check if photos are already available (cached result)
    final existingPhotos = submitResponse['photos'] as List<dynamic>?;
    List<String> replicateUrls;

    if (existingPhotos != null && existingPhotos.isNotEmpty) {
      replicateUrls = existingPhotos.map((e) => e.toString()).toList();
      AppLogger.i('Enhancement job $jobId: cached result with ${replicateUrls.length} photos');
    } else {
      // Step 2: Poll for completion
      final rawServerJobId = submitResponse['enhancement_job_id'];
      final serverJobId = rawServerJobId is int
          ? rawServerJobId
          : int.tryParse(rawServerJobId?.toString() ?? '');
      if (serverJobId == null) {
        throw Exception('No enhancement_job_id in response');
      }

      AppLogger.i('Enhancement job $jobId: server job $serverJobId, polling...');

      await NotificationService.instance.showEnhancementProgress(
        jobId: jobId,
        progress: 20,
        message: 'Generating AI-enhanced photos...',
      );

      replicateUrls = await _pollEnhancementStatus(serverJobId);
    }

    AppLogger.i('Enhancement job $jobId got ${replicateUrls.length} photos, persisting to CDN...');

    // Step 3: Persist Replicate URLs to CDN (they expire in ~1 hour)
    await NotificationService.instance.showEnhancementProgress(
      jobId: jobId,
      progress: 70,
      message: 'Saving photos to gallery...',
    );

    final cdnUrls = <String>[];
    for (final url in replicateUrls) {
      final cdnUrl = await PhotosService.instance.uploadToCdn(
        url,
        type: 'enhanced',
      );
      cdnUrls.add(cdnUrl ?? url);
    }

    await storage.updateJobStatus(
      jobId,
      status: AnalysisJobStatus.completed,
      resultPhotoUrls: cdnUrls,
    );

    await NotificationService.instance.showEnhancementComplete(
      jobId: jobId,
      message: 'Your enhanced photos are ready!',
    );

    AppLogger.i('Enhancement job $jobId completed with ${cdnUrls.length} CDN URLs');
  } on InsufficientCreditsException {
    await NotificationService.instance.cancelEnhancementNotifications();

    await storage.updateJobStatus(
      jobId,
      status: AnalysisJobStatus.failed,
      errorMessage: 'Insufficient credits',
    );

    await NotificationService.instance.showEnhancementFailed(
      jobId: jobId,
      message: 'Not enough credits to enhance photos',
    );
  } on ApiException catch (e) {
    AppLogger.e('Enhancement job $jobId API error (${e.statusCode})', error: e);

    await NotificationService.instance.cancelEnhancementNotifications();

    await storage.updateJobStatus(
      jobId,
      status: AnalysisJobStatus.failed,
      errorMessage: e.statusCode != null && e.statusCode! >= 500
          ? 'Server error, please try again'
          : e.message,
    );

    await NotificationService.instance.showEnhancementFailed(
      jobId: jobId,
      message: 'Enhancement failed. Tap to retry.',
    );
  } catch (e, stackTrace) {
    AppLogger.e('Enhancement job $jobId failed', error: e, stackTrace: stackTrace);

    // Cancel any lingering progress notification
    await NotificationService.instance.cancelEnhancementNotifications();

    await storage.updateJobStatus(
      jobId,
      status: AnalysisJobStatus.failed,
      errorMessage: e.toString(),
    );

    await NotificationService.instance.showEnhancementFailed(
      jobId: jobId,
      message: 'Enhancement failed. Tap to retry.',
    );
  }
}

/// Poll GET /photos/enhance/status/:id until completed or failed
/// Used by background worker. Throws on failure.
Future<List<String>> _pollEnhancementStatus(int serverJobId) async {
  const pollInterval = Duration(seconds: 5);
  const maxWait = Duration(minutes: 5);
  final deadline = DateTime.now().add(maxWait);

  while (DateTime.now().isBefore(deadline)) {
    await Future.delayed(pollInterval);

    try {
      final response = await ApiClient.instance.get(
        Endpoints.enhanceStatus(serverJobId),
      );

      final status = response['status']?.toString() ?? 'pending';
      AppLogger.d('Enhancement server job $serverJobId status: $status');

      if (status == 'completed') {
        return (response['photos'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];
      }

      if (status == 'failed') {
        final errorVal = response['error'];
        final error = errorVal is String
            ? errorVal
            : (errorVal is Map ? errorVal['message']?.toString() : errorVal?.toString()) ?? 'Enhancement failed';
        throw EnhancementException(error);
      }

      // Still pending/processing — continue polling
    } on NotFoundException {
      throw EnhancementException('Enhancement job not found');
    } on EnhancementException {
      rethrow;
    } on ApiException catch (e) {
      // Per api.md §8: 500 is terminal; 502/503/504 are edge transients.
      if (e.statusCode == 500) {
        throw EnhancementException('Server error: ${e.message}');
      }
      AppLogger.w('Transient API error polling enhancement $serverJobId: ${e.statusCode}');
    } catch (e) {
      // Continue polling on transient errors
      AppLogger.w('Transient error polling enhancement $serverJobId: $e');
    }
  }

  throw EnhancementException('Enhancement timed out');
}

/// Process all pending jobs (for iOS background fetch)
Future<void> _processAllPendingJobs() async {
  final storage = JobQueueStorage.instance;
  final pendingJobs = await storage.getPendingJobs();

  for (final job in pendingJobs) {
    if (job.type == AnalysisJobType.enhancement) {
      await _executeEnhancementJob(job.id);
    } else {
      await _executeAnalysisJob(job.id);
    }
  }
}

/// Manager for background analysis tasks
class BackgroundTaskManager {
  BackgroundTaskManager._();
  static final BackgroundTaskManager instance = BackgroundTaskManager._();

  bool _initialized = false;
  final _jobStatusController = StreamController<AnalysisJob>.broadcast();

  /// Stream of job status updates
  Stream<AnalysisJob> get jobStatusStream => _jobStatusController.stream;

  /// Initialize the background task manager
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Workmanager().initialize(
        callbackDispatcher,
      );

      _initialized = true;
      AppLogger.i('BackgroundTaskManager initialized');

      // Check for any processing jobs that need to be resumed
      await _resumeProcessingJobs();
    } catch (e, stackTrace) {
      AppLogger.e('Failed to initialize BackgroundTaskManager',
          error: e, stackTrace: stackTrace);
    }
  }

  /// Submit a new analysis job
  Future<String> submitJob(AnalysisJob job) async {
    // Save to storage
    await JobQueueStorage.instance.saveJob(job);

    // Schedule background task
    await Workmanager().registerOneOffTask(
      job.id,
      analysisTaskName,
      inputData: {'jobId': job.id},
      tag: analysisTaskTag,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(seconds: 10),
    );

    _jobStatusController.add(job);
    AppLogger.i('Submitted job ${job.id}');
    return job.id;
  }

  /// Submit a new enhancement job
  Future<String> submitEnhancementJob(AnalysisJob job) async {
    // Save to storage
    await JobQueueStorage.instance.saveJob(job);

    // Schedule background task
    await Workmanager().registerOneOffTask(
      job.id,
      enhancementTaskName,
      inputData: {'jobId': job.id},
      tag: enhancementTaskTag,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(seconds: 10),
    );

    _jobStatusController.add(job);
    AppLogger.i('Submitted enhancement job ${job.id}');
    return job.id;
  }

  /// Cancel a pending job
  Future<void> cancelJob(String jobId) async {
    await Workmanager().cancelByUniqueName(jobId);
    await JobQueueStorage.instance.removeJob(jobId);
    AppLogger.i('Cancelled job $jobId');
  }

  /// Retry a failed job
  Future<void> retryJob(String jobId) async {
    final job = await JobQueueStorage.instance.getJob(jobId);
    if (job == null || !job.canRetry) {
      AppLogger.w('Job $jobId cannot be retried');
      return;
    }

    // Reset status to pending
    await JobQueueStorage.instance.updateJobStatus(
      jobId,
      status: AnalysisJobStatus.pending,
    );

    // Re-schedule with correct task type
    final isEnhancement = job.type == AnalysisJobType.enhancement;
    await Workmanager().registerOneOffTask(
      jobId,
      isEnhancement ? enhancementTaskName : analysisTaskName,
      inputData: {'jobId': jobId},
      tag: isEnhancement ? enhancementTaskTag : analysisTaskTag,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );

    final updatedJob = await JobQueueStorage.instance.getJob(jobId);
    if (updatedJob != null) _jobStatusController.add(updatedJob);
    AppLogger.i('Retrying job $jobId (type: ${job.type})');
  }

  /// Get job by ID
  Future<AnalysisJob?> getJob(String jobId) async {
    return JobQueueStorage.instance.getJob(jobId);
  }

  /// Get all active jobs (pending + processing)
  Future<List<AnalysisJob>> getActiveJobs() async {
    final jobs = await JobQueueStorage.instance.getAllJobs();
    return jobs.where((j) => j.isPending || j.isProcessing).toList();
  }

  /// Get completed jobs
  Future<List<AnalysisJob>> getCompletedJobs() async {
    return JobQueueStorage.instance.getCompletedJobs();
  }

  /// Resume any jobs that were processing when app was killed.
  /// Stale jobs (stuck > 30 minutes) are marked failed instead of retried.
  Future<void> _resumeProcessingJobs() async {
    final processingJobs = await JobQueueStorage.instance.getProcessingJobs();
    final now = DateTime.now();
    const staleThreshold = Duration(minutes: 30);

    for (final job in processingJobs) {
      final age = now.difference(job.createdAt);

      if (age > staleThreshold) {
        // Job is stale — mark as failed rather than retrying indefinitely
        AppLogger.w('Marking stale job ${job.id} as failed (stuck for ${age.inMinutes}m)');
        await JobQueueStorage.instance.updateJobStatus(
          job.id,
          status: AnalysisJobStatus.failed,
          errorMessage: 'Job timed out after ${age.inMinutes} minutes',
        );
        continue;
      }

      AppLogger.i('Resuming job ${job.id} (age: ${age.inMinutes}m)');

      // Reset to pending and re-schedule
      await JobQueueStorage.instance.updateJobStatus(
        job.id,
        status: AnalysisJobStatus.pending,
      );

      final isEnhancement = job.type == AnalysisJobType.enhancement;
      await Workmanager().registerOneOffTask(
        job.id,
        isEnhancement ? enhancementTaskName : analysisTaskName,
        inputData: {'jobId': job.id},
        tag: isEnhancement ? enhancementTaskTag : analysisTaskTag,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
    }
  }

  /// Cancel all pending analysis tasks
  Future<void> cancelAllAnalysisTasks() async {
    await Workmanager().cancelByTag(analysisTaskTag);
    AppLogger.i('Cancelled all analysis tasks');
  }

  /// Dispose resources
  void dispose() {
    _jobStatusController.close();
  }
}
