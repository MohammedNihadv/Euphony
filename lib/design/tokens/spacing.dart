/// Spacing scale.
///
/// A 4dp base grid. Feature code uses these names, never raw numbers, so the
/// whole app's density can be retuned from one file.
abstract final class EuSpace {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Horizontal padding for full-width screen content.
  static const double screenGutter = lg;

  /// Gap between cards in a horizontal carousel.
  static const double carouselGap = md;

  /// Height reserved for the mini player above the bottom navigation bar.
  static const double miniPlayerHeight = 64;
}
