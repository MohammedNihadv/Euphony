import 'json_nav.dart';

/// Response paths into InnerTube's renderer tree.
///
/// Ported from Harmony's `nav_parser.dart`. These constants are the single most
/// valuable thing in that project — each one is a piece of reverse engineering
/// that took someone an afternoon with a JSON dump. They are centralised here
/// so that when YouTube moves a renderer, exactly one file changes.
abstract final class P {
  // Renderer type keys, used as map keys rather than path steps.
  static const String twoRowItem = 'musicTwoRowItemRenderer';
  static const String responsiveListItem = 'musicResponsiveListItemRenderer';
  static const String shelf = 'musicShelfRenderer';
  static const String carouselShelf = 'musicCarouselShelfRenderer';
  static const String cardShelf = 'musicCardShelfRenderer';
  static const String toggleMenuItem = 'toggleMenuServiceItemRenderer';

  // Page skeleton.
  static const singleColumn = JsonPath([
    'contents',
    'singleColumnBrowseResultsRenderer',
  ]);
  static const singleColumnTab = JsonPath([
    'contents',
    'singleColumnBrowseResultsRenderer',
    'tabs',
    0,
    'tabRenderer',
    'content',
  ]);
  static const sectionList = JsonPath(['sectionListRenderer', 'contents']);
  static const sectionListItem = JsonPath([
    'sectionListRenderer',
    'contents',
    0,
  ]);

  /// The two-column layout YouTube moved playlists to.
  static const playlistShelf = JsonPath([
    'contents',
    'twoColumnBrowseResultsRenderer',
    'secondaryContents',
    'sectionListRenderer',
    'contents',
    0,
    'musicPlaylistShelfRenderer',
  ]);

  // Text.
  static const runText = JsonPath(['runs', 0, 'text']);
  static const titleText = JsonPath(['title', 'runs', 0, 'text']);
  static const titleRun = JsonPath(['title', 'runs', 0]);
  static const textRunText = JsonPath(['text', 'runs', 0, 'text']);
  static const textRun = JsonPath(['text', 'runs', 0]);
  static const subtitle = JsonPath(['subtitle', 'runs', 0, 'text']);
  static const subtitle2 = JsonPath(['subtitle', 'runs', 2, 'text']);
  static const subtitle3 = JsonPath(['subtitle', 'runs', 4, 'text']);
  static const description = JsonPath(['description', 'runs', 0, 'text']);
  static const descriptionShelf = JsonPath(['musicDescriptionShelfRenderer']);

  // Navigation endpoints.
  static const navigationBrowse = JsonPath([
    'navigationEndpoint',
    'browseEndpoint',
  ]);
  static const navigationBrowseId = JsonPath([
    'navigationEndpoint',
    'browseEndpoint',
    'browseId',
  ]);
  static const navigationVideoId = JsonPath([
    'navigationEndpoint',
    'watchEndpoint',
    'videoId',
  ]);
  static const navigationPlaylistId = JsonPath([
    'navigationEndpoint',
    'watchEndpoint',
    'playlistId',
  ]);
  static const navigationWatchPlaylistId = JsonPath([
    'navigationEndpoint',
    'watchPlaylistEndpoint',
    'playlistId',
  ]);
  static const navigationVideoType = JsonPath([
    'watchEndpoint',
    'watchEndpointMusicSupportedConfigs',
    'watchEndpointMusicConfig',
    'musicVideoType',
  ]);

  /// Distinguishes an artist page from an album page on a browse endpoint.
  static const pageType = JsonPath([
    'browseEndpointContextSupportedConfigs',
    'browseEndpointContextMusicConfig',
    'pageType',
  ]);

  // Thumbnails — three shapes for the same thing.
  static const thumbnails = JsonPath(['thumbnail', 'thumbnails']);
  static const thumbnailRenderer = JsonPath([
    'thumbnailRenderer',
    'musicThumbnailRenderer',
    'thumbnail',
    'thumbnails',
  ]);
  static const thumbnailNested = JsonPath([
    'thumbnail',
    'musicThumbnailRenderer',
    'thumbnail',
    'thumbnails',
  ]);
  static const thumbnailCropped = JsonPath([
    'thumbnail',
    'croppedSquareThumbnailRenderer',
    'thumbnail',
    'thumbnails',
  ]);

  // Menus and badges.
  static const menuItems = JsonPath(['menu', 'menuRenderer', 'items']);
  static const menuService = JsonPath([
    'menuServiceItemRenderer',
    'serviceEndpoint',
  ]);
  static const menuLikeStatus = JsonPath([
    'menu',
    'menuRenderer',
    'topLevelButtons',
    0,
    'likeButtonRenderer',
    'likeStatus',
  ]);
  static const badgeLabel = JsonPath([
    'badges',
    0,
    'musicInlineBadgeRenderer',
    'accessibilityData',
    'accessibilityData',
    'label',
  ]);
  static const subtitleBadgeLabel = JsonPath([
    'subtitleBadges',
    0,
    'musicInlineBadgeRenderer',
    'accessibilityData',
    'accessibilityData',
    'label',
  ]);
  static const feedbackToken = JsonPath(['feedbackEndpoint', 'feedbackToken']);
  static const playButton = JsonPath([
    'overlay',
    'musicItemThumbnailOverlayRenderer',
    'content',
    'musicPlayButtonRenderer',
  ]);
  static const carouselTitle = JsonPath([
    'header',
    'musicCarouselShelfBasicHeaderRenderer',
    'title',
    'runs',
    0,
  ]);

  // Search.
  static const tabbedSearchTabs = JsonPath([
    'contents',
    'tabbedSearchResultsRenderer',
    'tabs',
  ]);
  static const searchSuggestions = JsonPath([
    'contents',
    0,
    'searchSuggestionsSectionRenderer',
    'contents',
  ]);
  static const searchSuggestionQuery = JsonPath([
    'searchSuggestionRenderer',
    'navigationEndpoint',
    'searchEndpoint',
    'query',
  ]);
  static const searchChips = JsonPath([
    'sectionListRenderer',
    'header',
    'chipCloudRenderer',
    'chips',
  ]);
}
