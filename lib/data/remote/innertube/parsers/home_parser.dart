import '../../../../core/failure.dart';
import '../../../../core/result.dart';
import '../../../../domain/music_item.dart';
import '../../../../domain/song.dart';
import '../innertube_paths.dart';
import '../json_nav.dart';
import 'item_parser.dart';

/// A section/shelf on the YouTube Music Home page.
class HomeSection {
  const HomeSection({required this.title, this.items = const []});

  final String title;
  final List<MusicItem> items;
}

/// The decoded YouTube Music home page.
class HomeFeed {
  const HomeFeed({this.quickPicks = const [], this.sections = const []});

  final List<Song> quickPicks;
  final List<HomeSection> sections;
}

/// Parses a YouTube Music home page response (`FEmusic_home`).
Result<HomeFeed> parseHomeFeed(Map<String, dynamic> root) {
  final contents = navOrNull<List<dynamic>>(root, P.singleColumnTab);
  final sectionList = contents != null
      ? navOrNull<List<dynamic>>(contents.first, P.sectionList)
      : null;

  if (sectionList == null) {
    return const Err(ParseFailure('home.sectionList'));
  }

  final quickPicks = <Song>[];
  final sections = <HomeSection>[];

  for (final section in sectionList) {
    if (section is! Map<String, dynamic>) continue;

    final shelf =
        section['musicCarouselShelfRenderer'] as Map<String, dynamic>? ??
        section['musicShelfRenderer'] as Map<String, dynamic>?;

    if (shelf == null) continue;

    final title =
        navOrNull<String>(shelf, P.carouselTitle) ??
        navOrNull<String>(shelf, P.titleText) ??
        'Featured';

    final contentsList = shelf['contents'] as List<dynamic>? ?? const [];
    final items = <MusicItem>[];

    for (final rawItem in contentsList) {
      if (rawItem is! Map<String, dynamic>) continue;
      final renderer =
          rawItem['musicResponsiveListItemRenderer'] as Map<String, dynamic>? ??
          rawItem['musicTwoRowItemRenderer'] as Map<String, dynamic>? ??
          rawItem;

      final parsed = parseListItem(renderer);
      if (parsed case Ok(:final value)) {
        items.add(value);
        if (value case SongItem(:final song)) {
          quickPicks.add(song);
        }
      }
    }

    if (items.isNotEmpty) {
      sections.add(HomeSection(title: title, items: items));
    }
  }

  return Ok(HomeFeed(quickPicks: quickPicks, sections: sections));
}
