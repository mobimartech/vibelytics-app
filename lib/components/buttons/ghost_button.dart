import 'package:flutter/material.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';
import '../../core/tokens/durations.dart';
import '../../core/utils/haptics.dart';

/// Ghost button - text-only button
///
/// No background, no border. Used for tertiary actions.
class VGhostButton extends StatefulWidget {
  const VGhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.isEnabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Color? color;
  final bool isEnabled;

  @override
  State<VGhostButton> createState() => _VGhostButtonState();
}

class _VGhostButtonState extends State<VGhostButton> {
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
    final textColor = widget.color ?? VColors.textLink;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedOpacity(
        duration: VDuration.micro,
        opacity: _isPressed ? 0.7 : (isDisabled ? 0.5 : 1.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: 4),
              ],
              Text(
                widget.label,
                style: VType.label.copyWith(color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alias for convenience
typedef GhostButton = VGhostButton;
