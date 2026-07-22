/// Rewrites a YouTube thumbnail URL to a requested size.
///
/// Ported near-verbatim from Harmony's `models/thumbnail.dart` — it is a small
/// piece of genuinely good reverse engineering. YouTube serves art from three
/// different hosts with three different sizing conventions:
///
/// * `…=w60-h60-l90-rj`   — Google user content, width/height in the query
/// * `…=s60`              — the same host, square shorthand
/// * `i.ytimg.com/…/sddefault.jpg` — video stills, sized by filename
///
/// Requesting the right size matters: the default URLs are thumbnail-sized and
/// look soft on a full-screen player, while always requesting the largest wastes
/// bandwidth in a list.
extension type const ThumbnailUrl(String url) {
  static const int _lowSize = 150;
  static const int _mediumSize = 250;
  static const int _highSize = 400;
  static const int _maxSize = 600;

  /// The URL rewritten to request a [size] x [size] image.
  String sized(int size) {
    if (url.contains('-rj')) {
      return '${url.split('=').first}=w$size-h$size-l90-rj';
    }
    if (url.contains('=s')) {
      return '${url.split('=s').first}=s$size';
    }
    if (url.contains('i.yti') && size >= _maxSize) {
      return url.replaceFirst('sddefault', 'maxresdefault');
    }
    return url;
  }

  /// List rows and small tiles.
  String get low => sized(_lowSize);

  /// Grid tiles and the mini player.
  String get medium => sized(_mediumSize);

  /// Carousel cards and headers.
  String get high => sized(_highSize);

  /// The full-screen player.
  String get max => sized(_maxSize);
}
