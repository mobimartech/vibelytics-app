import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/tokens/colors.dart';
import '../../core/tokens/radii.dart';

/// Frosted glass panel with blur effect
class FrostedPanel extends StatelessWidget {
  const FrostedPanel({
    super.key,
    required this.child,
    this.blurAmount = 20,
    this.opacity = 0.8,
    this.borderRadius,
    this.padding,
  });

  final Widget child;
  final double blurAmount;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? VRadii.lgRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurAmount,
          sigmaY: blurAmount,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: VColors.card(context).withValues(alpha: opacity),
            borderRadius: borderRadius ?? VRadii.lgRadius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Frosted overlay that covers the entire screen
class FrostedOverlay extends StatelessWidget {
  const FrostedOverlay({
    super.key,
    required this.child,
    this.blurAmount = 10,
    this.overlayColor,
  });

  final Widget child;
  final double blurAmount;
  final Color? overlayColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurAmount,
            sigmaY: blurAmount,
          ),
          child: Container(
            color: overlayColor ?? Colors.black.withValues(alpha: 0.3),
          ),
        ),
        child,
      ],
    );
  }
}
