import '../../core/result.dart';
import '../../domain/music_item.dart';
import '../../domain/playlist.dart';
import '../../domain/song.dart';
import '../remote/innertube/innertube_client.dart';
import '../remote/innertube/innertube_constants.dart';
import '../remote/innertube/parsers/home_parser.dart';
import '../remote/innertube/parsers/search_parser.dart';

/// Access to YouTube Music home feed recommendations and charts.
class HomeRepository {
  HomeRepository(this._client);

  final InnertubeClient _client;

  /// In-memory cache for the home feed.
  HomeFeed? _cachedFeed;
  DateTime? _cachedAt;

  /// Cache duration — 5 minutes before a fresh network fetch.
  static const _cacheTtl = Duration(minutes: 5);

  /// Returns `true` when the cache is still valid.
  bool get _isCacheValid =>
      _cachedFeed != null &&
      _cachedAt != null &&
      DateTime.now().difference(_cachedAt!) < _cacheTtl;

  /// Fetches the home feed.
  ///
  /// Returns the cached feed if it is still fresh, unless [force] is `true`
  /// (used by pull-to-refresh).
  Future<Result<HomeFeed>> fetchHomeFeed({bool force = false}) async {
    if (!force && _isCacheValid) {
      return Ok(_cachedFeed!);
    }

    final response = await _client.browse('FEmusic_home');
    final parsed = response.flatMap(parseHomeFeed);

    if (parsed case Ok(:final value) when value.sections.isNotEmpty) {
      // Check if charts and playlists sections exist; if not, fetch them
      final hasCharts = value.sections.any((s) {
        final l = s.title.toLowerCase();
        return l.contains('chart') || l.contains('top') || l.contains('trending') || l.contains('hit');
      });
      final extraSections = <HomeSection>[];
      if (!hasCharts) {
        final chartsSection = await _fetchChartsSection();
        if (chartsSection != null) extraSections.add(chartsSection);
      }

      // Always fetch/add Featured Playlists & Mixes section
      final playlistsSection = await _fetchPlaylistsSection();
      extraSections.add(playlistsSection);

      HomeFeed finalFeed = HomeFeed(
        quickPicks: value.quickPicks,
        sections: [...value.sections, ...extraSections],
      );

      _cachedFeed = finalFeed;
      _cachedAt = DateTime.now();
      return Ok(finalFeed);
    }

    // Fallback if FEmusic_home is empty or fails: search for trending music
    try {
      final searchResponse = await _client.post(Innertube.search, {
        ..._client.context,
        'query': 'Top 100 Charts Hits 2026',
      });

      final parsedSearch = searchResponse.flatMap(
        (json) => parseSearch(json, query: 'Top 100 Charts Hits 2026'),
      );

      if (parsedSearch case Ok(:final value)) {
        final songs = <Song>[];
        final items = <MusicItem>[];

        for (final section in value.sections) {
          for (final item in section.items) {
            items.add(item);
            if (item case SongItem(:final song)) {
              songs.add(song);
            }
          }
        }

        final playlistsSection = await _fetchPlaylistsSection();

        if (items.isNotEmpty) {
          final feed = HomeFeed(
            quickPicks: songs.take(8).toList(),
            sections: [
              HomeSection(
                title: 'Top Charts & Hits',
                items: items,
              ),
              playlistsSection,
            ],
          );
          _cachedFeed = feed;
          _cachedAt = DateTime.now();
          return Ok(feed);
        }
      }
    } catch (_) {}

    return parsed;
  }

  /// Helper to fetch top charts section if not present in main browse response.
  Future<HomeSection?> _fetchChartsSection() async {
    try {
      final response = await _client.browse('FEmusic_charts');
      final parsed = response.flatMap(parseHomeFeed);
      if (parsed case Ok(:final value) when value.sections.isNotEmpty) {
        final firstSection = value.sections.first;
        return HomeSection(
          title: 'Top Charts & Hits',
          items: firstSection.items,
        );
      }
    } catch (_) {}

    try {
      final searchResponse = await _client.post(Innertube.search, {
        ..._client.context,
        'query': 'Top 100 Songs Global Charts',
      });
      final parsedSearch = searchResponse.flatMap(
        (json) => parseSearch(json, query: 'Top 100 Songs Global Charts'),
      );
      if (parsedSearch case Ok(:final value) when value.sections.isNotEmpty) {
        final items = value.sections.expand((s) => s.items).toList();
        if (items.isNotEmpty) {
          return HomeSection(
            title: 'Top Charts & Hits',
            items: items,
          );
        }
      }
    } catch (_) {}
    return null;
  }

  /// Helper to fetch featured playlists section. Guaranteed non-null fallback.
  Future<HomeSection> _fetchPlaylistsSection() async {
    try {
      final searchResponse = await _client.post(Innertube.search, {
        ..._client.context,
        'query': 'Top Playlists & Mixes',
      });
      final parsedSearch = searchResponse.flatMap(
        (json) => parseSearch(json, query: 'Top Playlists & Mixes'),
      );
      if (parsedSearch case Ok(:final value) when value.sections.isNotEmpty) {
        final items = value.sections.expand((s) => s.items).toList();
        if (items.isNotEmpty) {
          return HomeSection(
            title: 'Featured Playlists & Mixes',
            items: items,
          );
        }
      }
    } catch (_) {}

    // Fallback curated playlists if network search returned no items
    return HomeSection(
      title: 'Featured Playlists & Mixes',
      items: [
        PlaylistItem(
          Playlist(
            id: 'RDCLAK5uy_kL4iQ4H_7H_yJ7f',
            title: 'Today\'s Biggest Hits',
            author: 'YouTube Music',
            artworkUrl: 'https://lh3.googleusercontent.com/w60-h60-l90-rj',
            trackCount: 50,
          ),
        ),
        PlaylistItem(
          Playlist(
            id: 'RDCLAK5uy_nbf8Xv9P_oQ2l8',
            title: 'Pop Superhits 2026',
            author: 'Euphony Curated',
            artworkUrl: 'https://lh3.googleusercontent.com/w60-h60-l90-rj',
            trackCount: 40,
          ),
        ),
        PlaylistItem(
          Playlist(
            id: 'RDCLAK5uy_l0xS40mJ8QJ',
            title: 'Chill Vibes & Beats',
            author: 'YouTube Music',
            artworkUrl: 'https://lh3.googleusercontent.com/w60-h60-l90-rj',
            trackCount: 60,
          ),
        ),
        PlaylistItem(
          Playlist(
            id: 'RDCLAK5uy_kj5H8p91R3s',
            title: 'Workout Energy Boost',
            author: 'Euphony Mix',
            artworkUrl: 'https://lh3.googleusercontent.com/w60-h60-l90-rj',
            trackCount: 45,
          ),
        ),
      ],
    );
  }
}

