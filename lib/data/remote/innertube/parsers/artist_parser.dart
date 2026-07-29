import '../../../../core/result.dart';
import '../../../../domain/artist.dart';
import '../../../../domain/music_item.dart';
import '../../../../domain/song.dart';
import '../innertube_paths.dart';
import '../json_nav.dart';
import 'item_parser.dart';

/// Parses an artist page response (`UC...`).
Result<Artist> parseArtistPage(Map<String, dynamic> root, String browseId) {
  // The artist name, art and subscriber count live in the immersive header —
  // not at the response root, which is where this used to look (and so always
  // fell back to the "Artist" placeholder with no art).
  final header =
      navOrNull<Map<String, dynamic>>(
        root,
        const JsonPath(['header', P.immersiveHeader]),
      ) ??
      navOrNull<Map<String, dynamic>>(
        root,
        const JsonPath(['header', 'musicVisualHeaderRenderer']),
      ) ??
      const <String, dynamic>{};

  final name = navOrNull<String>(header, P.titleText) ?? 'Artist';
  final artworkUrl =
      navOrNull<String>(header, P.thumbnailNested + [0, 'url']) ??
      navOrNull<String>(header, P.thumbnails + [0, 'url']);
  final subscribers =
      navOrNull<String>(
        header,
        const JsonPath([
          'subscriptionButton',
          'subscribeButtonRenderer',
          'subscriberCountText',
          'runs',
          0,
          'text',
        ]),
      ) ??
      navOrNull<String>(
        header,
        const JsonPath(['monthlyListenerCount', 'runs', 0, 'text']),
      );

  // Sections live under the single-column tab, not the response root.
  final sectionsList =
      navOrNull<List<dynamic>>(
        root,
        P.singleColumnTab + ['sectionListRenderer', 'contents'],
      ) ??
      navOrNull<List<dynamic>>(root, P.sectionList) ??
      const [];
  final artistSections = <ArtistSection>[];

  for (final section in sectionsList) {
    if (section is! Map<String, dynamic>) continue;

    final shelf =
        section['musicCarouselShelfRenderer'] as Map<String, dynamic>? ??
        section['musicShelfRenderer'] as Map<String, dynamic>?;

    if (shelf == null) continue;

    final title =
        navOrNull<String>(shelf, P.carouselTitle) ??
        navOrNull<String>(shelf, P.titleText) ??
        'Songs';

    final contentsList = shelf['contents'] as List<dynamic>? ?? const [];
    final songs = <Song>[];
    final artists = <Artist>[];

    for (final rawItem in contentsList) {
      if (rawItem is! Map<String, dynamic>) continue;
      final renderer =
          rawItem['musicResponsiveListItemRenderer'] as Map<String, dynamic>? ??
          rawItem['musicTwoRowItemRenderer'] as Map<String, dynamic>? ??
          rawItem;

      final parsed = parseListItem(renderer);
      if (parsed case Ok(:final value)) {
        switch (value) {
          case SongItem(:final song):
            songs.add(song);
          case ArtistItem(:final artist):
            artists.add(artist);
          default:
            break;
        }
      }
    }

    if (songs.isNotEmpty || artists.isNotEmpty) {
      artistSections.add(
        ArtistSection(title: title, songs: songs, relatedArtists: artists),
      );
    }
  }

  return Ok(
    Artist(
      browseId: browseId,
      name: name,
      artworkUrl: artworkUrl,
      subscribers: subscribers,
      sections: artistSections,
    ),
  );
}
