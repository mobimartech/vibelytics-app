import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../components/feedback/progress_ring.dart';
import '../../core/services/analysis_service.dart';
import '../../core/services/credits_service.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/icons.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/typography.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/image_utils.dart';
import 'chat_results_screen.dart';

/// Processing screen for chat analysis.
///
/// Unlike profile analysis, chat analysis completes in a single request,
/// but we still route through a dedicated processing screen so the UX stays
/// consistent and users immediately leave the upload form.
class ChatProcessingScreen extends StatefulWidget {
  const ChatProcessingScreen({
    super.key,
    required this.images,
  });

  final List<XFile> images;

  @override
  State<ChatProcessingScreen> createState() => _ChatProcessingScreenState();
}

class _ChatProcessingScreenState extends State<ChatProcessingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _stepTimer;
  int _currentStep = 0;
  String? _errorMessage;
  bool _isComplete = false;

  List<String> get _steps => [
        'enhance.step_preparing_screenshots'.tr(),
        'enhance.step_reading_flow'.tr(),
        'enhance.step_detecting_tone'.tr(),
        'enhance.step_trust_signals'.tr(),
        'enhance.step_generating_guidance'.tr(),
      ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startAnalysis();
    });
  }

  Future<void> _startAnalysis() async {
    try {
      final locale = context.locale;
      _updateStep(0);

      final dataUris = await _convertImagesToBase64();
      if (dataUris.isEmpty) {
        _showError('enhance.upload_failed');
        return;
      }

      // 10 MB edge cap (Caddy) — fail fast before hitting 413
      final totalBytes = ImageUtils.estimateTotalBytes(dataUris);
      if (totalBytes > ImageUtils.maxAnalysisPayloadBytes) {
        AppLogger.w('Chat payload too large: ${totalBytes ~/ 1024} KB');
        _showError('analysis.payload_too_large');
        return;
      }

      _updateStep(1);
      _startStepAnimation();

      final result = await AnalysisService.instance.analyzeChat(
        screenshotUrls: dataUris,
        language: locale.languageCode,
      );

      if (!result.isSuccess || result.analysisId == null || result.data == null) {
        unawaited(CreditsService.instance.getBalance(forceRefresh: true));
        _showError(result.errorKey ?? 'analysis.failed');
        return;
      }

      if (!mounted) return;

      _stopStepAnimation();
      _updateStep(_steps.length - 1);
      setState(() => _isComplete = true);

      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChatResultsScreen(
            analysisId: result.analysisId!,
            data: result.data!,
            contextUsed: result.contextUsed,
          ),
        ),
      );
    } catch (e, stackTrace) {
      AppLogger.e('Chat analysis processing error',
          error: e, stackTrace: stackTrace);
      unawaited(CreditsService.instance.getBalance(forceRefresh: true));
      _showError('analysis.failed');
    }
  }

  Future<List<String>> _convertImagesToBase64() async {
    try {
      return await ImageUtils.xFilesToBase64DataUris(widget.images);
    } catch (e, stackTrace) {
      AppLogger.e('Chat screenshot conversion error',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  void _startStepAnimation() {
    _stepTimer?.cancel();
    _stepTimer = Timer.periodic(const Duration(milliseconds: 1100), (timer) {
      if (!mounted || _isComplete || _errorMessage != null) {
        timer.cancel();
        return;
      }

      if (_currentStep < _steps.length - 2) {
        _updateStep(_currentStep + 1);
      }
    });
  }

  void _stopStepAnimation() {
    _stepTimer?.cancel();
    _stepTimer = null;
  }

  void _updateStep(int step) {
    if (!mounted) return;
    setState(() => _currentStep = step);
    _controller.forward(from: 0);
  }

  void _showError(String errorKey) {
    _stopStepAnimation();
    if (!mounted) return;
    setState(() => _errorMessage = errorKey);
  }

  void _retry() {
    setState(() {
      _currentStep = 0;
      _errorMessage = null;
      _isComplete = false;
    });
    _startAnalysis();
  }

  @override
  void dispose() {
    _stopStepAnimation();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return _ChatProcessingErrorView(
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
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
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
              ProgressRing(
                progress: progress,
                size: 120,
                strokeWidth: 8,
                useGradient: true,
                showPercentage: true,
              ),
              VSpace.v8,
              Text(
                'enhance.analyzing_title'.tr(),
                style: VType.screenTitle.copyWith(color: VColors.text(context)),
                textAlign: TextAlign.center,
              ),
              VSpace.v4,
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

class _ChatProcessingErrorView extends StatelessWidget {
  const _ChatProcessingErrorView({
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
