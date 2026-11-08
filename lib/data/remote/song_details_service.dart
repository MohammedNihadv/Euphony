import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;

import '../../core/log.dart';
import '../../core/result.dart';
import '../../domain/song.dart';
import '../../domain/song_details.dart';
import '../repository/music_detail_repository.dart';

final _log = logFor('song_details_service');

/// Service that retrieves detailed track metadata, views, likes, and channel info.
class SongDetailsService {
  SongDetailsService._();
  static final SongDetailsService instance = SongDetailsService._();

  final Map<String, SongDetails> _cache = {};

  /// Fetches comprehensive song and artist metadata for [song].
  Future<SongDetails?> getSongDetails(
    Song song, {
    MusicDetailRepository? musicDetailRepo,
  }) async {
    if (_cache.containsKey(song.id)) {
      return _cache[song.id];
    }

    DateTime? uploadDate;
    int? viewCount;
    int? likeCount;
    int? dislikeCount;
    String? description;
    String? artistName = song.artistNames.isNotEmpty ? song.artistNames : null;
    String? artistId = song.artists.isNotEmpty ? song.artists.first.browseId : null;
    String? artistThumbnailUrl = song.artwork?.max ?? song.artworkUrl;
    String? artistSubscribers;

    final yt = yt_explode.YoutubeExplode();
    try {
      final video = await yt.videos.get(song.id);
      uploadDate = video.uploadDate ?? video.publishDate;
      viewCount = video.engagement.viewCount;
      likeCount = video.engagement.likeCount;
      dislikeCount = video.engagement.dislikeCount;
      description = video.description;
      artistName ??= video.author;
      artistId ??= video.channelId.value;

      try {
        final channel = await yt.channels.get(video.channelId);
        if (channel.logoUrl.isNotEmpty) {
          artistThumbnailUrl = channel.logoUrl;
        }
      } catch (_) {}
    } catch (e) {
      _log.warning('YoutubeExplode video details fetch failed for ${song.id}: $e');
    } finally {
      yt.close();
    }

    // Query artist page for subscriber count and high-res artist photography
    final effectiveArtistId = artistId ?? (song.artists.isNotEmpty ? song.artists.first.browseId : null);
    if (effectiveArtistId != null &&
        effectiveArtistId.startsWith('UC') &&
        musicDetailRepo != null) {
      try {
        final res = await musicDetailRepo.fetchArtist(effectiveArtistId);
        if (res case Ok(:final value)) {
          if (value.artworkUrl != null && value.artworkUrl!.isNotEmpty) {
            artistThumbnailUrl = value.artworkUrl;
          }
          if (value.subscribers != null && value.subscribers!.isNotEmpty) {
            artistSubscribers = value.subscribers;
          }
          if (value.name.isNotEmpty) {
            artistName = value.name;
          }
        }
      } catch (e) {
        _log.warning('Artist page fetch failed for $effectiveArtistId: $e');
      }
    }

    final details = SongDetails(
      songId: song.id,
      uploadDate: uploadDate,
      viewCount: viewCount,
      likeCount: likeCount,
      dislikeCount: dislikeCount,
      description: description,
      artistName: artistName,
      artistId: effectiveArtistId,
      artistThumbnailUrl: artistThumbnailUrl,
      artistSubscribers: artistSubscribers,
    );

    _cache[song.id] = details;
    return details;
  }
}

