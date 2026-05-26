import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../tokens/colors.dart';
import '../tokens/typography.dart';

/// Vibelytics Theme Configuration
///
/// Provides light and dark ThemeData based on the design token system.
class AppTheme {
  AppTheme._();

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: VColors.bgPrimary,
      colorScheme: ColorScheme.light(
        primary: VColors.accentPrimary,
        secondary: VColors.accentSecondary,
        error: VColors.error,
        surface: VColors.bgPrimary,
        onPrimary: VColors.textInverse,
        onSecondary: VColors.textInverse,
        onError: VColors.textInverse,
        onSurface: VColors.textPrimary,
      ),
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: AppBarTheme(
        backgroundColor: VColors.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: VColors.textPrimary,
        iconTheme: const IconThemeData(color: VColors.grey900),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: VColors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: VType.screenTitle.copyWith(color: VColors.textPrimary),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: VColors.bgPrimary,
        selectedItemColor: VColors.accentPrimary,
        unselectedItemColor: VColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: VColors.borderSubtle,
        thickness: 1,
        space: 0,
      ),
      cardTheme: CardThemeData(
        color: VColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VColors.bgSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: VColors.borderSubtle, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: VColors.borderSubtle, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: VColors.accentPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: VColors.error, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: VType.bodyLg.copyWith(color: VColors.textTertiary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VColors.accentPrimary,
          foregroundColor: VColors.textInverse,
          elevation: 0,
          minimumSize: Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: VType.label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VColors.accentPrimary,
          side: BorderSide(color: VColors.accentPrimary, width: 1.5),
          minimumSize: Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: VType.label,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VColors.textLink,
          textStyle: VType.label,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: VColors.bgInverse,
        contentTextStyle: VType.body.copyWith(color: VColors.textInverse),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: VColors.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK THEME
  // ═══════════════════════════════════════════════════════════════════════════

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: VColors.bgPrimaryDark,
      colorScheme: ColorScheme.dark(
        primary: VColors.accentPrimary,
        secondary: VColors.accentSecondary,
        error: VColors.error,
        surface: VColors.bgPrimaryDark,
        onPrimary: VColors.textInverse,
        onSecondary: VColors.textInverse,
        onError: VColors.textInverse,
        onSurface: VColors.textPrimaryDark,
      ),
      textTheme: _buildTextTheme(Brightness.dark),
      appBarTheme: AppBarTheme(
        backgroundColor: VColors.bgPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: VColors.textPrimaryDark,
        iconTheme: IconThemeData(color: VColors.textPrimaryDark),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: VColors.dark900,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        titleTextStyle:
            VType.screenTitle.copyWith(color: VColors.textPrimaryDark),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: VColors.bgSecondaryDark,
        selectedItemColor: VColors.accentPrimary,
        unselectedItemColor: VColors.textTertiaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: VColors.borderSubtleDark,
        thickness: 1,
        space: 0,
      ),
      cardTheme: CardThemeData(
        color: VColors.surfaceCardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: VColors.bgSecondaryDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: VColors.borderSubtleDark, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: VColors.borderSubtleDark, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: VColors.accentPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: VColors.error, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: VType.bodyLg.copyWith(color: VColors.textTertiaryDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: VColors.accentPrimary,
          foregroundColor: VColors.textInverse,
          elevation: 0,
          minimumSize: Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: VType.label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: VColors.accentPrimary,
          side: BorderSide(color: VColors.accentPrimary, width: 1.5),
          minimumSize: Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: VType.label,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: VColors.textLink,
          textStyle: VType.label,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: VColors.bgInverseDark,
        contentTextStyle: VType.body.copyWith(color: VColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: VColors.surfaceCardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TEXT THEME BUILDER
  // ═══════════════════════════════════════════════════════════════════════════

  static TextTheme _buildTextTheme(Brightness brightness) {
    final color = brightness == Brightness.light
        ? VColors.textPrimary
        : VColors.textPrimaryDark;
    final secondaryColor = brightness == Brightness.light
        ? VColors.textSecondary
        : VColors.textSecondaryDark;

    return TextTheme(
      displayLarge: VType.display.copyWith(color: color),
      displayMedium: VType.h1.copyWith(color: color),
      displaySmall: VType.h2.copyWith(color: color),
      headlineLarge: VType.h1.copyWith(color: color),
      headlineMedium: VType.h2.copyWith(color: color),
      headlineSmall: VType.h3.copyWith(color: color),
      titleLarge: VType.h3.copyWith(color: color),
      titleMedium: VType.label.copyWith(color: color),
      titleSmall: VType.labelSm.copyWith(color: color),
      bodyLarge: VType.bodyLg.copyWith(color: color),
      bodyMedium: VType.body.copyWith(color: color),
      bodySmall: VType.bodySm.copyWith(color: secondaryColor),
      labelLarge: VType.label.copyWith(color: color),
      labelMedium: VType.labelSm.copyWith(color: color),
      labelSmall: VType.caption.copyWith(color: secondaryColor),
    );
  }
}
