import 'package:flutter/material.dart';

/// Vibelytics Color Token System
///
/// Primitive colors are raw values - never use directly in widgets.
/// Semantic colors are context-aware - use these in widgets.
abstract class VColors {
  VColors._();

  // ═══════════════════════════════════════════════════════════════════════════
  // PRIMITIVE COLORS — Raw hex values
  // ═══════════════════════════════════════════════════════════════════════════

  // Blues
  static const Color blue50 = Color(0xFFE8F4FD);
  static const Color blue100 = Color(0xFFCCE4FB);
  static const Color blue500 = Color(0xFF0F62FE); // Lumen Blue - PRIMARY
  static const Color blue600 = Color(0xFF0D56E0);
  static const Color blue700 = Color(0xFF0A47BD);

  // Teals
  static const Color teal50 = Color(0xFFE8FFFE);
  static const Color teal100 = Color(0xFFB3F5F0);
  static const Color teal500 = Color(0xFF00C2A8); // Fresh Teal - SECONDARY

  // Purples (AI Gradient)
  static const Color purple500 = Color(0xFF8A2BE2); // Electric Violet
  static const Color purple400 = Color(0xFFA66BFF); // Data Purple
  static const Color orchid500 = Color(0xFFC850C0); // Orchid (gradient mid)
  static const Color rose500 = Color(0xFFFF82B2); // Rose Pink (gradient end)

  // Neutrals - Light Mode
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey50 = Color(0xFFF7F9FC); // Soft Paper
  static const Color grey100 = Color(0xFFEEF1F6); // Inset backgrounds
  static const Color grey200 = Color(0xFFE2E6EB); // Subtle borders
  static const Color grey300 = Color(0xFFC4CAD1); // Strong borders
  static const Color grey400 = Color(0xFF8B95A2); // Tertiary text
  static const Color grey500 = Color(0xFF586674); // Secondary text
  static const Color grey900 = Color(0xFF0B1A2A); // Deep Graphite - PRIMARY TEXT

  // Neutrals - Dark Mode
  static const Color dark900 = Color(0xFF0B0B0D); // Pitch Black
  static const Color dark800 = Color(0xFF121216); // Charcoal surface
  static const Color dark700 = Color(0xFF1A1A20); // Elevated surface
  static const Color dark600 = Color(0xFF070712); // Deeper (Enhance mode)

  // Semantic Colors
  static const Color green500 = Color(0xFF198754); // Success
  static const Color green400 = Color(0xFF12B76A); // Positive trend
  static const Color amber500 = Color(0xFFFFB020); // Warning
  static const Color red500 = Color(0xFFE31A2B); // Error
  static const Color red400 = Color(0xFFEF4444); // Negative trend

  // Data Visualization
  static const Color dataBlue = Color(0xFF00A1FF);
  static const Color dataAmber = Color(0xFFFFB020);
  static const Color dataGreen = Color(0xFF12B76A);
  static const Color dataRed = Color(0xFFEF4444);
  static const Color dataPurple = Color(0xFFA66BFF);
  static const Color dataTeal = Color(0xFF00C2A8);

  // Social Provider Colors
  static const Color google = Color(0xFFFFFFFF);
  static const Color apple = Color(0xFF000000);
  static const Color telegram = Color(0xFF0088CC);
  static const Color whatsapp = Color(0xFF25D366);

  // Special
  static const Color polaroidCream = Color(0xFFF5F1E9);
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);

  // ═══════════════════════════════════════════════════════════════════════════
  // SEMANTIC COLORS — LIGHT MODE (Use these in widgets)
  // ═══════════════════════════════════════════════════════════════════════════

  // Backgrounds
  static const Color bgPrimary = white;
  static const Color bgSecondary = grey50;
  static const Color bgTertiary = grey100;
  static const Color bgInverse = grey900;

  // Text
  static const Color textPrimary = grey900;
  static const Color textSecondary = grey500;
  static const Color textTertiary = grey400;
  static const Color textInverse = white;
  static const Color textLink = blue500;

  // Brand / Accent
  static const Color accentPrimary = blue500;
  static const Color accentSecondary = teal500;

  // AI Gradient Colors
  static const Color aiGradientStart = purple500;
  static const Color aiGradientMid = orchid500;
  static const Color aiGradientEnd = rose500;

  // Semantic States
  static const Color success = green500;
  static const Color warning = amber500;
  static const Color error = red500;
  static const Color info = blue500;

  // Surfaces & Borders
  static const Color surfaceCard = white;
  static const Color surfaceOverlay = Color(0x99FFFFFF); // 60% white
  static const Color borderSubtle = grey200;
  static const Color borderStrong = grey300;
  static const Color borderDataRule = grey900; // 2px dividers

  // Shimmer
  static const Color shimmerBase = grey100;
  static const Color shimmerHighlight = grey50;

  // ═══════════════════════════════════════════════════════════════════════════
  // SEMANTIC COLORS — DARK MODE
  // ═══════════════════════════════════════════════════════════════════════════

  static const Color bgPrimaryDark = dark900;
  static const Color bgSecondaryDark = dark800;
  static const Color bgTertiaryDark = dark700;
  static const Color bgInverseDark = grey50;

  static const Color textPrimaryDark = Color(0xFFE6E7E8);
  static const Color textSecondaryDark = Color(0xFF8B8E92);
  static const Color textTertiaryDark = Color(0xFF5A5D62);

  static const Color surfaceCardDark = dark800;
  static const Color surfaceOverlayDark = Color(0x80000000); // 50% black
  static const Color borderSubtleDark = Color(0x14FFFFFF); // 8% white

  // ═══════════════════════════════════════════════════════════════════════════
  // AI GRADIENT
  // ═══════════════════════════════════════════════════════════════════════════

  static const LinearGradient aiGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      aiGradientStart, // Electric Violet - 0%
      aiGradientMid, // Orchid - 50%
      aiGradientEnd, // Rose Pink - 100%
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get the appropriate color based on brightness
  static Color adaptive(
    BuildContext context, {
    required Color light,
    required Color dark,
  }) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  /// Get background primary based on current theme
  static Color background(BuildContext context) =>
      adaptive(context, light: bgPrimary, dark: bgPrimaryDark);

  /// Get text primary based on current theme
  static Color text(BuildContext context) =>
      adaptive(context, light: textPrimary, dark: textPrimaryDark);

  /// Get surface card based on current theme
  static Color card(BuildContext context) =>
      adaptive(context, light: surfaceCard, dark: surfaceCardDark);

  /// Get border subtle based on current theme
  static Color border(BuildContext context) =>
      adaptive(context, light: borderSubtle, dark: borderSubtleDark);

  /// Get text secondary based on current theme
  static Color textSec(BuildContext context) =>
      adaptive(context, light: textSecondary, dark: textSecondaryDark);

  /// Get text tertiary based on current theme
  static Color textTer(BuildContext context) =>
      adaptive(context, light: textTertiary, dark: textTertiaryDark);

  /// Get background secondary based on current theme
  static Color bgSec(BuildContext context) =>
      adaptive(context, light: bgSecondary, dark: bgSecondaryDark);

  /// Get background tertiary based on current theme
  static Color bgTer(BuildContext context) =>
      adaptive(context, light: bgTertiary, dark: bgTertiaryDark);
}
