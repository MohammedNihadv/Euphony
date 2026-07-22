import 'package:meta/meta.dart';

import '../core/util/thumbnail_url.dart';
import 'album.dart';
import 'playlist.dart';
import 'song.dart';

/// One titled row on an artist page — "Songs", "Albums", "Singles", "Fans might
/// also like". Contents are heterogeneous, so each list is separate rather than
/// one `List<dynamic>`.
@immutable
class ArtistSection {
  const ArtistSection({
    required this.title,
    this.browseId,
    this.songs = const [],
    this.albums = const [],
    this.playlists = const [],
    this.relatedArtists = const [],
  });

  final String title;

  /// Set when the section has a "more" link.
  final String? browseId;

  final List<Song> songs;
  final List<Album> albums;
  final List<Playlist> playlists;
  final List<Artist> relatedArtists;

  bool get isEmpty =>
      songs.isEmpty &&
      albums.isEmpty &&
      playlists.isEmpty &&
      relatedArtists.isEmpty;
}

@immutable
class Artist {
  const Artist({
    required this.browseId,
    required this.name,
    this.artworkUrl,
    this.description,
    this.subscribers,
    this.radioId,
    this.shuffleId,
    this.sections = const [],
  });

  /// The `UC…` channel id.
  final String browseId;
  final String name;
  final String? artworkUrl;
  final String? description;

  /// As displayed, e.g. `"1.2M"` — YouTube does not give a number.
  final String? subscribers;

  /// Playlist ids for "start radio" and "shuffle", when the page offers them.
  final String? radioId;
  final String? shuffleId;

  final List<ArtistSection> sections;

  ThumbnailUrl? get artwork =>
      artworkUrl == null ? null : ThumbnailUrl(artworkUrl!);

  @override
  String toString() => 'Artist($browseId, "$name")';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Artist && browseId == other.browseId;

  @override
  int get hashCode => browseId.hashCode;
}
