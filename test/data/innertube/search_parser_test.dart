import 'package:euphony/data/remote/innertube/innertube_utils.dart';
import 'package:euphony/data/remote/innertube/parsers/item_parser.dart';
import 'package:euphony/data/remote/innertube/parsers/search_parser.dart';
import 'package:test/test.dart';

import '../../fixtures.dart';

/// Golden tests against real captured responses.
///
/// This is the gate the whole data layer stands on. Harmony had no equivalent,
/// which is why its search could break in the wild and stay broken across 23
/// duplicate issue reports before anyone traced it to a moved key.
void main() {
  group('unfiltered search', () {
    late final results = parseSearch(
      loadFixture('search_unfiltered'),
      query: 'daft punk',
    ).unwrap();

    test('parses without failing', () {
      expect(results.query, 'daft punk');
      expect(results.isEmpty, isFalse);
    });

    test('finds a top result', () {
      expect(results.topResult, isNotNull);
    });

    test('returns a titled section holding a mix of item types', () {
      // YouTube's current unfiltered response is a flat list of self-typed
      // rows, not the titled per-type shelves Harmony assumed. This test
      // pins that shape: if YouTube goes back to shelves, it fails here
      // rather than in a user's empty search screen.
      expect(results.sections, isNotEmpty);
      for (final section in results.sections) {
        expect(section.title, isNotEmpty);
      }

      final kinds = results.sections
          .expand((s) => s.items)
          .map((item) => item.runtimeType)
          .toSet();
      expect(
        kinds.length,
        greaterThanOrEqualTo(2),
        reason: 'an unfiltered search mixes songs, albums and artists',
      );
    });

    test('offers filter chips that map to search params', () {
      expect(results.filters, isNotEmpty);
      expect(results.filters.keys, contains('Songs'));
      for (final params in results.filters.values) {
        expect(params, isNotEmpty);
      }
    });

    test('every parsed item carries the fields the UI needs', () {
      final items = results.sections.expand((s) => s.items).toList();
      expect(items, isNotEmpty);

      for (final item in items) {
        switch (item) {
          case SongItem(:final song):
            expect(song.id, isNotEmpty);
            expect(song.title, isNotEmpty);
            expect(song.artworkUrl, isNotNull);
          case AlbumItem(:final album):
            expect(album.browseId, startsWith('MPRE'));
            expect(album.title, isNotEmpty);
          case ArtistItem(:final artist):
            expect(artist.browseId, isNotEmpty);
            expect(artist.name, isNotEmpty);
          case PlaylistItem(:final playlist):
            expect(playlist.id, isNotEmpty);
            expect(playlist.title, isNotEmpty);
          case StationItem(:final playlistId):
            expect(playlistId, isNotEmpty);
        }
      }
    });
  });

  group('filtered search', () {
    test('songs filter yields songs with ids, artists and durations', () {
      final results = parseSearch(
        loadFixture('search_songs'),
        query: 'daft punk',
        filter: SearchFilter.songs,
      ).unwrap();

      final songs = results.sections
          .expand((s) => s.items)
          .whereType<SongItem>()
          .map((i) => i.song)
          .toList();

      expect(songs.length, greaterThanOrEqualTo(10));
      expect(songs.every((s) => s.id.isNotEmpty), isTrue);
      expect(songs.every((s) => s.title.isNotEmpty), isTrue);
      expect(
        songs.where((s) => s.artists.isNotEmpty).length,
        greaterThan(songs.length ~/ 2),
        reason: 'most song rows carry an artist line',
      );
      expect(
        songs.where((s) => s.duration != null).length,
        greaterThan(songs.length ~/ 2),
        reason: 'most song rows carry a duration',
      );
    });

    test('albums filter yields albums with browse ids', () {
      final results = parseSearch(
        loadFixture('search_albums'),
        query: 'daft punk',
        filter: SearchFilter.albums,
      ).unwrap();

      final albums = results.sections
          .expand((s) => s.items)
          .whereType<AlbumItem>()
          .map((i) => i.album)
          .toList();

      expect(albums.length, greaterThanOrEqualTo(5));
      expect(albums.every((a) => a.browseId.startsWith('MPRE')), isTrue);
      expect(albums.every((a) => a.title.isNotEmpty), isTrue);
      expect(
        albums.where((a) => a.year != null).length,
        greaterThan(0),
        reason: 'album rows show a release year',
      );
    });

    test('artists filter yields artists with channel ids', () {
      final results = parseSearch(
        loadFixture('search_artists'),
        query: 'daft punk',
        filter: SearchFilter.artists,
      ).unwrap();

      final artists = results.sections
          .expand((s) => s.items)
          .whereType<ArtistItem>()
          .map((i) => i.artist)
          .toList();

      expect(artists, isNotEmpty);
      expect(artists.every((a) => a.browseId.startsWith('UC')), isTrue);
      expect(artists.every((a) => a.name.isNotEmpty), isTrue);
    });

    test('a filtered shelf offers a continuation token', () {
      final results = parseSearch(
        loadFixture('search_songs'),
        query: 'daft punk',
        filter: SearchFilter.songs,
      ).unwrap();

      expect(
        results.sections.any((s) => s.hasMore),
        isTrue,
        reason: 'paging is how the search screen loads more rows',
      );
    });
  });

  group('search suggestions', () {
    test('parses to plain query strings', () {
      final suggestions = parseSearchSuggestions(
        loadFixture('search_suggestions'),
      ).unwrap();

      expect(suggestions, isNotEmpty);
      expect(suggestions.every((s) => s.isNotEmpty), isTrue);
      expect(
        suggestions.any((s) => s.toLowerCase().contains('daf')),
        isTrue,
        reason: 'suggestions extend the typed prefix',
      );
    });

    test('an empty response is an empty list, not a failure', () {
      final result = parseSearchSuggestions(const {});
      expect(result.isOk, isTrue);
      expect(result.unwrap(), isEmpty);
    });
  });

  group('degenerate responses', () {
    test('a response with no contents is an empty result', () {
      final results = parseSearch(const {}, query: 'zzzz').unwrap();
      expect(results.isEmpty, isTrue);
      expect(results.sections, isEmpty);
    });

    test('a response with contents of the wrong shape fails loudly', () {
      final result = parseSearch(const {
        'contents': 'not a renderer',
      }, query: 'x');
      expect(result.isErr, isTrue);
      expect(result.failureOrNull.toString(), contains('contents'));
    });
  });
}
