import 'package:flutter/material.dart';

/// Vibelytics Border Radius Token System
abstract class VRadii {
  VRadii._();

  // ═══════════════════════════════════════════════════════════════════════════
  // RAW VALUES
  // ═══════════════════════════════════════════════════════════════════════════

  static const double none = 0;
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 20;
  static const double full = 9999;

  // ═══════════════════════════════════════════════════════════════════════════
  // BORDER RADIUS OBJECTS
  // ═══════════════════════════════════════════════════════════════════════════

  static final BorderRadius noneRadius = BorderRadius.circular(none);
  static final BorderRadius smRadius = BorderRadius.circular(sm);
  static final BorderRadius mdRadius = BorderRadius.circular(md);
  static final BorderRadius lgRadius = BorderRadius.circular(lg);
  static final BorderRadius xlRadius = BorderRadius.circular(xl);
  static final BorderRadius xxlRadius = BorderRadius.circular(xxl);
  static final BorderRadius fullRadius = BorderRadius.circular(full);

  // ═══════════════════════════════════════════════════════════════════════════
  // SEMANTIC ALIASES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Standard cards, photo cards, modals (16px)
  static final BorderRadius card = xlRadius;

  /// Data tiles, secondary buttons (12px)
  static final BorderRadius dataTile = lgRadius;

  /// Buttons (12px)
  static final BorderRadius button = lgRadius;

  /// Input fields (12px or 8px)
  static final BorderRadius input = lgRadius;

  /// Chips, pills (full)
  static final BorderRadius chip = fullRadius;

  /// Bottom sheets, frosted panels (20px)
  static final BorderRadius sheet = xxlRadius;

  /// Avatars (circular)
  static final BorderRadius avatar = fullRadius;

  /// Polaroid frame outer edge (4px)
  static final BorderRadius polaroid = smRadius;

  // ═══════════════════════════════════════════════════════════════════════════
  // TOP-ONLY RADII (for bottom sheets)
  // ═══════════════════════════════════════════════════════════════════════════

  static final BorderRadius sheetTop = BorderRadius.only(
    topLeft: Radius.circular(xxl),
    topRight: Radius.circular(xxl),
  );
}
