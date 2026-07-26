import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Neo-Brutalist design tokens: hard shadows, thick borders, flat colour.
///
/// The palette is deliberately three accents, not six. Neo-brutalism reads as
/// intentional when a small set of colours recurs with meaning, and as noise
/// when every surface picks a different one. Each accent has one job:
///
/// | token       | job                          | text on it |
/// |-------------|------------------------------|------------|
/// | [accent]    | interactive — buttons, nav, progress | white |
/// | [highlight] | attention fills, artwork placeholders | [ink] |
/// | [alert]     | destructive, liked, "explicit" | white     |
///
/// Contrast is not decorative here. PRODUCT.md commits to WCAG AA, and the
/// previous values did not reach it: white on the old `#7C5CFF` was 4.35:1 and
/// white on `#FF4081` was 3.33:1, both under the 4.5:1 floor for body text —
/// on filled buttons whose labels are white. The values below are the darkened
/// equivalents that clear it while keeping the same hue.
///
/// `test/design/brutal_contrast_test.dart` asserts these ratios, so a future
/// tweak that breaks accessibility fails the build instead of shipping.
abstract final class EuBrutal {
  /// Borders, hard shadows, and text on light or [highlight] surfaces.
  static const Color ink = Color(0xFF121218);

  /// The interactive accent.
  ///
  /// Squeezed by two floors at once, which is what makes brutalism awkward to
  /// tune: it carries white label text (WCAG AA wants 4.5:1) *and* sits inside
  /// an [ink] border (WCAG 1.4.11 wants 3:1 for non-text boundaries). Too dark
  /// and the border disappears into it; too light and the label does. This
  /// lands at 5.55:1 on white and 3.39:1 against the border.
  static const Color accent = Color(0xFF6A4BE8);

  /// Attention fills only — never a text or icon colour. Yellow on white is
  /// 1.25:1, effectively invisible; [ink] on yellow is 15.815:1.
  static const Color highlight = Color(0xFFFFEB3B);

  /// Destructive and "liked" states. White text on it: 4.95:1.
  static const Color alert = Color(0xFFD81B60);

  /// Text and icons that sit on [accent] or [alert].
  static const Color onAccent = Colors.white;

  /// Text and icons that sit on [highlight].
  static const Color onHighlight = ink;

  // --- Shadows ------------------------------------------------------------
  // Zero blur is the whole idea: a brutalist shadow is an offset copy of the
  // shape, not a soft glow. One scale, three steps, so depth stays legible.

  static const List<BoxShadow> smHardShadow = [
    BoxShadow(color: ink, offset: Offset(2.5, 2.5)),
  ];
  static const List<BoxShadow> hardShadow = [
    BoxShadow(color: ink, offset: Offset(4, 4)),
  ];
  static const List<BoxShadow> lgHardShadow = [
    BoxShadow(color: ink, offset: Offset(6, 6)),
  ];

  // --- Borders ------------------------------------------------------------

  /// Cards, sheets, buttons — anything that reads as a slab.
  static const Border border = Border.fromBorderSide(
    BorderSide(color: ink, width: 2.5),
  );

  /// List rows and chips, where the base weight would crowd the content.
  static const Border thinBorder = Border.fromBorderSide(
    BorderSide(color: ink, width: 1.5),
  );

  static const BorderSide side = BorderSide(color: ink, width: 2.5);
  static const BorderSide thinSide = BorderSide(color: ink, width: 1.5);

  /// A slab: flat fill, hard border, offset shadow.
  static BoxDecoration boxDecoration({
    required Color color,
    BorderRadiusGeometry borderRadius = const BorderRadius.all(
      Radius.circular(12),
    ),
    List<BoxShadow> shadows = hardShadow,
    Border border = border,
  }) => BoxDecoration(
    color: color,
    borderRadius: borderRadius,
    border: border,
    boxShadow: shadows,
  );

  /// The WCAG 2.1 contrast ratio between [a] and [b], from 1.0 to 21.0.
  ///
  /// Exposed so the palette can assert its own accessibility in tests rather
  /// than relying on the values having been checked once by hand.
  static double contrastRatio(Color a, Color b) {
    final lighter = _relativeLuminance(a);
    final darker = _relativeLuminance(b);
    final (hi, lo) = lighter > darker ? (lighter, darker) : (darker, lighter);
    return (hi + 0.05) / (lo + 0.05);
  }

  static double _relativeLuminance(Color color) {
    double channel(double component) => component <= 0.03928
        ? component / 12.92
        : math.pow((component + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * channel(color.r) +
        0.7152 * channel(color.g) +
        0.0722 * channel(color.b);
  }
}
