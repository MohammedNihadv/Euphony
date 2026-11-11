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
/// Every setting is a getter and a setter on this class; the string keys are
/// private and appear once.
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

  ColourSource get colourSource {
    final raw = _prefs.getString(_kColourSource);
    if (raw == null || raw == 'artwork') return ColourSource.fixed;
    return ColourSource.values.asNameMap()[raw] ?? ColourSource.fixed;
  }

  Future<void> setColourSource(ColourSource value) =>
      _prefs.setString(_kColourSource, value.name);

  static const _kAudioQuality = 'audio_quality';
  static const _kAutoPlaySimilar = 'auto_play_similar';
  static const _kSkipSilence = 'skip_silence';
  static const _kContentRegion = 'content_region';
  static const _kDynamicIsland = 'dynamic_island_enabled';

  String get audioQuality => _prefs.getString(_kAudioQuality) ?? 'HIGH';
  Future<void> setAudioQuality(String value) =>
      _prefs.setString(_kAudioQuality, value);

  bool get autoPlaySimilar => _prefs.getBool(_kAutoPlaySimilar) ?? true;
  Future<void> setAutoPlaySimilar(bool value) =>
      _prefs.setBool(_kAutoPlaySimilar, value);

  bool get skipSilence => _prefs.getBool(_kSkipSilence) ?? false;
  Future<void> setSkipSilence(bool value) =>
      _prefs.setBool(_kSkipSilence, value);

  String get contentRegion =>
      _prefs.getString(_kContentRegion) ?? 'US - United States';
  Future<void> setContentRegion(String value) =>
      _prefs.setString(_kContentRegion, value);

  bool get dynamicIsland => _prefs.getBool(_kDynamicIsland) ?? false;
  Future<void> setDynamicIsland(bool value) =>
      _prefs.setBool(_kDynamicIsland, value);

  static const _kHideMiniPlayerWithIsland = 'hide_mini_player_with_island';
  bool get hideMiniPlayerWithIsland =>
      _prefs.getBool(_kHideMiniPlayerWithIsland) ?? false;
  Future<void> setHideMiniPlayerWithIsland(bool value) =>
      _prefs.setBool(_kHideMiniPlayerWithIsland, value);

  static const _kDiscordRpc = 'discord_rpc_enabled';
  bool get discordRpcEnabled => _prefs.getBool(_kDiscordRpc) ?? true;
  Future<void> setDiscordRpcEnabled(bool value) =>
      _prefs.setBool(_kDiscordRpc, value);

  static const _kCrossfadeSeconds = 'crossfade_seconds';
  int get crossfadeSeconds => _prefs.getInt(_kCrossfadeSeconds) ?? 0;
  Future<void> setCrossfadeSeconds(int value) =>
      _prefs.setInt(_kCrossfadeSeconds, value);

  static const _kSleepFadeOut = 'sleep_fade_out';
  bool get sleepFadeOut => _prefs.getBool(_kSleepFadeOut) ?? true;
  Future<void> setSleepFadeOut(bool value) =>
      _prefs.setBool(_kSleepFadeOut, value);

  static const _kAudioSpeed = 'audio_speed';
  double get audioSpeed => _prefs.getDouble(_kAudioSpeed) ?? 1.0;
  Future<void> setAudioSpeed(double value) =>
      _prefs.setDouble(_kAudioSpeed, value);

  static const _kAudioPitch = 'audio_pitch';
  double get audioPitch => _prefs.getDouble(_kAudioPitch) ?? 1.0;
  Future<void> setAudioPitch(double value) =>
      _prefs.setDouble(_kAudioPitch, value);

  static const _kAudioDspPreset = 'audio_dsp_preset';
  String get audioDspPreset =>
      _prefs.getString(_kAudioDspPreset) ?? 'normal';
  Future<void> setAudioDspPreset(String value) =>
      _prefs.setString(_kAudioDspPreset, value);

  static const _kCloseToTray = 'close_to_tray';
  bool get closeToTray => _prefs.getBool(_kCloseToTray) ?? false;
  Future<void> setCloseToTray(bool value) =>
      _prefs.setBool(_kCloseToTray, value);
}
