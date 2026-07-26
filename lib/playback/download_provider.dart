import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;

import '../core/log.dart';
import '../data/providers.dart';
import '../domain/artist_ref.dart';
import '../domain/song.dart';

final _log = logFor('download_provider');

const _downloadedSongsKey = 'offline_downloaded_songs_v1';

class DownloadProgressNotifier extends Notifier<Map<String, double>> {
  @override
  Map<String, double> build() => const {};

  void setProgress(String songId, double progress) {
    state = {...state, songId: progress.clamp(0.0, 1.0)};
  }

  void removeProgress(String songId) {
    final next = {...state};
    next.remove(songId);
    state = next;
  }
}

final downloadProgressProvider =
    NotifierProvider<DownloadProgressNotifier, Map<String, double>>(() {
      return DownloadProgressNotifier();
    });

class DownloadedSongsNotifier extends Notifier<List<Song>> {
  @override
  List<Song> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    try {
      final jsonStr = prefs.getString(_downloadedSongsKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final list = json.decode(jsonStr) as List<dynamic>;
        return list
            .map((item) => _songFromJson(item as Map<String, dynamic>))
            .whereType<Song>()
            .toList();
      }
    } catch (e) {
      _log.warning('Failed to load downloaded songs: $e');
    }
    return const [];
  }

  Future<void> _saveToPrefs(List<Song> songs) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final list = songs.map(_songToJson).toList();
      await prefs.setString(_downloadedSongsKey, json.encode(list));
    } catch (e) {
      _log.warning('Failed to save downloaded songs: $e');
    }
  }

  bool isDownloaded(String songId) {
    return state.any((s) => s.id == songId);
  }

  Future<String?> getLocalFilePath(String songId) async {
    if (!isDownloaded(songId)) return null;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${docDir.path}/offline_audio');
      final file = File('${dir.path}/$songId.audio');
      if (file.existsSync()) {
        return file.path;
      }
    } catch (e) {
      _log.warning('Error checking local audio file for $songId: $e');
    }
    return null;
  }

  Future<void> downloadSong(Song song) async {
    if (isDownloaded(song.id)) return;
    final progressNotifier = ref.read(downloadProgressProvider.notifier);
    progressNotifier.setProgress(song.id, 0.01);

    try {
      final yt = yt_explode.YoutubeExplode();
      final manifest = await yt.videos.streamsClient.getManifest(song.id);
      yt.close();
      final audioOnly = manifest.audioOnly;
      if (audioOnly.isEmpty) {
        throw Exception('No audio stream found for ${song.id}');
      }
      final bestAudio = audioOnly.lastWhere(
        (item) => item.tag == 251 || item.tag == 140,
        orElse: () => audioOnly.first,
      );
      final url = bestAudio.url.toString();

      final docDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${docDir.path}/offline_audio');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final filePath = '${dir.path}/${song.id}.audio';
      final tempPath = '${dir.path}/${song.id}.temp';

      final dio = Dio();
      await dio.download(
        url,
        tempPath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final pct = (received / total).clamp(0.01, 0.99);
            progressNotifier.setProgress(song.id, pct);
          }
        },
      );

      final file = File(tempPath);
      if (file.existsSync()) {
        file.renameSync(filePath);
      }

      progressNotifier.setProgress(song.id, 1.0);
      final next = [song, ...state.where((s) => s.id != song.id)];
      state = next;
      await _saveToPrefs(next);
      _log.info('Successfully downloaded ${song.title} to $filePath');
    } catch (e) {
      _log.warning('Failed to download ${song.id}: $e');
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        progressNotifier.removeProgress(song.id);
      });
    }
  }

  Future<void> removeDownload(String songId) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final file = File('${docDir.path}/offline_audio/$songId.audio');
      if (file.existsSync()) {
        file.deleteSync();
      }
      final next = state.where((s) => s.id != songId).toList();
      state = next;
      await _saveToPrefs(next);
    } catch (e) {
      _log.warning('Error removing download $songId: $e');
    }
  }

  Map<String, dynamic> _songToJson(Song s) {
    return {
      'id': s.id,
      'title': s.title,
      'artists': s.artists
          .map((a) => {'id': a.browseId, 'name': a.name})
          .toList(),
      'albumId': s.albumId,
      'albumTitle': s.albumTitle,
      'artworkUrl': s.artworkUrl,
      'duration': s.duration?.inSeconds,
      'isExplicit': s.isExplicit,
    };
  }

  Song? _songFromJson(Map<String, dynamic> json) {
    try {
      final artistsList =
          (json['artists'] as List<dynamic>?)?.map((item) {
            final m = item as Map<String, dynamic>;
            return ArtistRef(
              browseId: m['id'] as String?,
              name: m['name'] as String? ?? 'Unknown',
            );
          }).toList() ??
          const [];
      final durationSec = json['duration'] as int?;
      return Song(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Unknown',
        artists: artistsList,
        albumId: json['albumId'] as String?,
        albumTitle: json['albumTitle'] as String?,
        artworkUrl: json['artworkUrl'] as String?,
        duration: durationSec != null ? Duration(seconds: durationSec) : null,
        isExplicit: json['isExplicit'] as bool? ?? false,
      );
    } catch (e) {
      return null;
    }
  }
}

final downloadedSongsProvider =
    NotifierProvider<DownloadedSongsNotifier, List<Song>>(() {
      return DownloadedSongsNotifier();
    });
