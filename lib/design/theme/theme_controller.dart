import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/providers.dart';
import '../../data/repository/settings_repository.dart';
import 'artwork_palette.dart';

part 'theme_controller.g.dart';

/// The palette cache. Long-lived — re-deriving a scheme the user already saw
/// would flash the fallback colours on every repeat play.
@Riverpod(keepAlive: true)
ArtworkPalette artworkPalette(Ref ref) => ArtworkPalette();

/// Everything the app needs to build its [ThemeData].
@immutable
class ThemeState {
  const ThemeState({
    required this.mode,
    required this.amoled,
    required this.source,
    required this.scheme,
  });

  final ThemeMode mode;
  final bool amoled;
  final ColourSource source;

  /// The active light/dark pair. Tracks the playing song's artwork when
  /// [source] is [ColourSource.artwork].
  final ArtworkScheme scheme;

  ThemeState copyWith({
    ThemeMode? mode,
    bool? amoled,
    ColourSource? source,
    ArtworkScheme? scheme,
  }) => ThemeState(
    mode: mode ?? this.mode,
    amoled: amoled ?? this.amoled,
    source: source ?? this.source,
    scheme: scheme ?? this.scheme,
  );
}

@Riverpod(keepAlive: true)
class ThemeController extends _$ThemeController {
  @override
  ThemeState build() {
    final settings = ref.watch(settingsRepositoryProvider);
    return ThemeState(
      mode: settings.themeMode,
      amoled: settings.amoled,
      source: settings.colourSource,
      scheme: ArtworkScheme.fallback,
    );
  }

  SettingsRepository get _settings => ref.read(settingsRepositoryProvider);

  Future<void> setMode(ThemeMode mode) async {
    state = state.copyWith(mode: mode);
    unawaited(_settings.setThemeMode(mode));
  }

  Future<void> setAmoled({required bool value}) async {
    state = state.copyWith(amoled: value);
    unawaited(_settings.setAmoled(value: value));
  }

  Future<void> setColourSource(ColourSource source) async {
    // Leaving artwork mode drops back to the fixed seed immediately; entering
    // it keeps the current colours until the next track paints over them.
    state = ThemeState(
      mode: state.mode,
      amoled: state.amoled,
      source: source,
      scheme: source == ColourSource.artwork
          ? state.scheme
          : ArtworkScheme.fallback,
    );
    unawaited(_settings.setColourSource(source));
  }

  /// Repaints the app in the colours of [artwork], keyed by [key] (the song
  /// id). A no-op unless the user has artwork colouring enabled.
  Future<void> applyArtwork(String key, ImageProvider artwork) async {
    if (state.source != ColourSource.artwork) return;

    final palette = ref.read(artworkPaletteProvider);
    final cached = palette.peek(key);
    if (cached != null) {
      state = state.copyWith(scheme: cached);
      return;
    }

    state = state.copyWith(scheme: await palette.schemeFor(key, artwork));
  }

  /// Returns to the fallback palette — used when playback stops.
  void resetArtwork() {
    if (state.source != ColourSource.artwork) return;
    state = state.copyWith(scheme: ArtworkScheme.fallback);
  }
}
