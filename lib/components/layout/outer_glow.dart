import 'package:flutter/material.dart';
import '../../core/tokens/colors.dart';

/// Outer glow effect for selection states
class OuterGlow extends StatelessWidget {
  const OuterGlow({
    super.key,
    required this.child,
    this.glowColor,
    this.glowRadius = 12,
    this.glowOpacity = 0.4,
    this.isActive = true,
    this.borderRadius,
  });

  final Widget child;
  final Color? glowColor;
  final double glowRadius;
  final double glowOpacity;
  final bool isActive;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    if (!isActive) return child;

    final effectiveColor = glowColor ?? VColors.accentPrimary;

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: effectiveColor.withValues(alpha: glowOpacity),
            blurRadius: glowRadius,
            spreadRadius: glowRadius / 4,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Animated glow that pulses
class PulsingGlow extends StatefulWidget {
  const PulsingGlow({
    super.key,
    required this.child,
    this.glowColor,
    this.minGlowRadius = 8,
    this.maxGlowRadius = 16,
    this.duration = const Duration(milliseconds: 1500),
    this.isActive = true,
    this.borderRadius,
  });

  final Widget child;
  final Color? glowColor;
  final double minGlowRadius;
  final double maxGlowRadius;
  final Duration duration;
  final bool isActive;
  final BorderRadius? borderRadius;

  @override
  State<PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<PulsingGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: widget.minGlowRadius,
      end: widget.maxGlowRadius,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulsingGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return widget.child;

    final effectiveColor = widget.glowColor ?? VColors.accentPrimary;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            boxShadow: [
              BoxShadow(
                color: effectiveColor.withValues(alpha: 0.4),
                blurRadius: _animation.value,
                spreadRadius: _animation.value / 4,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
