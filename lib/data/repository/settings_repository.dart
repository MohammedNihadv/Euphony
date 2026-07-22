import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How the app picks its colour scheme.
enum ColourSource {
  /// Derive the scheme from the current track's artwork. Euphony's default and
  /// its signature effect.
  artwork,

  /// Follow the Android system accent colour.
  system,

  /// Use the app's own fixed seed.
  fixed,
}

/// Typed access to user settings.
///
/// Harmony stored settings as untyped Hive map entries, which let two
/// misspelled keys (`restrorePlaybackSession`, `stopPlyabackOnSwipeAway`)
/// become load-bearing (developer guide 7.3). Here every setting is a getter
/// and a setter on this class; the string keys are private and appear once.
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _kThemeMode = 'theme_mode';
  static const _kAmoled = 'amoled_dark';
  static const _kColourSource = 'colour_source';

  ThemeMode get themeMode =>
      ThemeMode.values.asNameMap()[_prefs.getString(_kThemeMode)] ??
      ThemeMode.system;

  Future<void> setThemeMode(ThemeMode value) =>
      _prefs.setString(_kThemeMode, value.name);

  /// True black backgrounds in dark mode, for OLED panels.
  bool get amoled => _prefs.getBool(_kAmoled) ?? false;

  Future<void> setAmoled({required bool value}) =>
      _prefs.setBool(_kAmoled, value);

  ColourSource get colourSource =>
      ColourSource.values.asNameMap()[_prefs.getString(_kColourSource)] ??
      ColourSource.artwork;

  Future<void> setColourSource(ColourSource value) =>
      _prefs.setString(_kColourSource, value.name);
}
