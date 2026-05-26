import 'package:flutter/material.dart';

/// Vibelytics Spacing Token System
///
/// Based on 8pt grid system with semantic aliases.
abstract class VSpace {
  VSpace._();

  // ═══════════════════════════════════════════════════════════════════════════
  // SPACING SCALE
  // ═══════════════════════════════════════════════════════════════════════════

  static const double space0 = 0;
  static const double space05 = 2;
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;
  static const double space16 = 64;

  // ═══════════════════════════════════════════════════════════════════════════
  // SEMANTIC ALIASES
  // ═══════════════════════════════════════════════════════════════════════════

  static const double cardPadding = space4; // 16px
  static const double dataTilePadding = space3; // 12px (tighter for density)
  static const double communityCardPadding = space5; // 20px (more breathing room)
  static const double screenMargin = space4; // 16px
  static const double cardGap = space3; // 12px
  static const double sectionGap = space6; // 24px
  static const double screenTopGap = space4;
  static const double screenSectionGap = space6;
  static const double screenCardGap = space3;
  static const double screenDenseGap = space2;
  static const double screenActionInset = space4;
  static const double bottomBarHorizontal = space5;
  static const double bottomBarVertical = space4;

  // ═══════════════════════════════════════════════════════════════════════════
  // VERTICAL SIZEDBOX HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static SizedBox get v0 => const SizedBox(height: space0);
  static SizedBox get v05 => const SizedBox(height: space05);
  static SizedBox get v1 => const SizedBox(height: space1);
  static SizedBox get v2 => const SizedBox(height: space2);
  static SizedBox get v3 => const SizedBox(height: space3);
  static SizedBox get v4 => const SizedBox(height: space4);
  static SizedBox get v5 => const SizedBox(height: space5);
  static SizedBox get v6 => const SizedBox(height: space6);
  static SizedBox get v8 => const SizedBox(height: space8);
  static SizedBox get v10 => const SizedBox(height: space10);
  static SizedBox get v12 => const SizedBox(height: space12);
  static SizedBox get v16 => const SizedBox(height: space16);

  // ═══════════════════════════════════════════════════════════════════════════
  // HORIZONTAL SIZEDBOX HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static SizedBox get h0 => const SizedBox(width: space0);
  static SizedBox get h05 => const SizedBox(width: space05);
  static SizedBox get h1 => const SizedBox(width: space1);
  static SizedBox get h2 => const SizedBox(width: space2);
  static SizedBox get h3 => const SizedBox(width: space3);
  static SizedBox get h4 => const SizedBox(width: space4);
  static SizedBox get h5 => const SizedBox(width: space5);
  static SizedBox get h6 => const SizedBox(width: space6);
  static SizedBox get h8 => const SizedBox(width: space8);
  static SizedBox get h10 => const SizedBox(width: space10);
  static SizedBox get h12 => const SizedBox(width: space12);
  static SizedBox get h16 => const SizedBox(width: space16);

  // ═══════════════════════════════════════════════════════════════════════════
  // EDGEINSETS PRESETS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Standard screen horizontal padding (16px)
  static EdgeInsets get screenH => const EdgeInsets.symmetric(horizontal: space4);

  /// Standard card padding (16px all sides)
  static EdgeInsets get card => const EdgeInsets.all(space4);

  /// Dense card padding for data tiles (12px all sides)
  static EdgeInsets get cardDense => const EdgeInsets.all(space3);

  /// Loose card padding for community cards (20px all sides)
  static EdgeInsets get cardLoose => const EdgeInsets.all(space5);

  /// Screen padding (horizontal 16px, vertical 24px)
  static EdgeInsets get screen => const EdgeInsets.symmetric(
        horizontal: space4,
        vertical: space6,
      );

  /// List item padding
  static EdgeInsets get listItem => const EdgeInsets.symmetric(
        horizontal: space4,
        vertical: space3,
      );
}
