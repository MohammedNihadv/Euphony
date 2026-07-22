import 'package:meta/meta.dart';

import '../core/util/thumbnail_url.dart';
import 'artist_ref.dart';
import 'song.dart';

/// An album, EP or single.
@immutable
class Album {
  const Album({
    required this.browseId,
    required this.title,
    this.artists = const [],
    this.artworkUrl,
    this.year,
    this.trackCount,
    this.description,
    this.isExplicit = false,
    this.audioPlaylistId,
    this.tracks = const [],
  });

  /// The `MPREb_…` browse id. Note this is *not* the playlist id — playing an
  /// album needs [audioPlaylistId], which only the album page carries.
  final String browseId;
  final String title;
  final List<ArtistRef> artists;
  final String? artworkUrl;
  final int? year;
  final int? trackCount;
  final String? description;
  final bool isExplicit;

  /// The `OLAK5uy_…` playlist backing this album.
  final String? audioPlaylistId;

  /// Populated only when the album page itself has been fetched.
  final List<Song> tracks;

  String get artistNames => formatArtists(artists);

  ThumbnailUrl? get artwork =>
      artworkUrl == null ? null : ThumbnailUrl(artworkUrl!);

  Duration get totalDuration => tracks.fold(
    Duration.zero,
    (sum, song) => sum + (song.duration ?? Duration.zero),
  );

  Album copyWith({
    String? title,
    List<ArtistRef>? artists,
    String? artworkUrl,
    int? year,
    int? trackCount,
    String? description,
    String? audioPlaylistId,
    List<Song>? tracks,
  }) => Album(
    browseId: browseId,
    title: title ?? this.title,
    artists: artists ?? this.artists,
    artworkUrl: artworkUrl ?? this.artworkUrl,
    year: year ?? this.year,
    trackCount: trackCount ?? this.trackCount,
    description: description ?? this.description,
    isExplicit: isExplicit,
    audioPlaylistId: audioPlaylistId ?? this.audioPlaylistId,
    tracks: tracks ?? this.tracks,
  );

  @override
  String toString() => 'Album($browseId, "$title")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Album && browseId == other.browseId;

  @override
  int get hashCode => browseId.hashCode;
}
