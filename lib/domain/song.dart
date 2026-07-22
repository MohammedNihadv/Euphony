import 'package:meta/meta.dart';

import '../core/util/thumbnail_url.dart';
import 'artist_ref.dart';

/// What kind of thing a "song" actually is.
///
/// YouTube Music mixes real audio tracks with music videos and user uploads in
/// the same shelves. They behave differently — videos are larger, often have a
/// different duration than the audio release, and some cannot be cached — so
/// the distinction is kept rather than flattened.
enum SongKind { song, video, upload, episode }

/// A playable track.
@immutable
class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artists,
    this.kind = SongKind.song,
    this.albumId,
    this.albumTitle,
    this.artworkUrl,
    this.duration,
    this.year,
    this.trackNumber,
    this.isExplicit = false,
    this.playlistId,
  });

  /// The YouTube video id. Primary key everywhere in Euphony.
  final String id;
  final String title;
  final List<ArtistRef> artists;
  final SongKind kind;
  final String? albumId;
  final String? albumTitle;
  final String? artworkUrl;
  final Duration? duration;
  final int? year;
  final int? trackNumber;
  final bool isExplicit;

  /// The playlist this song was found in, when it came from one — needed to
  /// start radio from the right context.
  final String? playlistId;

  String get artistNames => formatArtists(artists);

  ThumbnailUrl? get artwork =>
      artworkUrl == null ? null : ThumbnailUrl(artworkUrl!);

  Song copyWith({
    String? title,
    List<ArtistRef>? artists,
    String? albumId,
    String? albumTitle,
    String? artworkUrl,
    Duration? duration,
    int? year,
    int? trackNumber,
    bool? isExplicit,
    String? playlistId,
  }) => Song(
    id: id,
    title: title ?? this.title,
    artists: artists ?? this.artists,
    kind: kind,
    albumId: albumId ?? this.albumId,
    albumTitle: albumTitle ?? this.albumTitle,
    artworkUrl: artworkUrl ?? this.artworkUrl,
    duration: duration ?? this.duration,
    year: year ?? this.year,
    trackNumber: trackNumber ?? this.trackNumber,
    isExplicit: isExplicit ?? this.isExplicit,
    playlistId: playlistId ?? this.playlistId,
  );

  @override
  String toString() => 'Song($id, "$title", $artistNames)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Song && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
