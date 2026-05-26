/// Central place for temporary feature toggles.
abstract class FeatureFlags {
  FeatureFlags._();

  /// Chat analysis is temporarily disabled.
  static const bool chatAnalysisEnabled = false;
}
