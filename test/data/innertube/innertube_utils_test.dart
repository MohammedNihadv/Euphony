import 'package:euphony/core/util/thumbnail_url.dart';
import 'package:euphony/data/remote/innertube/innertube_utils.dart';
import 'package:test/test.dart';

void main() {
  group('parseDuration', () {
    test('parses minutes and seconds', () {
      expect(parseDuration('3:45'), const Duration(minutes: 3, seconds: 45));
    });

    test('parses hours', () {
      expect(
        parseDuration('1:02:03'),
        const Duration(hours: 1, minutes: 2, seconds: 3),
      );
    });

    test('returns null for text that is not a duration', () {
      expect(parseDuration('1.2M views'), isNull);
      expect(parseDuration('Daft Punk'), isNull);
      expect(parseDuration(''), isNull);
      expect(parseDuration(null), isNull);
    });

    test('returns null rather than throwing on absurd input', () {
      expect(parseDuration('1:2:3:4'), isNull);
      expect(parseDuration('-1:30'), isNull);
    });
  });

  group('normalisePlaylistId', () {
    test('strips the VL prefix', () {
      expect(normalisePlaylistId('VLPL123'), 'PL123');
    });

    test('leaves an already-normal id alone', () {
      expect(normalisePlaylistId('PL123'), 'PL123');
    });
  });

  group('isExpired', () {
    DateTime at(int epochSeconds) =>
        DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);

    test('reads the expiry out of a stream URL', () {
      const url = 'https://example.com/v?expire=2000000&other=1';
      expect(isExpired(url: url, clock: () => at(1000000)), isFalse);
      expect(isExpired(url: url, clock: () => at(1999000)), isTrue);
    });

    test('treats an expiry inside 30 minutes as already expired', () {
      // A track queued now must still play when it starts.
      expect(isExpired(epoch: 2000000, clock: () => at(1998300)), isTrue);
      expect(isExpired(epoch: 2000000, clock: () => at(1998100)), isFalse);
    });

    test('a URL with no expiry parameter counts as expired', () {
      expect(isExpired(url: 'https://example.com/v'), isTrue);
    });

    test('no input at all counts as expired', () {
      expect(isExpired(), isTrue);
    });
  });

  group('searchParams', () {
    test('is null for an unfiltered search', () {
      expect(searchParams(), isNull);
    });

    test('gives a distinct value per filter', () {
      final values = {
        for (final filter in SearchFilter.values)
          filter: searchParams(filter: filter),
      };
      expect(values.values.every((v) => v != null && v.isNotEmpty), isTrue);
      expect(
        values.values.toSet().length,
        SearchFilter.values.length,
        reason: 'each filter scopes the search differently',
      );
    });

    test('ignoreSpelling changes the value', () {
      expect(
        searchParams(filter: SearchFilter.songs),
        isNot(searchParams(filter: SearchFilter.songs, ignoreSpelling: true)),
      );
    });
  });

  group('flex and fixed columns', () {
    const row = <String, dynamic>{
      'flexColumns': [
        {
          'musicResponsiveListItemFlexColumnRenderer': {
            'text': {
              'runs': [
                {'text': 'Around the World'},
              ],
            },
          },
        },
        {
          'musicResponsiveListItemFlexColumnRenderer': {
            'text': {
              'runs': [
                {'text': 'Daft Punk'},
                {'text': ' • '},
                {'text': 'Homework'},
              ],
            },
          },
        },
      ],
      'fixedColumns': [
        {
          'musicResponsiveListItemFixedColumnRenderer': {
            'text': {
              'runs': [
                {'text': '7:09'},
              ],
            },
          },
        },
      ],
    };

    test('reads a flex column title', () {
      expect(flexColumnText(row, 0), 'Around the World');
    });

    test('reads a specific run of a flex column', () {
      expect(flexColumnText(row, 1, runIndex: 2), 'Homework');
    });

    test('returns null for a column that is not there', () {
      expect(flexColumnText(row, 5), isNull);
    });

    test('reads the whole run list', () {
      expect(flexColumnRuns(row, 1), hasLength(3));
    });

    test('reads the duration out of a fixed column', () {
      expect(fixedColumnText(row, 0), '7:09');
      expect(
        parseDuration(fixedColumnText(row, 0)),
        const Duration(minutes: 7, seconds: 9),
      );
    });

    test('finds the dot separator', () {
      expect(dotSeparatorIndex(flexColumnRuns(row, 1)!), 1);
      expect(dotSeparatorIndex(flexColumnRuns(row, 0)!), -1);
    });
  });

  group('ThumbnailUrl', () {
    test('rewrites the width/height form', () {
      const url = ThumbnailUrl(
        'https://lh3.googleusercontent.com/abc=w60-h60-l90-rj',
      );
      expect(url.sized(400), endsWith('=w400-h400-l90-rj'));
    });

    test('rewrites the square shorthand', () {
      const url = ThumbnailUrl('https://lh3.googleusercontent.com/abc=s60');
      expect(url.sized(250), endsWith('=s250'));
    });

    test('upgrades a video still only when a large size is asked for', () {
      const url = ThumbnailUrl('https://i.ytimg.com/vi/abc/sddefault.jpg');
      expect(url.low, contains('sddefault'));
      expect(url.max, contains('maxresdefault'));
    });

    test('leaves an unrecognised URL untouched', () {
      const url = ThumbnailUrl('https://example.com/art.png');
      expect(url.high, 'https://example.com/art.png');
    });
  });
}
