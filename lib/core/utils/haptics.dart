import 'package:flutter/services.dart';

/// Haptic feedback utilities
///
/// Provides consistent haptic feedback across the app.
/// Uses system haptic engine - no additional packages needed.
abstract class VHaptics {
  VHaptics._();

  /// Light impact — taps, toggles, selections
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium impact — confirmations, successful actions
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact — destructive actions, warnings
  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  /// Selection changed — picker value changes
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }

  /// Success — AI enhancement complete, purchases
  static Future<void> success() async {
    // Use a pattern: medium -> light for success feeling
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.lightImpact();
  }

  /// Error — failed actions, validation errors
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
  }

  /// Rating tap — star selection
  static Future<void> rating() async {
    await HapticFeedback.lightImpact();
  }

  /// Double tap like
  static Future<void> like() async {
    await HapticFeedback.mediumImpact();
  }
}
