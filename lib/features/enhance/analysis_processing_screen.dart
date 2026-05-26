import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../core/background/analysis_job.dart';
import '../../core/background/background_task_manager.dart';
import '../../core/background/job_queue_storage.dart';
import '../../core/services/analysis_service.dart';
import '../../core/services/credits_service.dart';
import '../../core/services/permission_coordinator.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/icons.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/image_utils.dart';
import '../../components/feedback/progress_ring.dart';
import 'analysis_results_screen.dart';

/// AI processing screen with service-level polling
///
/// Supports two modes:
/// 1. New analysis: Pass [images] to start a new analysis
/// 2. Resume tracking: Pass [existingJobId] to track an existing analysis
class AnalysisProcessingScreen extends StatefulWidget {
  const AnalysisProcessingScreen({
    super.key,
    this.images,
    this.existingJobId,
    this.runInBackground = false,
  }) : assert(images != null || existingJobId != null,
            'Either images or existingJobId must be provided');

  final List<XFile>? images;
  final String? existingJobId;
  final bool runInBackground;

  @override
  State<AnalysisProcessingScreen> createState() =>
      _AnalysisProcessingScreenState();
}

class _AnalysisProcessingScreenState extends State<AnalysisProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentStep = 0;
  String? _errorMessage;
  bool _isComplete = false;
  int? _analysisId;
  StreamSubscription<AnalysisJobUpdate>? _jobSub;

  List<String> get _steps => [
        'enhance.step_preparing_images'.tr(),
        'enhance.step_analyzing_features'.tr(),
        'enhance.step_evaluating_composition'.tr(),
        'enhance.step_lighting_quality'.tr(),
        'enhance.step_generating_insights'.tr(),
      ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    if (widget.existingJobId != null) {
      // Resume: try to parse as analysis ID and subscribe to stream
      _analysisId = int.tryParse(widget.existingJobId!);
      if (_analysisId != null) {
        _subscribeToUpdates();
        _updateStep(2); // Show "in progress" state
      }
    } else if (widget.runInBackground) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _startInBackground();
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _startAnalysis();
      });
    }
  }

  /// Show a consent dialog explaining why background processing needs
  /// a foreground service. Returns true if user approves.
  Future<bool> _showBackgroundProcessingConsent() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text('enhance.background_consent_title'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('enhance.background_consent_message'.tr()),
            VSpace.v4,
            Container(
              padding: VSpace.card,
              decoration: BoxDecoration(
                color: VColors.adaptive(ctx,
                    light: VColors.bgSec(context),
                    dark: VColors.bgSecondaryDark),
                borderRadius: VRadii.mdRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(VIcons.zap, size: 18, color: VColors.accentPrimary),
                      VSpace.h2,
                      Expanded(
                        child: Text(
                          'enhance.background_reason_1'.tr(),
                          style: VType.bodySm.copyWith(
                              color: VColors.text(ctx)),
                        ),
                      ),
                    ],
                  ),
                  VSpace.v2,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(VIcons.privacy, size: 18, color: VColors.accentPrimary),
                      VSpace.h2,
                      Expanded(
                        child: Text(
                          'enhance.background_reason_2'.tr(),
                          style: VType.bodySm.copyWith(
                              color: VColors.text(ctx)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('common.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('common.continue'.tr()),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Submit analysis as a background job and pop back immediately.
  Future<void> _startInBackground() async {
    try {
      final permissionsReady = await _ensureBackgroundPermissions();
      if (!mounted) return;

      final locale = context.locale;
      _updateStep(0);

      final base64DataUris = await _convertImagesToBase64();
      if (base64DataUris.isEmpty) {
        _showError('analysis.failed');
        return;
      }

      if (!mounted) return;

      final job = AnalysisJob.profile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        base64Images: base64DataUris,
        language: locale.languageCode,
      );

      await BackgroundTaskManager.instance.submitJob(job);
      AppLogger.i('Analysis submitted to background: ${job.id}');

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(_backgroundStatusMessage(permissionsReady)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.e('Background analysis submission error',
          error: e, stackTrace: stackTrace);
      _showError('analysis.failed');
    }
  }

  /// Submit analysis and hand off polling to service singleton
  Future<void> _startAnalysis() async {
    try {
      final locale = context.locale;
      _updateStep(0);

      // Convert images to base64
      final base64DataUris = await _convertImagesToBase64();
      if (base64DataUris.isEmpty) {
        _showError('analysis.failed');
        return;
      }

      // Edge enforces 10 MB body cap (Caddy). Fail fast with a clear
      // message instead of letting the request hit a 413 with empty body.
      final totalBytes = ImageUtils.estimateTotalBytes(base64DataUris);
      if (totalBytes > ImageUtils.maxAnalysisPayloadBytes) {
        AppLogger.w('Analysis payload too large: ${totalBytes ~/ 1024} KB');
        _showError('analysis.payload_too_large');
        return;
      }

      _updateStep(1);

      // Submit to API — get analysis_id back
      int? id;
      try {
        final submitResponse = await ApiClient.instance.postLongRunning(
          Endpoints.analysis,
          body: {
            'screenshots': base64DataUris,
            'language': locale.languageCode,
          },
          timeout: const Duration(minutes: 2),
        );

        if (submitResponse['success'] != true) {
          _showError('analysis.failed');
          return;
        }

        final analysisId = submitResponse['analysis_id'];
        id = analysisId is int
            ? analysisId
            : int.tryParse(analysisId?.toString() ?? '');
      } on PayloadTooLargeException {
        // Edge-level 413 (someone bypassed the pre-check, or screenshots
        // grew between estimate and send). Surface the same friendly key.
        _showError('analysis.payload_too_large');
        return;
      } on ApiException catch (e) {
        // Per api.md §8: 429 ANALYSIS_IN_PROGRESS doesn't include the
        // in-flight id, so look it up via /analysis/list and resume polling.
        if (e.statusCode == 429) {
          AppLogger.i('429 in-progress — looking up in-flight analysis');
          id = await AnalysisService.instance.findInFlightAnalysisId();
          if (id == null) {
            _showError('analysis.in_progress');
            return;
          }
          AppLogger.i('Resumed in-flight analysis: $id');
        } else {
          rethrow;
        }
      }

      if (id == null) {
        _showError('analysis.failed');
        return;
      }

      _analysisId = id;
      AppLogger.i('Analysis submitted, id: $id — handing off to service polling');

      // Also save as background job (insurance if app is killed)
      try {
        final job = AnalysisJob.profile(
          id: id.toString(),
          base64Images: base64DataUris,
          language: locale.languageCode,
        );
        await JobQueueStorage.instance.saveJob(
          job.copyWith(
            status: AnalysisJobStatus.processing,
            analysisId: id,
          ),
        );
      } catch (e) {
        AppLogger.w('Failed to save backup job: $e');
      }

      _updateStep(2);

      // Start service-level polling (survives navigation)
      AnalysisService.instance.startServicePolling(id);

      // Subscribe to updates
      _subscribeToUpdates();
    } catch (e, stackTrace) {
      AppLogger.e('Analysis submission error', error: e, stackTrace: stackTrace);
      unawaited(CreditsService.instance.getBalance(forceRefresh: true));
      _showError('analysis.failed');
    }
  }

  /// Subscribe to the service-level broadcast stream
  void _subscribeToUpdates() {
    _jobSub?.cancel();
    _jobSub = AnalysisService.instance.jobUpdates.listen((update) {
      if (update.analysisId != _analysisId) return;
      if (!mounted) return;

      if (update.status == AnalysisStatus.processing) {
        _updateStep(3);
      } else if (update.status.isCompleted && update.result?.isSuccess == true) {
        final resultId = update.result?.analysisId;
        final resultData = update.result?.data;
        final promptsCount = update.result?.photoPromptsCount ?? 0;
        if (resultId == null || resultData == null) return;

        _updateStep(4);
        setState(() => _isComplete = true);
        _markJobCompleted(resultId);

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => AnalysisResultsScreen(
                  analysisId: resultId,
                  data: resultData,
                  photoPromptsCount: promptsCount,
                ),
              ),
            );
          }
        });
      } else if (update.status.isFailed) {
        unawaited(CreditsService.instance.getBalance(forceRefresh: true));
        _showError(update.result?.errorKey ?? 'analysis.failed');
      }
    });
  }

  Future<void> _markJobCompleted(int analysisId) async {
    try {
      await JobQueueStorage.instance.updateJobStatus(
        analysisId.toString(),
        status: AnalysisJobStatus.completed,
        analysisId: analysisId,
      );
    } catch (e, st) {
      AppLogger.e('Failed to mark job completed in local DB', error: e, stackTrace: st);
    }
  }

  Future<List<String>> _convertImagesToBase64() async {
    if (widget.images == null) return [];
    try {
      return await ImageUtils.xFilesToBase64DataUris(widget.images!);
    } catch (e, stackTrace) {
      AppLogger.e('Image conversion error', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  void _updateStep(int step) {
    if (mounted) {
      setState(() => _currentStep = step);
      _controller.forward(from: 0);
    }
  }

  void _showError(String errorKey) {
    if (mounted) {
      setState(() => _errorMessage = errorKey);
    }
  }

  Future<bool> _ensureBackgroundPermissions() async {
    final notificationInfo =
        await PermissionCoordinator.instance.ensureNotificationPermission(
      context,
    );
    if (!mounted) return false;

    final batteryInfo =
        await PermissionCoordinator.instance.ensureBatteryOptimization(
      context,
    );
    if (!mounted) return false;

    return notificationInfo.isAllowed && batteryInfo.isAllowed;
  }

  String _backgroundStatusMessage(bool permissionsReady) {
    return permissionsReady
        ? 'enhance.analysis_background'.tr()
        : 'permissions.background_limited'.tr();
  }

  void _retry() {
    setState(() {
      _errorMessage = null;
      _currentStep = 0;
      _isComplete = false;
    });
    _startAnalysis();
  }

  /// Navigate to main screen — polling continues in service singleton
  Future<void> _goBack() async {
    final approved = await _showBackgroundProcessingConsent();
    if (!mounted || !approved) return;

    final permissionsReady = await _ensureBackgroundPermissions();
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    // Pop all the way back to the main shell instead of just the previous screen
    Navigator.of(context).popUntil((route) => route.isFirst);
    if (_analysisId != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_backgroundStatusMessage(permissionsReady)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _jobSub?.cancel();
    // NOTE: service polling is NOT cancelled here — it runs in the singleton
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _ErrorView(
        errorKey: _errorMessage!,
        onRetry: _retry,
        onBack: () => Navigator.of(context).pop(),
      );
    }

    final progress = _isComplete ? 1.0 : (_currentStep + 1) / _steps.length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: VSpace.screenH,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // AI icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: VColors.aiGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  VIcons.aiAnalysis,
                  size: 40,
                  color: Colors.white,
                ),
              ),

              VSpace.v8,

              // Progress ring
              ProgressRing(
                progress: progress,
                size: 120,
                strokeWidth: 8,
                useGradient: true,
                showPercentage: true,
              ),

              VSpace.v8,

              // Title
              Text(
                'enhance.analyzing_title'.tr(),
                style: VType.screenTitle.copyWith(color: VColors.text(context)),
                textAlign: TextAlign.center,
              ),

              VSpace.v4,

              // Current step
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _steps[_currentStep],
                  key: ValueKey(_currentStep),
                  style: VType.body.copyWith(color: VColors.textSec(context)),
                  textAlign: TextAlign.center,
                ),
              ),

              VSpace.v2,
              Text(
                'enhance.processing_hint'.tr(),
                style: VType.caption.copyWith(color: VColors.textTer(context)),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              VSpace.v8,

              // Step indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_steps.length, (index) {
                  final isComplete = index <= _currentStep;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isComplete ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isComplete
                          ? VColors.accentPrimary
                          : VColors.bgSec(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),

              VSpace.v8,

              // Continue in background button
              if (!_isComplete)
                TextButton.icon(
                  onPressed: _goBack,
                  icon: Icon(VIcons.back, size: 18),
                  label: Text('enhance.continue_background'.tr()),
                  style: TextButton.styleFrom(
                    foregroundColor: VColors.textSec(context),
                  ),
                ),

              VSpace.v4,

              // Tip
              Text(
                'enhance.tip_rate'.tr(),
                style: VType.screenMeta.copyWith(color: VColors.textTer(context)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.errorKey,
    required this.onRetry,
    required this.onBack,
  });

  final String errorKey;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: VSpace.screenH,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                VIcons.error,
                size: 64,
                color: VColors.error,
              ),
              VSpace.v6,
              Text(
                'enhance.analysis_failed'.tr(),
                style: VType.screenTitle.copyWith(color: VColors.text(context)),
                textAlign: TextAlign.center,
              ),
              VSpace.v3,
              Text(
                errorKey.tr(),
                style: VType.body.copyWith(color: VColors.textSec(context)),
                textAlign: TextAlign.center,
              ),
              VSpace.v8,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: onBack,
                    child: Text('common.back'.tr()),
                  ),
                  VSpace.h4,
                  ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VColors.accentPrimary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('common.retry'.tr()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
