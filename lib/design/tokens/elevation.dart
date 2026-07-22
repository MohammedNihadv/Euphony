/// Elevation steps.
///
/// Euphony leans on tonal surface colour rather than shadow, so most surfaces
/// sit at [flat] and only genuinely floating things cast one.
abstract final class EuElevation {
  static const double flat = 0;
  static const double raised = 1;
  static const double floating = 3;
  static const double overlay = 6;

  /// The mini player strip — separated from content, but not lifted off it.
  static const double miniPlayer = raised;

  /// Bottom sheets and the expanded player.
  static const double sheet = overlay;
}
