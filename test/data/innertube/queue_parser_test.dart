import 'package:euphony/data/remote/innertube/parsers/queue_parser.dart';
import 'package:test/test.dart';

import '../../fixtures.dart';

/// Golden test for the autoplay radio parser. This is what gives confidence
/// that playback keeps going with related tracks once a queue ends, without
/// waiting for a real song to finish.
void main() {
  group('parseWatchQueue', () {
    test('extracts the related-track queue from a next response', () {
      final songs = parseWatchQueue(loadFixture('radio'));

      expect(songs.length, greaterThanOrEqualTo(10));
      expect(songs.every((s) => s.id.isNotEmpty), isTrue);
      expect(songs.every((s) => s.title.isNotEmpty), isTrue);
      // Most radio tracks carry an artist line.
      expect(
        songs.where((s) => s.artists.isNotEmpty).length,
        greaterThan(songs.length ~/ 2),
      );
    });

    test('an unrelated response yields an empty queue, not an error', () {
      expect(parseWatchQueue(const {}), isEmpty);
    });
  });
}
