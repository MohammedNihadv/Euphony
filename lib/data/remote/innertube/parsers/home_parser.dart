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

/// Parses a YouTube Music home page response (FEmusic_home or
/// FEmusic_new_releases).
///
/// The page skeleton is:
///   contents
///     singleColumnBrowseResultsRenderer
///       tabs[0].tabRenderer.content      <- Map (P.singleColumnTab)
///         sectionListRenderer.contents   <- List (P.sectionList)
///           [musicCarouselShelfRenderer | musicShelfRenderer | gridRenderer]
///
/// Previous code requested P.singleColumnTab as a List, which always failed
/// because content is a Map. We now navigate it as a Map and then step
/// into sectionListRenderer.contents from there.
Result<HomeFeed> parseHomeFeed(Map<String, dynamic> root) {
  // Step 1: reach the content Map at the tab level.
  final contentMap =
      navOrNull<Map<String, dynamic>>(root, P.singleColumnTab) ??
      navOrNull<Map<String, dynamic>>(root, P.singleColumn);

  if (contentMap == null) {
    return const Err(ParseFailure('home.singleColumnTab'));
  }

  // Step 2: get the sectionList contents (the shelf array).
  final sectionList = navOrNull<List<dynamic>>(contentMap, P.sectionList);

  if (sectionList == null) {
    return const Err(ParseFailure('home.sectionList'));
  }

  final quickPicks = <Song>[];
  final sections = <HomeSection>[];

  for (final section in sectionList) {
    if (section is! Map<String, dynamic>) continue;

    // Handle gridRenderer (used by FEmusic_new_releases for the mix card).
    if (section.containsKey('gridRenderer')) {
      final grid = section['gridRenderer'] as Map<String, dynamic>?;
      if (grid == null) continue;
      final gridItems = grid['items'] as List<dynamic>? ?? const [];
      final parsed = <MusicItem>[];
      for (final raw in gridItems) {
        if (raw is! Map<String, dynamic>) continue;
        final renderer =
            raw['musicTwoRowItemRenderer'] as Map<String, dynamic>? ??
            raw['musicResponsiveListItemRenderer'] as Map<String, dynamic>?;
        if (renderer == null) continue;
        final r = parseTwoRowItem(renderer);
        if (r case Ok(:final value)) {
          parsed.add(value);
          if (value case SongItem(:final song)) quickPicks.add(song);
        }
      }
      if (parsed.isNotEmpty) {
        sections.add(HomeSection(title: 'New Release Mix', items: parsed));
      }
      continue;
    }

    // Handle musicCarouselShelfRenderer and musicShelfRenderer.
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

      final twoRow =
          rawItem['musicTwoRowItemRenderer'] as Map<String, dynamic>?;
      final listRow =
          rawItem['musicResponsiveListItemRenderer'] as Map<String, dynamic>?;

      Result<MusicItem> parsed;
      if (twoRow != null) {
        parsed = parseTwoRowItem(twoRow);
      } else if (listRow != null) {
        parsed = parseListItem(listRow);
      } else {
        parsed = parseListItem(rawItem);
      }

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
