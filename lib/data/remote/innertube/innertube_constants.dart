/// InnerTube endpoint constants.
///
/// Ported from Harmony's `constant.dart`. The API key is the public web-client
/// key YouTube Music ships in its own page source, not a credential.
abstract final class Innertube {
  static const String domain = 'https://music.youtube.com/';
  static const String baseUrl = '${domain}youtubei/v1/';
  static const String apiKey = 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30';
  static const String fixedParams = '?prettyPrint=false&alt=json&key=$apiKey';

  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36';

  static const String clientName = 'WEB_REMIX';

  /// Used when visitor-id generation fails — a known-good value that keeps the
  /// app working rather than failing every request.
  static const String fallbackVisitorId =
      'CgttN24wcmd5UzNSWSi2lvq2BjIKCgJKUBIEGgAgYQ%3D%3D';

  /// Visitor ids are treated as valid for 30 days.
  static const Duration visitorIdLifetime = Duration(days: 30);

  // Endpoints.
  static const String browse = 'browse';
  static const String search = 'search';
  static const String next = 'next';
  static const String player = 'player';
  static const String searchSuggestions = 'music/get_search_suggestions';

  // Browse ids for the fixed feeds.
  static const String homeBrowseId = 'FEmusic_home';
  static const String chartsBrowseId = 'FEmusic_charts';
  static const String moodsBrowseId = 'FEmusic_moods_and_genres';
}
