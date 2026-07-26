import '../../core/result.dart';
import '../../domain/artist.dart';
import '../remote/innertube/innertube_client.dart';
import '../remote/innertube/parsers/album_parser.dart';
import '../remote/innertube/parsers/artist_parser.dart';

/// Access to Artist, Album, and Playlist details.
class MusicDetailRepository {
  MusicDetailRepository(this._client);

  final InnertubeClient _client;

  /// Fetches artist channel details for [browseId].
  Future<Result<Artist>> fetchArtist(String browseId) async {
    final response = await _client.browse(browseId);
    return response.flatMap((root) => parseArtistPage(root, browseId));
  }

  /// Fetches album details for [browseId].
  Future<Result<AlbumDetails>> fetchAlbum(String browseId) async {
    final response = await _client.browse(browseId);
    return response.flatMap((root) => parseAlbumDetails(root, browseId));
  }

  /// Fetches playlist details for [playlistId].
  Future<Result<PlaylistDetails>> fetchPlaylist(String playlistId) async {
    final response = await _client.browse(playlistId);
    return response.flatMap((root) => parsePlaylistDetails(root, playlistId));
  }
}
