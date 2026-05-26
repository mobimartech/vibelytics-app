import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Vibelytics Typography Token System
///
/// Font Families:
/// - Inter: 90% of UI (primary)
/// - JetBrains Mono: Analytics data only
/// - Nunito: Community badges only
abstract class VType {
  VType._();

  // ═══════════════════════════════════════════════════════════════════════════
  // FONT FAMILIES
  // ═══════════════════════════════════════════════════════════════════════════

  static const String fontPrimary = 'Inter';
  static const String fontMono = 'JetBrainsMono';
  static const String fontCommunity = 'Nunito';

  // ═══════════════════════════════════════════════════════════════════════════
  // DISPLAY & HEADINGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// 32sp SemiBold - Screen hero titles
  static TextStyle get display => GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 32,
        height: 1.15,
        letterSpacing: -0.02 * 32,
      );

  /// 28sp SemiBold - Section titles
  static TextStyle get h1 => GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 28,
        height: 1.20,
        letterSpacing: -0.01 * 28,
      );

  /// 22sp SemiBold - Subsection headers
  static TextStyle get h2 => GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 22,
        height: 1.25,
        letterSpacing: 0,
      );

  /// 18sp Medium - Card titles
  static TextStyle get h3 => GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        fontSize: 18,
        height: 1.30,
        letterSpacing: 0,
      );

  /// Standard compact push-screen title
  static TextStyle get screenTitle => h3;

  /// Standard section title used on dense feature screens
  static TextStyle get screenSectionTitle =>
      bodyLg.copyWith(fontWeight: FontWeight.w600);

  /// Standard body copy for dense feature screens
  static TextStyle get screenBody => body;

  /// Standard supporting copy for dense feature screens
  static TextStyle get screenSupporting => bodySm;

  /// Standard metadata copy for dense feature screens
  static TextStyle get screenMeta => caption;

  // ═══════════════════════════════════════════════════════════════════════════
  // BODY TEXT
  // ═══════════════════════════════════════════════════════════════════════════

  /// 16sp Regular - Primary body
  static TextStyle get bodyLg => GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: 16,
        height: 1.50,
        letterSpacing: 0,
      );

  /// 14sp Regular - Standard body
  static TextStyle get body => GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 1.45,
        letterSpacing: 0,
      );

  /// 12sp Regular - Supporting text
  static TextStyle get bodySm => GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: 12,
        height: 1.40,
        letterSpacing: 0.01 * 12,
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // LABELS
  // ═══════════════════════════════════════════════════════════════════════════

  /// 14sp Medium - Buttons, tabs
  static TextStyle get label => GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        fontSize: 14,
        height: 1.20,
        letterSpacing: 0.02 * 14,
      );

  /// 12sp Medium - Chips, metadata
  static TextStyle get labelSm => GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        fontSize: 12,
        height: 1.20,
        letterSpacing: 0.04 * 12,
      );

  /// 11sp Light - Timestamps
  static TextStyle get caption => GoogleFonts.inter(
        fontWeight: FontWeight.w300,
        fontSize: 11,
        height: 1.35,
        letterSpacing: 0.02 * 11,
      );

  /// 10sp Medium - Badge counters, UPPERCASE
  static TextStyle get micro => GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        fontSize: 10,
        height: 1.20,
        letterSpacing: 0.08 * 10,
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // ANALYTICS-SPECIFIC (Swiss Metric + Electric Brutalism)
  // ═══════════════════════════════════════════════════════════════════════════

  /// 48sp SemiBold - Profile hero score
  static TextStyle get kpiHero => GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 48,
        height: 1.00,
        letterSpacing: -0.03 * 48,
      );

  /// 32sp SemiBold - Secondary KPIs
  static TextStyle get kpiLarge => GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 32,
        height: 1.10,
        letterSpacing: -0.02 * 32,
      );

  /// 16sp Bold Mono - Metric numbers
  static TextStyle get dataValue => GoogleFonts.jetBrainsMono(
        fontWeight: FontWeight.w700,
        fontSize: 16,
        height: 1.20,
        letterSpacing: 0,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// 11sp Medium - UPPERCASE metric labels
  static TextStyle get dataLabel => GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        fontSize: 11,
        height: 1.20,
        letterSpacing: 0.08 * 11,
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // COMMUNITY-SPECIFIC (Warm Analog)
  // ═══════════════════════════════════════════════════════════════════════════

  /// 11sp Bold Nunito - UPPERCASE rank badges
  static TextStyle get badge => GoogleFonts.nunito(
        fontWeight: FontWeight.w700,
        fontSize: 11,
        height: 1.20,
        letterSpacing: 0.04 * 11,
      );

  /// 13sp SemiBold Nunito - Reaction labels
  static TextStyle get reaction => GoogleFonts.nunito(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        height: 1.30,
        letterSpacing: 0,
      );

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Apply a color to a text style
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }
}
