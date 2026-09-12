import '../../core/result.dart';
import '../../domain/music_item.dart';
import '../../domain/song.dart';
import '../remote/innertube/innertube_client.dart';
import '../remote/innertube/innertube_constants.dart';
import '../remote/innertube/innertube_utils.dart';
import '../remote/innertube/parsers/home_parser.dart';
import '../remote/innertube/parsers/search_parser.dart';

/// Access to YouTube Music home feed recommendations, regional curation, and charts.
class HomeRepository {
  HomeRepository(this._client);

  final InnertubeClient _client;

  /// In-memory cache for the home feed.
  HomeFeed? _cachedFeed;
  DateTime? _cachedAt;
  String? _cachedRegion;

  /// Cache duration — 5 minutes before a fresh network fetch.
  static const _cacheTtl = Duration(minutes: 5);

  /// Returns true when the cache is still valid for the active region.
  bool get _isCacheValid =>
      _cachedFeed != null &&
      _cachedAt != null &&
      _cachedRegion == _client.region &&
      DateTime.now().difference(_cachedAt!) < _cacheTtl;

  /// Fetches the home feed, combining FEmusic_home, FEmusic_new_releases,
  /// and region-curated shelves (e.g. Mollywood, Kollywood, Tollywood, Bollywood, Hollywood, Pakistani).
  Future<Result<HomeFeed>> fetchHomeFeed({bool force = false}) async {
    if (!force && _isCacheValid) {
      return Ok(_cachedFeed!);
    }

    final currentRegion = _client.region;

    // Fetch home, new releases, regional sections, and regional quick picks in parallel.
    final futures = await Future.wait([
      _client.browse('FEmusic_home'),
      _client.browse('FEmusic_new_releases'),
      _fetchRegionalSections(currentRegion),
      _fetchRegionalQuickPicks(currentRegion),
    ]);

    final homeResult = (futures[0] as Result<Map<String, dynamic>>).flatMap(parseHomeFeed);
    final releasesResult = (futures[1] as Result<Map<String, dynamic>>).flatMap(parseHomeFeed);
    final regionalSections = futures[2] as List<HomeSection>;
    final regionalQuickPicks = futures[3] as List<Song>;

    List<HomeSection> homeSections = const [];
    List<HomeSection> releasesSections = const [];
    List<Song> homeQuickPicks = const [];
    List<Song> releasesQuickPicks = const [];

    if (homeResult case Ok(:final value)) {
      homeSections = value.sections;
      homeQuickPicks = value.quickPicks;
    }
    if (releasesResult case Ok(:final value)) {
      releasesSections = value.sections;
      releasesQuickPicks = value.quickPicks;
    }

    // Curated regional shelves are the primary feed content (preventing IP-located other-country content):
    final allSections = <HomeSection>[
      if (regionalSections.isNotEmpty)
        ...regionalSections
      else ...[
        ...releasesSections,
        ...homeSections,
      ],
    ];

    // Deduplicate sections by title (case-insensitive).
    final seen = <String>{};
    final dedupedSections = <HomeSection>[];
    for (final s in allSections) {
      final key = s.title.toLowerCase();
      if (seen.add(key)) dedupedSections.add(s);
    }

    // Combine quick picks: regional first (so user gets their chosen country's hits), fallback to releases.
    final allQuickPicks = [
      if (regionalQuickPicks.isNotEmpty)
        ...regionalQuickPicks
      else ...[
        ...releasesQuickPicks,
        ...homeQuickPicks,
      ],
    ];
    final seenIds = <String>{};
    final quickPicks = allQuickPicks
        .where((s) => seenIds.add(s.id))
        .take(16)
        .toList();

    if (dedupedSections.isNotEmpty || quickPicks.isNotEmpty) {
      final feed = HomeFeed(
        quickPicks: quickPicks,
        sections: dedupedSections,
      );
      _cachedFeed = feed;
      _cachedAt = DateTime.now();
      _cachedRegion = currentRegion;
      return Ok(feed);
    }

    // Both browse endpoints failed — return the first error.
    if (homeResult case Err(:final failure)) {
      return Err(failure);
    }
    return releasesResult.map((_) => const HomeFeed());
  }

  /// Fetches curated regional sections based on country code.
  Future<List<HomeSection>> _fetchRegionalSections(String region) async {
    final topics = _getRegionalTopics(region);
    final results = await Future.wait(
      topics.map((t) async {
        try {
          final res = await _client.post(Innertube.search, {
            ..._client.context,
            'query': t.query,
            'params': searchParams(filter: SearchFilter.featuredPlaylists) ??
                searchParams(filter: SearchFilter.playlists),
          });
          final parsed = res.flatMap(
            (json) => parseSearch(
              json,
              query: t.query,
              filter: SearchFilter.featuredPlaylists,
            ),
          );
          if (parsed case Ok(:final value)) {
            final allItems = <MusicItem>[
              if (value.topResult != null) value.topResult!,
              for (final sec in value.sections) ...sec.items,
            ];
            if (allItems.isNotEmpty) {
              return HomeSection(title: t.title, items: allItems.take(12).toList());
            }
          }
        } catch (_) {}
        return null;
      }),
    );

    return results.whereType<HomeSection>().toList();
  }

  /// Defines regional curation queries for each country code.
  List<({String title, String query, String tag})> _getRegionalTopics(String region) {
    switch (region.toUpperCase()) {
      case 'IN':
        return const [
          (title: 'Mollywood Waves', query: 'Malayalam Hits Playlist', tag: 'Mollywood'),
          (title: 'Kollywood Fire', query: 'Tamil Hits Playlist', tag: 'Kollywood'),
          (title: 'Tollywood Mass', query: 'Telugu Hits Playlist', tag: 'Tollywood'),
          (title: 'Bollywood Hits', query: 'Bollywood Superhits Playlist', tag: 'Bollywood'),
          (title: 'Hollywood & Global', query: 'Top Hollywood Hits Playlist', tag: 'Hollywood'),
          (title: 'Pakistani & Coke Studio', query: 'Pakistani Coke Studio Playlist', tag: 'Pakistani'),
          (title: 'Indie India', query: 'Indie India Playlist', tag: 'Indie India'),
        ];
      case 'PK':
        return const [
          (title: 'Coke Studio & Sufi', query: 'Coke Studio Best Songs Playlist', tag: 'Coke Studio'),
          (title: 'Pakistani Pop & OST', query: 'Pakistani OSTs Drama Songs Playlist', tag: 'Pakistani Pop'),
          (title: 'Desi Hip Hop', query: 'Pakistani Hip Hop Rap Playlist', tag: 'Desi Hip Hop'),
          (title: 'Bollywood Hits', query: 'Bollywood Hits Playlist', tag: 'Bollywood'),
          (title: 'Hollywood & Global', query: 'Top Hollywood Hits Playlist', tag: 'Hollywood'),
        ];
      case 'US':
        return const [
          (title: 'Billboard Hot 100', query: 'Today Top Hits Billboard Playlist', tag: 'Billboard'),
          (title: 'Hip-Hop & R&B', query: 'Rap Caviar Hip Hop Playlist', tag: 'Hip-Hop'),
          (title: 'Pop Fresh', query: 'Pop Rising Hits Playlist', tag: 'Pop'),
          (title: 'Rock & Alternative', query: 'Modern Rock Alternative Playlist', tag: 'Rock'),
          (title: 'Country & Americana', query: 'Hot Country Playlist', tag: 'Country'),
          (title: 'Global Pop Drops', query: 'Global Hits Playlist', tag: 'Global'),
        ];
      case 'UK':
        return const [
          (title: 'Official UK Top 40', query: 'UK Top 40 Chart Playlist', tag: 'UK Charts'),
          (title: 'British Indie & Rock', query: 'UK Indie Rock Playlist', tag: 'Indie'),
          (title: 'UK Drill & Grime', query: 'UK Rap Drill Playlist', tag: 'UK Rap'),
          (title: 'Pop & Dance UK', query: 'UK Dance Pop Playlist', tag: 'Dance'),
        ];
      case 'CA':
        return const [
          (title: 'Billboard Canadian Hot 100', query: 'Canadian Hot 100 Playlist', tag: 'Canada'),
          (title: 'Pop Canada', query: 'Top Pop Canada Playlist', tag: 'Pop'),
          (title: 'Canada Indie & Alt', query: 'Canada Indie Rock Playlist', tag: 'Indie'),
          (title: 'Hip-Hop North', query: 'Canadian Hip Hop Playlist', tag: 'Hip-Hop'),
        ];
      case 'AU':
        return const [
          (title: 'ARIA Top 50 Singles', query: 'ARIA Top 50 Australia Playlist', tag: 'ARIA'),
          (title: 'Aussie Indie & Alt', query: 'Australian Indie Rock Playlist', tag: 'Indie'),
          (title: 'Triple J Hottest', query: 'Triple J Hottest Hits Playlist', tag: 'Triple J'),
          (title: 'Pop Australia', query: 'Top Pop Australia Playlist', tag: 'Pop'),
        ];
      case 'DE':
        return const [
          (title: 'Top Hits Deutschland', query: 'Top Hits Deutschland Playlist', tag: 'Deutschland'),
          (title: 'Deutschrap Fresh', query: 'Deutschrap Playlist', tag: 'Deutschrap'),
          (title: 'Pop & Dance DE', query: 'German Pop Dance Playlist', tag: 'Pop'),
        ];
      case 'FR':
        return const [
          (title: 'Top 50 France', query: 'Top 50 France Playlist', tag: 'France'),
          (title: 'Rap Français', query: 'Rap Français Playlist', tag: 'Rap FR'),
          (title: 'Variété Française', query: 'Variété Française Playlist', tag: 'Pop FR'),
        ];
      case 'BR':
        return const [
          (title: 'Top Brasil', query: 'Top Brasil Hits Playlist', tag: 'Brasil'),
          (title: 'Sertanejo Pop', query: 'Sertanejo Hits Playlist', tag: 'Sertanejo'),
          (title: 'Funk Hits', query: 'Funk Brasil Playlist', tag: 'Funk'),
        ];
      case 'JP':
        return const [
          (title: 'J-Pop Hits', query: 'J-Pop Top Hits Playlist', tag: 'J-Pop'),
          (title: 'Anime Hits & OST', query: 'Anime Song Playlist', tag: 'Anime'),
          (title: 'City Pop & Indie', query: 'Japanese City Pop Playlist', tag: 'City Pop'),
        ];
      case 'KR':
        return const [
          (title: 'K-Pop Trending', query: 'K-Pop Top Hits Playlist', tag: 'K-Pop'),
          (title: 'K-Drama OST', query: 'Korean Drama OST Playlist', tag: 'OST'),
          (title: 'K-R&B & Hip-Hop', query: 'Korean R&B Hip Hop Playlist', tag: 'K-R&B'),
        ];
      default:
        return const [
          (title: "Today's Top Hits", query: 'Today Top Hits Playlist', tag: 'Top Hits'),
          (title: 'Trending Now', query: 'Trending Music Playlist', tag: 'Trending'),
          (title: 'Hollywood & Global', query: 'Global Pop Hits Playlist', tag: 'Hollywood'),
          (title: 'Chill & Acoustic', query: 'Chill Vibes Acoustic Playlist', tag: 'Chill'),
        ];
    }
  }

  /// Fetches top songs for the quick picks grid tailored to the selected region.
  Future<List<Song>> _fetchRegionalQuickPicks(String region) async {
    final query = _getRegionalQuickPickQuery(region);
    try {
      final res = await _client.post(Innertube.search, {
        ..._client.context,
        'query': query,
        'params': searchParams(filter: SearchFilter.songs),
      });
      final parsed = res.flatMap(
        (json) => parseSearch(json, query: query, filter: SearchFilter.songs),
      );
      if (parsed case Ok(:final value)) {
        final songs = <Song>[
          if (value.topResult case SongItem(:final song)) song,
          for (final sec in value.sections)
            for (final item in sec.items)
              if (item case SongItem(:final song)) song,
        ];
        return songs.take(16).toList();
      }
    } catch (_) {}
    return const [];
  }

  String _getRegionalQuickPickQuery(String region) {
    switch (region.toUpperCase()) {
      case 'US':
        return 'Today Top Hits Billboard US';
      case 'IN':
        return 'Top Indian Hits Hindi Malayalam Tamil';
      case 'PK':
        return 'Pakistani Top Hits Coke Studio Songs';
      case 'UK':
        return 'UK Top 40 Official Singles Chart';
      case 'JP':
        return 'J-Pop Top Hits Trending Japan';
      case 'KR':
        return 'K-Pop Top Hits Trending Korea';
      case 'CA':
        return 'Canada Top Hits Billboard';
      case 'AU':
        return 'ARIA Top 50 Singles Australia';
      case 'DE':
        return 'Top Hits Deutschland';
      case 'FR':
        return 'Top 50 France Hits';
      case 'BR':
        return 'Top Brasil Hits';
      default:
        return 'Today Top Hits Global Billboard';
    }
  }
}
