import 'package:flutter/material.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/shadows.dart';
import '../../core/utils/haptics.dart';

/// Hard shadow button - Neobrutalist CTA
///
/// Maximum ONE per screen. For primary actions only.
class VHardShadowButton extends StatefulWidget {
  const VHardShadowButton({
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
  State<VHardShadowButton> createState() => _VHardShadowButtonState();
}

class _VHardShadowButtonState extends State<VHardShadowButton> {
  bool _isPressed = false;

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
    VHaptics.medium();
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
        duration: Duration.zero, // Instant for neobrutalist feel
        width: widget.width ?? double.infinity,
        height: 52,
        transform: Matrix4.translationValues(_isPressed ? 2.0 : 0.0, _isPressed ? 2.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          color: VColors.accentPrimary.withValues(alpha: isDisabled ? 0.5 : 1.0),
          borderRadius: VRadii.lgRadius,
          boxShadow: _isPressed ? VShadow.hardPressed : VShadow.hard,
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                      style: VType.label.copyWith(color: VColors.textInverse),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Alias for convenience
typedef HardShadowButton = VHardShadowButton;
