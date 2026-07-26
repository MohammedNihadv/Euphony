import 'package:meta/meta.dart';

import 'album.dart';
import 'artist.dart';
import 'playlist.dart';
import 'song.dart';

@immutable
sealed class MusicItem {
  const MusicItem();
}

final class SongItem extends MusicItem {
  const SongItem(this.song);
  final Song song;
}

final class AlbumItem extends MusicItem {
  const AlbumItem(this.album);
  final Album album;
}

final class ArtistItem extends MusicItem {
  const ArtistItem(this.artist);
  final Artist artist;
}

final class PlaylistItem extends MusicItem {
  const PlaylistItem(this.playlist);
  final Playlist playlist;
}

final class StationItem extends MusicItem {
  const StationItem({
    required this.title,
    required this.playlistId,
    this.artworkUrl,
  });

  final String title;
  final String playlistId;
  final String? artworkUrl;
}
