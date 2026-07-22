import 'package:flutter/material.dart';

/// Corner radii and shapes.
///
/// Euphony runs a deliberately rounder scale than stock Material 3 — the
/// expressive look comes largely from this file. Flutter 3.44's superellipse
/// borders are used where a squircle reads better than a circular arc.
abstract final class EuShape {
  static const Radius xsRadius = Radius.circular(8);
  static const Radius smRadius = Radius.circular(14);
  static const Radius mdRadius = Radius.circular(20);
  static const Radius lgRadius = Radius.circular(28);
  static const Radius xlRadius = Radius.circular(36);

  static const BorderRadius xs = BorderRadius.all(xsRadius);
  static const BorderRadius sm = BorderRadius.all(smRadius);
  static const BorderRadius md = BorderRadius.all(mdRadius);
  static const BorderRadius lg = BorderRadius.all(lgRadius);
  static const BorderRadius xl = BorderRadius.all(xlRadius);

  /// Fully rounded — pills, chips, FABs.
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));

  /// Artwork thumbnails in lists and grids.
  static const BorderRadius artwork = md;

  /// The full-screen player's artwork.
  static const BorderRadius heroArtwork = xl;

  /// Top corners only — bottom sheets, the draggable player.
  static const BorderRadius sheetTop = BorderRadius.only(
    topLeft: lgRadius,
    topRight: lgRadius,
  );

  static const RoundedRectangleBorder cardBorder = RoundedRectangleBorder(
    borderRadius: lg,
  );

  static const RoundedRectangleBorder sheetBorder = RoundedRectangleBorder(
    borderRadius: sheetTop,
  );

  /// Squircle used for pressed/selected surfaces where the softer optical
  /// corner matters (Flutter 3.44+).
  static const RoundedSuperellipseBorder squircle = RoundedSuperellipseBorder(
    borderRadius: lg,
  );
}
