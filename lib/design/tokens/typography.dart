import 'package:flutter/material.dart';

/// Type scale.
///
/// Material's `displayLarge` / `bodySmall` names say nothing about intent, so
/// feature code uses the semantic names in [EuTextStyles] instead. The raw
/// scale below exists only to build the [TextTheme] those names read from.
abstract final class EuType {
  /// Tighter tracking than Material's default at large sizes — the expressive
  /// look wants headlines to feel set, not spaced out.
  static TextTheme build(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 52,
        height: 1.08,
        letterSpacing: -1.2,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 40,
        height: 1.12,
        letterSpacing: -0.8,
        fontWeight: FontWeight.w700,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 32,
        height: 1.15,
        letterSpacing: -0.5,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 28,
        height: 1.2,
        letterSpacing: -0.4,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 24,
        height: 1.22,
        letterSpacing: -0.3,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 20,
        height: 1.25,
        letterSpacing: -0.2,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 18,
        height: 1.3,
        letterSpacing: -0.1,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.bodyLarge?.copyWith(fontSize: 16, height: 1.45),
      bodyMedium: base.bodyMedium?.copyWith(fontSize: 14, height: 1.45),
      bodySmall: base.bodySmall?.copyWith(fontSize: 12, height: 1.4),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        letterSpacing: 0.1,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        letterSpacing: 0.3,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        letterSpacing: 0.4,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Semantic type names.
///
/// `context.text.songTitle` reads as intent; `titleMedium` does not. Add a name
/// here rather than reaching for a Material slot in a widget.
extension EuTextStyles on TextTheme {
  /// The track name on the full-screen player.
  TextStyle? get playerTitle => headlineMedium;

  /// The artist line under [playerTitle].
  TextStyle? get playerSubtitle => titleMedium;

  /// A screen's top-level heading.
  TextStyle? get screenTitle => headlineLarge;

  /// A section heading inside a screen ("Quick picks", "Listen again").
  TextStyle? get sectionTitle => titleLarge;

  /// The primary line of a song / album / artist row.
  TextStyle? get itemTitle => titleSmall;

  /// The secondary line of that row.
  TextStyle? get itemSubtitle => bodySmall;

  /// Duration, play counts, byte sizes — dimmed metadata.
  TextStyle? get meta => labelMedium;

  /// Text inside buttons and chips.
  TextStyle? get action => labelLarge;

  /// A synced lyric line, sized to be readable across a room.
  TextStyle? get lyricLine => headlineSmall;
}
