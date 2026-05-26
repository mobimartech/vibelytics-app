import 'package:flutter/material.dart';
import 'colors.dart';

/// Vibelytics Elevation & Shadow Token System
abstract class VShadow {
  VShadow._();

  // ═══════════════════════════════════════════════════════════════════════════
  // ELEVATION LEVELS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Level 0 — No shadow (flat elements, backgrounds)
  static const List<BoxShadow> level0 = [];

  /// Level 1 — Cards at rest
  static const List<BoxShadow> level1 = [
    BoxShadow(
      offset: Offset(0, 1),
      blurRadius: 2,
      color: Color(0x0D000000), // 5% black
    ),
  ];

  /// Level 2 — Raised cards, dropdowns
  static const List<BoxShadow> level2 = [
    BoxShadow(
      offset: Offset(0, 2),
      blurRadius: 8,
      color: Color(0x14000000), // 8% black
    ),
  ];

  /// Level 3 — Modals, floating panels
  static const List<BoxShadow> level3 = [
    BoxShadow(
      offset: Offset(0, 8),
      blurRadius: 24,
      color: Color(0x1F000000), // 12% black
    ),
  ];

  /// Level 4 — Full-screen overlays
  static const List<BoxShadow> level4 = [
    BoxShadow(
      offset: Offset(0, 16),
      blurRadius: 48,
      color: Color(0x29000000), // 16% black
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // HARD SHADOW (Neobrutalist)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Hard Shadow — Default state (4px offset, 0 blur)
  static const List<BoxShadow> hard = [
    BoxShadow(
      offset: Offset(4, 4),
      blurRadius: 0,
      color: VColors.grey900,
    ),
  ];

  /// Hard Shadow — Pressed state (2px offset, 0 blur)
  static const List<BoxShadow> hardPressed = [
    BoxShadow(
      offset: Offset(2, 2),
      blurRadius: 0,
      color: VColors.grey900,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // OUTER GLOW (Luminous Noir)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Create an outer glow with custom color
  static List<BoxShadow> outerGlow(Color color, {
    double blurRadius = 24,
    double spreadRadius = 4,
    double opacity = 0.35,
  }) {
    return [
      BoxShadow(
        color: color.withValues(alpha: opacity),
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
      ),
    ];
  }

  /// Blue outer glow (default selection)
  static List<BoxShadow> get glowBlue => outerGlow(VColors.accentPrimary);

  /// Teal outer glow (community)
  static List<BoxShadow> get glowTeal => outerGlow(VColors.accentSecondary);

  /// Gold outer glow (leaderboard)
  static List<BoxShadow> get glowGold => outerGlow(VColors.gold);

  /// AI gradient glow (enhanced content)
  static List<BoxShadow> get glowAI => outerGlow(VColors.aiGradientMid);
}
