/// Vibelytics Animation Duration Token System
abstract class VDuration {
  VDuration._();

  // ═══════════════════════════════════════════════════════════════════════════
  // DURATION TOKENS
  // ═══════════════════════════════════════════════════════════════════════════

  /// 0ms — Neobrutalist CTA press, instant state changes
  static const Duration instant = Duration.zero;

  /// 120ms — Ripple, checkbox, micro interactions
  static const Duration micro = Duration(milliseconds: 120);

  /// 180ms — Reaction pop, chip select, fast feedback
  static const Duration fast = Duration(milliseconds: 180);

  /// 260ms — Card expand, image crossfade, standard transitions
  static const Duration normal = Duration(milliseconds: 260);

  /// 360ms — Modal, tile flip, page transitions
  static const Duration emphasized = Duration(milliseconds: 360);

  /// 480ms — Full-screen viewer, AI reveal, dramatic effect
  static const Duration dramatic = Duration(milliseconds: 480);

  /// 3000ms — Glass Halo pulse, shimmer loop, breathing animations
  static const Duration breathing = Duration(milliseconds: 3000);

  /// 60ms — Per-item stagger delay for list animations
  static const Duration staggerDelay = Duration(milliseconds: 60);

  // ═══════════════════════════════════════════════════════════════════════════
  // MILLISECOND VALUES (for AnimationController)
  // ═══════════════════════════════════════════════════════════════════════════

  static const int instantMs = 0;
  static const int microMs = 120;
  static const int fastMs = 180;
  static const int normalMs = 260;
  static const int emphasizedMs = 360;
  static const int dramaticMs = 480;
  static const int breathingMs = 3000;
  static const int staggerDelayMs = 60;
}
