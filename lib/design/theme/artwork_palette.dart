import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/log.dart';
import 'eu_theme.dart';

final _log = logFor('artwork_palette');

/// A light/dark [ColorScheme] pair derived from one piece of artwork.
@immutable
class ArtworkScheme {
  const ArtworkScheme({required this.light, required this.dark});

  /// The scheme used before any artwork has been sampled.
  static final ArtworkScheme fallback = ArtworkScheme(
    light: ColorScheme.fromSeed(seedColor: euFallbackSeed),
    dark: ColorScheme.fromSeed(
      seedColor: euFallbackSeed,
      brightness: Brightness.dark,
    ),
  );

  final ColorScheme light;
  final ColorScheme dark;

  ColorScheme of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// Derives [ColorScheme]s from album artwork, with an LRU cache keyed by song.
///
/// This replaces Harmony's `PaletteGenerator` + hand-built `MaterialColor`
/// swatch + luminance clamping (developer guide 11.7) with the framework's own
/// `ColorScheme.fromImageProvider`, which runs the same quantiser Material 3
/// specifies and returns a scheme that is contrast-correct by construction.
///
/// Extraction is expensive, so artwork is downsampled to [_sampleSize] first —
/// the same trick Harmony used with `cacheHeight: 200`.
class ArtworkPalette {
  ArtworkPalette({this.maxEntries = 60});

  static const int _sampleSize = 200;

  /// How many schemes to keep before evicting the least recently used.
  final int maxEntries;
  final LinkedHashMap<String, ArtworkScheme> _cache =
      LinkedHashMap<String, ArtworkScheme>();
  final Map<String, Future<ArtworkScheme>> _inFlight = {};

  /// The cached scheme for [key], or `null` if it has not been derived yet.
  ///
  /// Lets a caller paint the correct colours on the first frame when the song
  /// has been played before, instead of flashing the fallback.
  ArtworkScheme? peek(String key) => _cache[key];

  /// Derives (or returns the cached) scheme for [image], keyed by [key].
  ///
  /// [key] is normally the song id. Concurrent calls for the same key share one
  /// extraction. Failures fall back to [ArtworkScheme.fallback] rather than
  /// throwing — a missing thumbnail must never break playback.
  Future<ArtworkScheme> schemeFor(String key, ImageProvider image) {
    final cached = _cache[key];
    if (cached != null) {
      // Refresh recency.
      _cache
        ..remove(key)
        ..[key] = cached;
      return SynchronousFuture(cached);
    }

    return _inFlight.putIfAbsent(key, () async {
      try {
        final sized = ResizeImage(
          image,
          width: _sampleSize,
          height: _sampleSize,
          allowUpscaling: false,
        );
        final results = await Future.wait([
          ColorScheme.fromImageProvider(provider: sized),
          ColorScheme.fromImageProvider(
            provider: sized,
            brightness: Brightness.dark,
          ),
        ]);
        final scheme = ArtworkScheme(light: results[0], dark: results[1]);
        _store(key, scheme);
        return scheme;
      } catch (error, stack) {
        _log.warning('palette extraction failed for $key', error, stack);
        return ArtworkScheme.fallback;
      } finally {
        // The removed value is the future we are already inside.
        final _ = _inFlight.remove(key);
      }
    });
  }

  void _store(String key, ArtworkScheme scheme) {
    _cache[key] = scheme;
    while (_cache.length > maxEntries) {
      _cache.remove(_cache.keys.first);
    }
  }

  void clear() => _cache.clear();
}
