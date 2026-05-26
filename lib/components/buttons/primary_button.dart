import 'package:flutter/material.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/radii.dart';
import '../../core/tokens/durations.dart';
import '../../core/utils/haptics.dart';

/// Primary button - main CTA
///
/// Filled blue button with optional icon and loading state.
class VPrimaryButton extends StatefulWidget {
  const VPrimaryButton({
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
  State<VPrimaryButton> createState() => _VPrimaryButtonState();
}

class _VPrimaryButtonState extends State<VPrimaryButton> {
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
          color: VColors.accentPrimary.withValues(alpha: isDisabled ? 0.5 : 1.0),
          borderRadius: VRadii.lgRadius,
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
typedef PrimaryButton = VPrimaryButton;
