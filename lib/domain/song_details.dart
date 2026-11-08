import 'package:meta/meta.dart';

/// Detailed metadata for a playable track / video, including engagement and channel stats.
@immutable
class SongDetails {
  const SongDetails({
    required this.songId,
    this.uploadDate,
    this.viewCount,
    this.likeCount,
    this.dislikeCount,
    this.description,
    this.artistName,
    this.artistId,
    this.artistThumbnailUrl,
    this.artistSubscribers,
  });

  final String songId;
  final DateTime? uploadDate;
  final int? viewCount;
  final int? likeCount;
  final int? dislikeCount;
  final String? description;
  final String? artistName;
  final String? artistId;
  final String? artistThumbnailUrl;
  final String? artistSubscribers;

  SongDetails copyWith({
    String? songId,
    DateTime? uploadDate,
    int? viewCount,
    int? likeCount,
    int? dislikeCount,
    String? description,
    String? artistName,
    String? artistId,
    String? artistThumbnailUrl,
    String? artistSubscribers,
  }) {
    return SongDetails(
      songId: songId ?? this.songId,
      uploadDate: uploadDate ?? this.uploadDate,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      description: description ?? this.description,
      artistName: artistName ?? this.artistName,
      artistId: artistId ?? this.artistId,
      artistThumbnailUrl: artistThumbnailUrl ?? this.artistThumbnailUrl,
      artistSubscribers: artistSubscribers ?? this.artistSubscribers,
    );
  }
}

