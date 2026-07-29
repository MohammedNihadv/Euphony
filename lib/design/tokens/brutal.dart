import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Euphony's design tokens — a polished, dark Neo-Brutalism.
///
/// Brutalism, but built for a dark canvas: bold flat colour blocks that glow
/// against near-black, crisp *light* frames instead of the black borders that
/// vanish on a dark surface, and hard offset shadows kept as a deliberate
/// accent. The look stays chunky and confident; it just reads correctly now.
///
/// The class keeps its old name and member names so the feature layer did not
/// need a line-by-line rewrite. The one structural change that matters: [ink]
/// is now *light* — it is the colour of text, icons and frames on the dark
/// canvas — while hard shadows have their own near-black [shadow] colour rather
/// than borrowing [ink].
///
/// | token       | job                                        | text on it |
/// |-------------|--------------------------------------------|------------|
/// | [ink]       | text, icons, frames                        | —          |
/// | [accent]    | interactive — buttons, nav, progress       | [onAccent] |
/// | [highlight] | attention fills, brand slab                | [onHighlight] |
/// | [alert]     | destructive, liked, "explicit"             | white      |
///
/// `test/design/brutal_contrast_test.dart` asserts the pairings the app renders
/// clear WCAG AA, so a change that breaks readability fails the build.
abstract final class EuBrutal {
  /// Text, icons and the brutalist frame. Light, because everything sits on the
  /// dark canvas now.
  static const Color ink = Color(0xFFF4F3FA);

  /// The near-black used for hard offset shadows. Kept separate from [ink] so
  /// frames can be light while shadows stay dark.
  static const Color shadow = Color(0xFF04040A);

  /// The interactive accent — buttons, nav, progress, the play button. A vivid
  /// violet that glows on the dark canvas and carries white text at AA (5.55:1).
  static const Color accent = Color(0xFF6A4BE8);

  /// A deeper companion to [accent] for gradients and pressed states.
  static const Color accentDeep = Color(0xFF4E36C4);

  /// Attention fills and the brand slab — the signature brutalist yellow.
  static const Color highlight = Color(0xFFFFE14D);

  /// Destructive and "liked" states. White on it is 4.95:1.
  static const Color alert = Color(0xFFD81B60);

  /// Text and icons on [accent] or [alert].
  static const Color onAccent = Colors.white;

  /// Text and icons on [highlight] — dark, because the fill is bright.
  static const Color onHighlight = Color(0xFF1A1500);

  /// The app canvas and the standard raised surface, exposed so widgets that
  /// build their own decorations match the theme without importing it.
  static const Color canvas = Color(0xFF0D0D14);
  static const Color surface = Color(0xFF17171F);
  static const Color surfaceHigh = Color(0xFF20202C);

  // --- Shadows ------------------------------------------------------------
  // Hard, zero-blur offset copies — the brutalist signature. Coloured [shadow]
  // (near-black), which reads against the raised surfaces on the dark canvas.

  static const List<BoxShadow> smHardShadow = [
    BoxShadow(color: shadow, offset: Offset(2.5, 2.5)),
  ];
  static const List<BoxShadow> hardShadow = [
    BoxShadow(color: shadow, offset: Offset(4, 4)),
  ];
  static const List<BoxShadow> lgHardShadow = [
    BoxShadow(color: shadow, offset: Offset(6, 6)),
  ];

  /// An accent-tinted glow, for the brand mark and hero surfaces.
  static List<BoxShadow> glow(Color color, {double strength = 0.5}) => [
    BoxShadow(
      color: color.withValues(alpha: strength),
      blurRadius: 28,
      spreadRadius: -6,
    ),
  ];

  // --- Borders ------------------------------------------------------------

  /// Cards, sheets, buttons — anything that reads as a slab.
  static const Border border = Border.fromBorderSide(
    BorderSide(color: ink, width: 2),
  );

  /// List rows and chips, where the base weight would crowd the content.
  static const Border thinBorder = Border.fromBorderSide(
    BorderSide(color: ink, width: 1.5),
  );

  static const BorderSide side = BorderSide(color: ink, width: 2);
  static const BorderSide thinSide = BorderSide(color: ink, width: 1.5);

  /// A slab: flat fill, light frame, hard shadow.
  static BoxDecoration boxDecoration({
    required Color color,
    BorderRadiusGeometry borderRadius = const BorderRadius.all(
      Radius.circular(14),
    ),
    List<BoxShadow> shadows = hardShadow,
    Border border = border,
  }) => BoxDecoration(
    color: color,
    borderRadius: borderRadius,
    border: border,
    boxShadow: shadows,
  );

  /// A vertical accent gradient for hero surfaces and the play button.
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentDeep],
  );

  /// The WCAG 2.1 contrast ratio between [a] and [b], from 1.0 to 21.0.
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
