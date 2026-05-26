import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/typography.dart';

/// Circular progress indicator with percentage
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 80,
    this.strokeWidth = 8,
    this.backgroundColor,
    this.progressColor,
    this.useGradient = false,
    this.showPercentage = true,
    this.child,
  });

  final double progress; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? progressColor;
  final bool useGradient;
  final bool showPercentage;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _ProgressRingPainter(
              progress: progress.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              backgroundColor: backgroundColor ?? VColors.bgSec(context),
              progressColor: progressColor ?? VColors.accentPrimary,
              useGradient: useGradient,
            ),
          ),
          Center(
            child: child ??
                (showPercentage
                    ? Text(
                        '${(progress * 100).round()}%',
                        style: VType.label.copyWith(
                          color: VColors.text(context),
                          fontFamily: 'JetBrains Mono',
                        ),
                      )
                    : null),
          ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
    required this.useGradient,
  });

  final double progress;
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;
  final bool useGradient;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      if (useGradient) {
        progressPaint.shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: math.pi * 1.5,
          colors: [
            VColors.aiGradientStart,
            VColors.aiGradientEnd,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      } else {
        progressPaint.color = progressColor;
      }

      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        strokeWidth != oldDelegate.strokeWidth ||
        backgroundColor != oldDelegate.backgroundColor ||
        progressColor != oldDelegate.progressColor;
  }
}

/// Animated progress ring
class AnimatedProgressRing extends StatefulWidget {
  const AnimatedProgressRing({
    super.key,
    required this.progress,
    this.size = 80,
    this.strokeWidth = 8,
    this.duration = const Duration(milliseconds: 800),
    this.useGradient = false,
    this.showPercentage = true,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Duration duration;
  final bool useGradient;
  final bool showPercentage;

  @override
  State<AnimatedProgressRing> createState() => _AnimatedProgressRingState();
}

class _AnimatedProgressRingState extends State<AnimatedProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _previousProgress = _animation.value;
      _animation = Tween<double>(
        begin: _previousProgress,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ProgressRing(
          progress: _animation.value,
          size: widget.size,
          strokeWidth: widget.strokeWidth,
          useGradient: widget.useGradient,
          showPercentage: widget.showPercentage,
        );
      },
    );
  }
}
