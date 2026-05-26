import 'package:flutter/material.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/durations.dart';
import '../../core/utils/haptics.dart';

/// AI Gradient button - for AI-related actions
///
/// Purple-pink gradient with shimmer animation.
class VAiGradientButton extends StatefulWidget {
  const VAiGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool isEnabled;
  final double? width;

  @override
  State<VAiGradientButton> createState() => _VAiGradientButtonState();
}

class _VAiGradientButtonState extends State<VAiGradientButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: VDuration.breathing,
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isEnabled || widget.isLoading) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  void _handleTap() {
    if (!widget.isEnabled || widget.isLoading) return;
    VHaptics.light();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = !widget.isEnabled || widget.isLoading;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedContainer(
        duration: VDuration.micro,
        width: widget.width ?? double.infinity,
        height: 52,
        transform: Matrix4.diagonal3Values(_isPressed ? 0.97 : 1.0, _isPressed ? 0.97 : 1.0, 1.0),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: isDisabled
              ? LinearGradient(
                  colors: [
                    VColors.grey400,
                    VColors.grey300,
                  ],
                )
              : VColors.aiGradient,
          borderRadius: VRadii.lgRadius,
        ),
        child: ClipRRect(
          borderRadius: VRadii.lgRadius,
          child: Stack(
            children: [
              // Shimmer effect
              if (!isDisabled)
                AnimatedBuilder(
                  animation: _shimmerAnimation,
                  builder: (context, child) {
                    return Positioned.fill(
                      child: FractionallySizedBox(
                        widthFactor: 0.3,
                        alignment: Alignment(_shimmerAnimation.value, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.1),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              // Content
              Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            widget.icon!,
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.label,
                            style:
                                VType.label.copyWith(color: VColors.textInverse),
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

/// Alias for convenience
typedef AiGradientButton = VAiGradientButton;
