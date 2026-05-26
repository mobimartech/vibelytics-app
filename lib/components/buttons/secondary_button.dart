import 'package:flutter/material.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/durations.dart';
import '../../core/utils/haptics.dart';

/// Secondary button - outlined style
///
/// Transparent background with blue border.
class VSecondaryButton extends StatefulWidget {
  const VSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isEnabled = true,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isEnabled;
  final double? width;

  @override
  State<VSecondaryButton> createState() => _VSecondaryButtonState();
}

class _VSecondaryButtonState extends State<VSecondaryButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isEnabled) return;
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  void _handleTap() {
    if (!widget.isEnabled) return;
    VHaptics.light();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = !widget.isEnabled;

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
          color: _isPressed
              ? VColors.accentPrimary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: VRadii.lgRadius,
          border: Border.all(
            color: VColors.accentPrimary.withValues(alpha: isDisabled ? 0.5 : 1.0),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: VType.label.copyWith(
                  color: VColors.accentPrimary.withValues(alpha: isDisabled ? 0.5 : 1.0),
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
typedef SecondaryButton = VSecondaryButton;
