import 'package:flutter/material.dart';

/// UX Context modes for Vibelytics
///
/// Different parts of the app have different visual personalities:
/// - canvas: Default neutral state (home, profile)
/// - enhance: AI enhancement flow (processing, results)
/// - analyze: Analytics and data visualization
/// - community: Social features (feed, ratings, comments)
enum VibelyticsMode {
  canvas,
  enhance,
  analyze,
  community,
}

/// InheritedWidget that provides the current UX context mode
///
/// Components can check this to adjust their appearance based on context.
/// For example:
/// - DataTile uses JetBrains Mono for numbers in `analyze` mode
/// - FeedPhotoCard applies Polaroid frame in `community` mode
class VibelyticsContext extends InheritedWidget {
  const VibelyticsContext({
    super.key,
    required this.mode,
    required super.child,
  });

  final VibelyticsMode mode;

  /// Get the current mode from context
  /// Returns `canvas` if no ancestor VibelyticsContext found
  static VibelyticsMode of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<VibelyticsContext>();
    return widget?.mode ?? VibelyticsMode.canvas;
  }

  /// Check if we're in a specific mode
  static bool isMode(BuildContext context, VibelyticsMode mode) {
    return of(context) == mode;
  }

  /// Check if we're in enhance mode (AI processing)
  static bool isEnhance(BuildContext context) => isMode(context, VibelyticsMode.enhance);

  /// Check if we're in analyze mode (data visualization)
  static bool isAnalyze(BuildContext context) => isMode(context, VibelyticsMode.analyze);

  /// Check if we're in community mode (social features)
  static bool isCommunity(BuildContext context) => isMode(context, VibelyticsMode.community);

  @override
  bool updateShouldNotify(VibelyticsContext oldWidget) {
    return mode != oldWidget.mode;
  }
}

/// Extension for easy context mode wrapping
extension VibelyticsContextExtension on Widget {
  /// Wrap this widget with a VibelyticsContext
  Widget withMode(VibelyticsMode mode) {
    return VibelyticsContext(mode: mode, child: this);
  }

  /// Wrap with enhance mode
  Widget get withEnhanceMode => withMode(VibelyticsMode.enhance);

  /// Wrap with analyze mode
  Widget get withAnalyzeMode => withMode(VibelyticsMode.analyze);

  /// Wrap with community mode
  Widget get withCommunityMode => withMode(VibelyticsMode.community);
}
