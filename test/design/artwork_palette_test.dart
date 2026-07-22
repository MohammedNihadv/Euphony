import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:euphony/design/theme/artwork_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ImageProvider> _solidImage(Color colour) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(
    recorder,
  ).drawRect(const ui.Rect.fromLTWH(0, 0, 32, 32), ui.Paint()..color = colour);
  final image = await recorder.endRecording().toImage(32, 32);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return MemoryImage(Uint8List.view(bytes!.buffer));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('derives a light and dark scheme from artwork', () async {
    final palette = ArtworkPalette();
    final scheme = await palette.schemeFor(
      'song-1',
      await _solidImage(const Color(0xFF2A6FA8)),
    );

    expect(scheme.light.brightness, Brightness.light);
    expect(scheme.dark.brightness, Brightness.dark);
    expect(scheme.of(Brightness.dark), same(scheme.dark));
  });

  test('caches by key so a repeat play does not re-extract', () async {
    final palette = ArtworkPalette();
    final image = await _solidImage(const Color(0xFFE2574C));

    expect(palette.peek('song-1'), isNull);
    final first = await palette.schemeFor('song-1', image);
    expect(palette.peek('song-1'), same(first));
    expect(await palette.schemeFor('song-1', image), same(first));
  });

  test('evicts the least recently used entry past maxEntries', () async {
    final palette = ArtworkPalette(maxEntries: 2);
    final image = await _solidImage(const Color(0xFF3F8F5B));

    await palette.schemeFor('a', image);
    await palette.schemeFor('b', image);
    // Touch 'a' so 'b' becomes the oldest.
    await palette.schemeFor('a', image);
    await palette.schemeFor('c', image);

    expect(palette.peek('b'), isNull);
    expect(palette.peek('a'), isNotNull);
    expect(palette.peek('c'), isNotNull);
  });

  test(
    'falls back instead of throwing when the image cannot be decoded',
    () async {
      final palette = ArtworkPalette();
      final scheme = await palette.schemeFor(
        'broken',
        MemoryImage(Uint8List.fromList([0, 1, 2, 3])),
      );

      expect(scheme, same(ArtworkScheme.fallback));
      expect(palette.peek('broken'), isNull, reason: 'do not cache a failure');
    },
  );
}
