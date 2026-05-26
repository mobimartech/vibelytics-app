import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/spacing.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/icons.dart';
import '../../core/utils/haptics.dart';
import '../../components/buttons/primary_button.dart';
import '../../components/buttons/secondary_button.dart';
import '../../components/buttons/ghost_button.dart';
import '../../components/layout/bottom_action_bar_surface.dart';
import '../../components/navigation/standard_screen_app_bar.dart';

/// Glow-up timelapse video preview screen
class GlowupPreviewScreen extends StatefulWidget {
  const GlowupPreviewScreen({super.key});

  @override
  State<GlowupPreviewScreen> createState() => _GlowupPreviewScreenState();
}

class _GlowupPreviewScreenState extends State<GlowupPreviewScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _selectedStyle = 'smooth';
  bool _addMusic = true;
  bool _isPlaying = true;
  static const _transitionStyles = ['smooth', 'dramatic', 'flash'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    VHaptics.light();
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    });
  }

  void _selectStyle(String style) {
    VHaptics.light();
    setState(() {
      _selectedStyle = style;
      // Reset animation for new style
      _animationController.reset();
      _animationController.repeat();
    });
  }

  Future<void> _exportVideo(String platform) async {
    VHaptics.light();
    // Video export requires a native rendering pipeline not yet implemented
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('enhance.feature_coming_soon'.tr()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _saveToPhotos() {
    VHaptics.light();
    // Video save requires a native rendering pipeline not yet implemented
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('enhance.feature_coming_soon'.tr()),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardScreenAppBar(
        title: 'enhance.glowup_video'.tr(),
      ),
      bottomNavigationBar: BottomActionBarSurface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              label: 'enhance.export_tiktok'.tr(),
              onPressed: () => _exportVideo('TikTok'),
            ),
            SizedBox(height: VSpace.screenDenseGap),
            SecondaryButton(
              label: 'enhance.export_reels'.tr(),
              onPressed: () => _exportVideo('Reels'),
            ),
            SizedBox(height: VSpace.screenDenseGap),
            GhostButton(
              label: 'enhance.save_to_photos'.tr(),
              onPressed: _saveToPhotos,
              icon: Icon(VIcons.download, size: 18, color: VColors.textLink),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: VSpace.screenH,
          child: Column(
            children: [
              SizedBox(height: VSpace.screenTopGap),
              AspectRatio(
                aspectRatio: 4 / 5,
                child: _VideoPreview(
                  animation: _animationController,
                  style: _selectedStyle,
                  isPlaying: _isPlaying,
                  onTogglePlayback: _togglePlayback,
                ),
              ),
              SizedBox(height: VSpace.screenSectionGap),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'enhance.your_glowup'.tr(),
                  style: VType.screenSectionTitle.copyWith(
                    color: VColors.text(context),
                  ),
                ),
              ),
              SizedBox(height: VSpace.screenCardGap),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'enhance.transition_style'.tr(),
                    style: VType.screenMeta.copyWith(
                      color: VColors.textSec(context),
                    ),
                  ),
                  VSpace.v2,
                  Row(
                    children: _transitionStyles.map((style) {
                      final isSelected = _selectedStyle == style;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _selectStyle(style),
                          child: Container(
                            margin: EdgeInsets.only(
                              right: style != _transitionStyles.last ? 8 : 0,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? VColors.accentPrimary
                                  : VColors.bgSec(context),
                              borderRadius: VRadii.mdRadius,
                              border: isSelected
                                  ? null
                                  : Border.all(color: VColors.border(context)),
                            ),
                            child: Center(
                              child: Text(
                                'enhance.style_$style'.tr(),
                                style: VType.label.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : VColors.text(context),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              SizedBox(height: VSpace.screenCardGap),
              Container(
                padding: VSpace.card,
                decoration: BoxDecoration(
                  color: VColors.adaptive(
                    context,
                    light: VColors.bgSec(context),
                    dark: VColors.bgSecondaryDark,
                  ),
                  borderRadius: VRadii.lgRadius,
                ),
                child: Row(
                  children: [
                    Icon(
                      VIcons.music,
                      size: 20,
                      color: VColors.text(context),
                    ),
                    VSpace.h2,
                    Expanded(
                      child: Text(
                        'enhance.add_trending_audio'.tr(),
                        style: VType.screenBody.copyWith(
                          color: VColors.text(context),
                        ),
                      ),
                    ),
                    Switch(
                      value: _addMusic,
                      onChanged: (value) {
                        VHaptics.light();
                        setState(() => _addMusic = value);
                      },
                      activeTrackColor: VColors.accentPrimary,
                      thumbColor: WidgetStateProperty.all(Colors.white),
                    ),
                  ],
                ),
              ),
              SizedBox(height: VSpace.screenSectionGap),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoPreview extends StatefulWidget {
  const _VideoPreview({
    required this.animation,
    required this.style,
    required this.isPlaying,
    required this.onTogglePlayback,
  });

  final AnimationController animation;
  final String style;
  final bool isPlaying;
  final VoidCallback onTogglePlayback;

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  // Cache child widgets to avoid rebuilding on every animation frame
  late final Widget _beforeChild;
  late final Widget _afterChild;
  late final Widget _playOverlay;

  @override
  void initState() {
    super.initState();
    // Build and cache static children once
    _beforeChild = ColoredBox(
      color: VColors.bgTer(context),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              VIcons.image,
              size: 80,
              color: VColors.textTer(context),
            ),
            VSpace.v2,
            Text(
              'enhance.before'.tr(),
              style: VType.h3.copyWith(color: VColors.textTer(context)),
            ),
          ],
        ),
      ),
    );

    _afterChild = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            VColors.aiGradientStart.withValues(alpha: 0.2),
            VColors.aiGradientEnd.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (bounds) =>
                  VColors.aiGradient.createShader(bounds),
              child: Icon(
                VIcons.ai,
                size: 80,
                color: Colors.white,
              ),
            ),
            VSpace.v2,
            ShaderMask(
              shaderCallback: (bounds) =>
                  VColors.aiGradient.createShader(bounds),
              child: Text(
                'enhance.after'.tr(),
                style: VType.h3.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );

    _playOverlay = Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: SizedBox(
          width: 64,
          height: 64,
          child: Icon(
            VIcons.play,
            size: 40,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTogglePlayback,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: VColors.bgTer(context),
          borderRadius: VRadii.xlRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: VRadii.xlRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Wrap animation in RepaintBoundary to isolate repaints
              RepaintBoundary(
                child: AnimatedBuilder(
                  animation: widget.animation,
                  builder: (context, child) {
                    final progress = _getAnimationProgress(widget.animation.value);
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // Before image - use FadeTransition-like opacity
                        Opacity(
                          opacity: 1 - progress,
                          child: _beforeChild, // Cached, not rebuilt
                        ),
                        // After image
                        Opacity(
                          opacity: progress,
                          child: _afterChild, // Cached, not rebuilt
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Play/Pause overlay
              if (!widget.isPlaying) _playOverlay,

              // Progress indicator
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: widget.animation,
                    builder: (context, child) {
                      return LinearProgressIndicator(
                        value: widget.animation.value,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          VColors.aiGradientStart,
                        ),
                        minHeight: 3,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getAnimationProgress(double value) {
    switch (widget.style) {
      case 'smooth':
        // Smooth sine wave transition
        return (1 - (value * 2 * 3.14159).cos()) / 2;
      case 'dramatic':
        // Hold at each end, quick transition
        if (value < 0.4) return 0;
        if (value > 0.6) return 1;
        return (value - 0.4) / 0.2;
      case 'flash':
        // Quick flash transition
        if (value < 0.45) return 0;
        if (value < 0.5) return (value - 0.45) / 0.05;
        if (value < 0.95) return 1;
        return 1 - ((value - 0.95) / 0.05);
      default:
        return value;
    }
  }
}

extension on double {
  double cos() => _cos(this);
}

double _cos(double x) {
  // Simple cosine approximation
  x = x % (2 * 3.14159);
  double result = 1.0;
  double term = 1.0;
  for (int n = 1; n <= 10; n++) {
    term *= -x * x / ((2 * n - 1) * (2 * n));
    result += term;
  }
  return result;
}
