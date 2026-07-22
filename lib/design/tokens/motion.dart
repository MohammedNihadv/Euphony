import 'package:flutter/material.dart';

/// Durations, curves and spring descriptions.
///
/// Motion is spring-led rather than duration-led: sheets, the player expand,
/// and selection transitions all use [EuMotion.spatial] so overlapping
/// gestures interrupt cleanly instead of snapping.
abstract final class EuMotion {
  // Durations — used for colour/opacity changes, where springs are overkill.
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration quick = Duration(milliseconds: 200);
  static const Duration standard = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 500);

  /// Cross-fade for the artwork-derived theme. Long on purpose — the colour
  /// shift should feel like a wash, not a flash.
  static const Duration themeShift = Duration(milliseconds: 650);

  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve emphasizedIn = Curves.easeInCubic;
  static const Curve standardCurve = Curves.easeInOut;

  /// Springs for anything that moves in space (sheets, cards, the player).
  static const SpringDescription spatial = SpringDescription(
    mass: 1,
    stiffness: 380,
    damping: 32,
  );

  /// Softer spring for large surfaces — the full player sheet.
  static const SpringDescription spatialSlow = SpringDescription(
    mass: 1,
    stiffness: 220,
    damping: 30,
  );

  /// Snappier spring for small controls — chips, toggles, icon buttons.
  static const SpringDescription effects = SpringDescription(
    mass: 0.8,
    stiffness: 560,
    damping: 34,
  );

  /// Animation style for modal sheets and menus.
  static const AnimationStyle sheet = AnimationStyle(
    duration: standard,
    curve: emphasized,
    reverseDuration: quick,
    reverseCurve: emphasizedIn,
  );
}
