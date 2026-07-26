import 'package:flutter/material.dart';

/// Corner radii and shapes for Euphony's Neo-Brutalist aesthetic.
abstract final class EuShape {
  static const Radius xsRadius = Radius.circular(6);
  static const Radius smRadius = Radius.circular(10);
  static const Radius mdRadius = Radius.circular(14);
  static const Radius lgRadius = Radius.circular(20);
  static const Radius xlRadius = Radius.circular(28);

  static const BorderRadius xs = BorderRadius.all(xsRadius);
  static const BorderRadius sm = BorderRadius.all(smRadius);
  static const BorderRadius md = BorderRadius.all(mdRadius);
  static const BorderRadius lg = BorderRadius.all(lgRadius);
  static const BorderRadius xl = BorderRadius.all(xlRadius);

  /// Fully rounded — pills, chips, floating action buttons.
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));

  /// Artwork thumbnails in lists and grids.
  static const BorderRadius artwork = sm;

  /// The full-screen player's artwork.
  static const BorderRadius heroArtwork = md;

  /// Top corners only — bottom sheets, the draggable player.
  static const BorderRadius sheetTop = BorderRadius.only(
    topLeft: lgRadius,
    topRight: lgRadius,
  );

  static const RoundedRectangleBorder cardBorder = RoundedRectangleBorder(
    borderRadius: md,
    side: BorderSide(color: Color(0xFF121218), width: 2.5),
  );

  static const RoundedRectangleBorder sheetBorder = RoundedRectangleBorder(
    borderRadius: sheetTop,
    side: BorderSide(color: Color(0xFF121218), width: 2.5),
  );

  static const RoundedSuperellipseBorder squircle = RoundedSuperellipseBorder(
    borderRadius: md,
    side: BorderSide(color: Color(0xFF121218), width: 2.5),
  );
}
