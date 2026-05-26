import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../core/background/analysis_job.dart';
import '../../core/background/background_task_manager.dart';
import '../../core/background/job_queue_storage.dart';
import '../../core/services/analysis_service.dart';
import '../../core/services/credits_service.dart';
import '../../core/services/permission_coordinator.dart';
import '../../core/services/photos_service.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/icons.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/haptics.dart';
import '../../components/feedback/progress_ring.dart';
import '../../main_shell.dart';
import 'enhance_gallery_screen.dart';

/// Photo enhancement processing screen with background job support
///
/// Supports two modes:
/// 1. New enhancement: Pass [analysisId] + [referencePhotoBase64]
/// 2. Resume tracking: Pass [existingJobId] to track an existing background job
class EnhanceProcessingScreen extends StatefulWidget {
  const EnhanceProcessingScreen({
    super.key,
    this.analysisId,
    this.referencePhotoBase64,
    this.existingJobId,
  }) : assert(
          (analysisId != null && referencePhotoBase64 != null) ||
              existingJobId != null,
          'Either analysisId+referencePhotoBase64 or existingJobId must be provided',
        );

  /// The analysis ID whose prompts will drive enhancement (for new enhancement)
  final int? analysisId;

  /// Base64 data URI of the reference photo (for new enhancement)
  final String? referencePhotoBase64;

  /// Existing job ID to track (for resuming)
  final String? existingJobId;

  @override
  State<EnhanceProcessingScreen> createState() =>
      _EnhanceProcessingScreenState();
}

class _EnhanceProcessingScreenState extends State<EnhanceProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentStep = 0;
  String? _errorMessage;
  bool _isComplete = false;
  bool _isRunningInBackground = false;
  String? _currentJobId;
  Timer? _pollTimer;

  List<String> get _steps => [
        'enhance.step_preparing_photo'.tr(),
        'enhance.step_generating_enhanced'.tr(),
        'enhance.step_almost_done'.tr(),
      ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Keep screen awake during processing
    WakelockPlus.enable();

    if (widget.existingJobId != null) {
      _currentJobId = widget.existingJobId;
      _trackExistingJob();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showBackgroundProcessingConsent().then((_) {
          if (!mounted) return;
          _startForegroundEnhancement();
        });
      });
    }
  }

  /// Show a consent dialog explaining why background processing is needed.
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
                          style: VType.bodySm
                              .copyWith(color: VColors.text(ctx)),
                        ),
                      ),
                    ],
                  ),
                  VSpace.v2,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(VIcons.privacy, size: 18,
                          color: VColors.accentPrimary),
                      VSpace.h2,
                      Expanded(
                        child: Text(
                          'enhance.background_reason_2'.tr(),
                          style: VType.bodySm
                              .copyWith(color: VColors.text(ctx)),
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

  /// Start enhancement in foreground (submit + poll → display immediately → CDN in background)
  Future<void> _startForegroundEnhancement() async {
    try {
      // Step 1: Preparing / submitting
      _updateStep(0);

      final result = await AnalysisService.instance.enhancePhotos(
        analysisId: widget.analysisId!,
        referencePhotoUrl: widget.referencePhotoBase64!,
        onProgress: (status) {
          if (!mounted) return;
          if (status == 'pending' && _currentStep < 1) {
            _updateStep(1);
          } else if (status == 'processing' && _currentStep < 1) {
            _updateStep(1);
          }
        },
      );

      if (!mounted) return;

      if (!result.isSuccess || result.photos.isEmpty) {
        if (result.creditsRefunded) {
          unawaited(CreditsService.instance.getBalance(forceRefresh: true));
        }
        _showError(result.errorKey ?? 'enhance.failed');
        return;
      }

      VHaptics.success();

      // Refresh credits (3 credits were spent)
      MainShell.refreshCredits(force: true);

      // Step 3: Almost done
      _updateStep(2);

      AppLogger.i('Enhancement complete: ${result.photos.length} photos');
      setState(() => _isComplete = true);
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Navigate to gallery immediately with Replicate URLs (valid ~1hr)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => EnhanceGalleryScreen(
            photos: result.photos,
            referencePhotoBase64: widget.referencePhotoBase64,
          ),
        ),
      );

      // Persist to CDN in background (fire-and-forget)
      // Server updates DB with CDN URLs, so future GET /photos/enhanced returns permanent URLs
      _persistToCdnInBackground(result.photos);
    } catch (e, stackTrace) {
      AppLogger.e('Enhancement processing error',
          error: e, stackTrace: stackTrace);
      unawaited(CreditsService.instance.getBalance(forceRefresh: true));

      if (mounted) {
        _showError('enhance.failed');
      }
    }
  }

  /// Persist temporary Replicate URLs to permanent CDN storage (fire-and-forget).
  /// Server updates ai_enhanced_photos.photo_url with CDN URL on each upload.
  /// Future calls to GET /photos/enhanced will return permanent CDN URLs.
  void _persistToCdnInBackground(List<String> replicateUrls) {
    Future.wait(
      replicateUrls.map((url) => PhotosService.instance.uploadToCdn(
            url,
            type: 'enhanced',
          )),
    ).then((results) {
      final succeeded = results.where((r) => r != null).length;
      AppLogger.i('CDN upload: $succeeded/${replicateUrls.length} persisted');
    }).catchError((e) {
      AppLogger.w('CDN background upload error: $e');
    });
  }

  /// Start enhancement in background. Returns true on success.
  Future<bool> _startBackgroundEnhancement() async {
    try {
      setState(() => _isRunningInBackground = true);

      final job = AnalysisJob.enhancement(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sourceAnalysisId: widget.analysisId!,
        referencePhotoBase64: widget.referencePhotoBase64!,
        language: context.locale.languageCode,
      );

      _currentJobId =
          await BackgroundTaskManager.instance.submitEnhancementJob(job);
      AppLogger.i('Submitted background enhancement job: $_currentJobId');

      // Start polling for status
      _startStatusPolling();
      return true;
    } catch (e, stackTrace) {
      AppLogger.e('Failed to start background enhancement',
          error: e, stackTrace: stackTrace);
      _showError('enhance.failed');
      return false;
    }
  }

  /// Track an existing background job
  Future<void> _trackExistingJob() async {
    setState(() => _isRunningInBackground = true);
    _startStatusPolling();
  }

  /// Poll for job status updates
  void _startStatusPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_currentJobId == null) return;

      final job = await JobQueueStorage.instance.getJob(_currentJobId!);
      if (job == null) return;

      if (mounted) {
        _handleJobStatusUpdate(job);
      }
    });
  }

  /// Handle job status changes
  void _handleJobStatusUpdate(AnalysisJob job) {
    switch (job.status) {
      case AnalysisJobStatus.pending:
        _updateStep(0);
        break;

      case AnalysisJobStatus.processing:
        _updateStep(1);
        break;

      case AnalysisJobStatus.completed:
        _pollTimer?.cancel();
        setState(() => _isComplete = true);

        // Navigate to gallery after a brief delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && job.resultPhotoUrls != null) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) =>
                    EnhanceGalleryScreen(photos: job.resultPhotoUrls),
              ),
            );
          }
        });
        break;

      case AnalysisJobStatus.failed:
        _pollTimer?.cancel();
        unawaited(CreditsService.instance.getBalance(forceRefresh: true));
        _showError(job.errorMessage ?? 'enhance.failed');
        break;
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
        ? 'enhance.enhancement_background'.tr()
        : 'permissions.background_limited'.tr();
  }

  void _retry() {
    setState(() {
      _errorMessage = null;
      _currentStep = 0;
      _isComplete = false;
      _isRunningInBackground = false;
    });

    if (_currentJobId != null) {
      BackgroundTaskManager.instance.retryJob(_currentJobId!);
      _startStatusPolling();
    } else {
      _startForegroundEnhancement();
    }
  }

  /// Move to background and return to previous screen
  Future<void> _moveToBackground() async {
    final permissionsReady = await _ensureBackgroundPermissions();
    if (!mounted) return;

    if (_currentJobId == null &&
        widget.analysisId != null &&
        widget.referencePhotoBase64 != null) {
      // Not yet submitted, start background enhancement
      final success = await _startBackgroundEnhancement();
      if (!mounted || !success) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(_backgroundStatusMessage(permissionsReady)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      // Already submitted, just go back
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
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
    _pollTimer?.cancel();
    WakelockPlus.disable();
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
              // AI icon with gradient
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: VColors.aiGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  VIcons.photoEnhance,
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
                'enhance.enhancing_title'.tr(),
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

              if (_isRunningInBackground) ...[
                VSpace.v2,
                Text(
                  'enhance.running_background'.tr(),
                  style: VType.caption.copyWith(color: VColors.textTer(context)),
                ),
              ],

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

              // Move to background button
              if (!_isComplete)
                TextButton.icon(
                  onPressed: _moveToBackground,
                  icon: Icon(VIcons.chevronLeft, size: 18),
                  label: Text('enhance.continue_background'.tr()),
                  style: TextButton.styleFrom(
                    foregroundColor: VColors.textSec(context),
                  ),
                ),

              VSpace.v4,

              // Tip
              Container(
                padding: VSpace.card,
                decoration: BoxDecoration(
                  color: VColors.adaptive(context, light: VColors.bgSecondary, dark: VColors.bgSecondaryDark),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      VIcons.lightbulb,
                      size: 20,
                      color: VColors.accentSecondary,
                    ),
                    VSpace.h3,
                    Expanded(
                      child: Text(
                        'enhance.enhancement_tip'.tr(),
                        style: VType.bodySm.copyWith(
                          color: VColors.textSec(context),
                        ),
                      ),
                    ),
                  ],
                ),
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
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: VColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  VIcons.error,
                  size: 40,
                  color: VColors.error,
                ),
              ),
              VSpace.v6,
              Text(
                'enhance.enhancement_failed'.tr(),
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
