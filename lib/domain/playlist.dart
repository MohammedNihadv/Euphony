import 'package:meta/meta.dart';

import '../core/util/thumbnail_url.dart';
import 'song.dart';

/// Where a playlist lives.
enum PlaylistKind {
  /// Created in Euphony, stored only on this device.
  local,

  /// A YouTube Music playlist.
  youtube,

  /// Synced from a Piped account.
  piped,
}

@immutable
class Playlist {
  const Playlist({
    required this.id,
    required this.title,
    this.kind = PlaylistKind.youtube,
    this.description,
    this.artworkUrl,
    this.author,
    this.trackCount,
    this.tracks = const [],
    this.continuationToken,
  });

  /// A `VL…`/`PL…` id for YouTube playlists, or a generated id for local ones.
  final String id;
  final String title;
  final PlaylistKind kind;
  final String? description;
  final String? artworkUrl;
  final String? author;
  final int? trackCount;

  /// Populated when the playlist page has been fetched. Large playlists arrive
  /// in pages — see [continuationToken].
  final List<Song> tracks;

  /// Token for the next page, or `null` when the list is complete.
  final String? continuationToken;

  bool get hasMore => continuationToken != null;

  ThumbnailUrl? get artwork =>
      artworkUrl == null ? null : ThumbnailUrl(artworkUrl!);

  Playlist copyWith({
    String? title,
    String? description,
    String? artworkUrl,
    String? author,
    int? trackCount,
    List<Song>? tracks,
    String? continuationToken,
    bool clearContinuation = false,
  }) => Playlist(
    id: id,
    title: title ?? this.title,
    kind: kind,
    description: description ?? this.description,
    artworkUrl: artworkUrl ?? this.artworkUrl,
    author: author ?? this.author,
    trackCount: trackCount ?? this.trackCount,
    tracks: tracks ?? this.tracks,
    continuationToken: clearContinuation
        ? null
        : continuationToken ?? this.continuationToken,
  );

  @override
  String toString() => 'Playlist($id, "$title", ${tracks.length} loaded)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Playlist && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
