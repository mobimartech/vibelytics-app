import 'package:flutter/material.dart';

/// Vibelytics Animation Curves Token System
abstract class VCurves {
  VCurves._();

  // ═══════════════════════════════════════════════════════════════════════════
  // EASING CURVES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Material 3 standard — most interactions
  static const Curve standard = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Enter animations — decelerate into view
  static const Curve decelerate = Cubic(0.0, 0.0, 0.0, 1.0);

  /// Exit animations — accelerate out of view
  static const Curve accelerate = Cubic(0.3, 0.0, 1.0, 1.0);

  /// Reaction bounce — overshoot effect
  static const Curve overshoot = Cubic(0.34, 1.56, 0.64, 1.0);

  /// Feed reveal — playful entrance (Prism pattern)
  static const Curve playful = Cubic(0.16, 1.0, 0.3, 1.0);
}

/// Vibelytics Spring Physics Token System
abstract class VSprings {
  VSprings._();

  // ═══════════════════════════════════════════════════════════════════════════
  // SPRING DESCRIPTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Gentle — Image enhancement reveal (Lumen)
  static const SpringDescription gentle = SpringDescription(
    mass: 1,
    stiffness: 400,
    damping: 28,
  );

  /// Snappy — Drag-to-dismiss (Lumen)
  static const SpringDescription snappy = SpringDescription(
    mass: 1,
    stiffness: 700,
    damping: 28,
  );

  /// Bouncy — Social reactions (Kinetic)
  static const SpringDescription bouncy = SpringDescription(
    mass: 1,
    stiffness: 300,
    damping: 12,
  );

  /// Rating — Star/heart tap (Warm Analog)
  static const SpringDescription rating = SpringDescription(
    mass: 1,
    stiffness: 350,
    damping: 15,
  );
}
