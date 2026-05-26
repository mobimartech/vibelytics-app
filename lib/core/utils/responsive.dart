import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Responsive utilities using Sizer
///
/// Uses optimized MediaQuery accessors (sizeOf, paddingOf, orientationOf)
/// to minimize unnecessary rebuilds.
class Responsive {
  Responsive._();

  /// Check if device is mobile based on screen width
  /// Uses MediaQuery.sizeOf for optimized rebuilds
  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 600;
  }

  /// Check if device is tablet based on screen width
  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 600;
  }

  /// Check if orientation is portrait
  /// Uses MediaQuery.orientationOf for optimized rebuilds
  static bool isPortrait(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.portrait;
  }

  /// Check if orientation is landscape
  static bool isLandscape(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape;
  }

  /// Get screen size
  static Size screenSize(BuildContext context) {
    return MediaQuery.sizeOf(context);
  }

  /// Get safe area padding
  static EdgeInsets safePadding(BuildContext context) {
    return MediaQuery.paddingOf(context);
  }

  /// Get view insets (keyboard, etc.)
  static EdgeInsets viewInsets(BuildContext context) {
    return MediaQuery.viewInsetsOf(context);
  }

  /// Get value based on device type
  static T device<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
  }) {
    if (isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile;
  }

  /// Get value based on orientation
  static T orientation<T>(
    BuildContext context, {
    required T portrait,
    required T landscape,
  }) {
    return isPortrait(context) ? portrait : landscape;
  }

  /// Responsive padding
  static EdgeInsets screenPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: device(context, mobile: 20.0, tablet: 40.0),
    );
  }

  /// Responsive grid columns
  static int gridColumns(BuildContext context) {
    return device(context, mobile: 2, tablet: 4);
  }
}

/// Extension for responsive sizing using Sizer
extension ResponsiveExtension on num {
  /// Percentage of screen width
  double get vw => w;

  /// Percentage of screen height
  double get vh => h;

  /// Responsive font size
  double get rsp => sp;
}
