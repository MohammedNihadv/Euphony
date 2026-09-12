import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt_explode;

import '../core/log.dart';
import '../data/providers.dart';
import '../domain/artist_ref.dart';
import '../domain/song.dart';
import '../playback/player_provider.dart';

final _log = logFor('download');

const _downloadedSongsKey = 'offline_downloaded_songs_v1';

// ---------------------------------------------------------------------------
// Download progress
// ---------------------------------------------------------------------------

class DownloadProgressNotifier extends Notifier<Map<String, double>> {
  @override
  Map<String, double> build() => const {};

  void setProgress(String songId, double progress) {
    state = {...state, songId: progress.clamp(0.0, 1.0)};
  }

  void removeProgress(String songId) {
    final next = {...state}..remove(songId);
    state = next;
  }
}

final downloadProgressProvider =
    NotifierProvider<DownloadProgressNotifier, Map<String, double>>(
      DownloadProgressNotifier.new,
    );

// ---------------------------------------------------------------------------
// Downloaded songs list
// ---------------------------------------------------------------------------

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
      await prefs.setString(_downloadedSongsKey, json.encode(songs.map(_songToJson).toList()));
    } catch (e) {
      _log.warning('Failed to save downloaded songs: $e');
    }
  }

  bool isDownloaded(String songId) => state.any((s) => s.id == songId);

  Future<String?> getLocalFilePath(String songId) async {
    if (!isDownloaded(songId)) return null;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final file = File('${docDir.path}/offline_audio/$songId.audio');
      if (file.existsSync()) return file.path;
    } catch (e) {
      _log.warning('Error checking local audio file for $songId: $e');
    }
    return null;
  }

  /// Downloads [song] using the **InnerTube** player endpoint — the same
  /// pipeline that drives playback, proven reliable on Android.
  ///
  /// Flow:
  ///  1. Ask InnerTube for streaming data (tries 4 clients, retries on error).
  ///  2. Pick the best audio-only URL with [pickAudioStreamUrl].
  ///  3. Download via Dio with progress callbacks, saving as a temp file first.
  ///  4. Atomically rename to the final path on success.
  Future<void> downloadSong(Song song) async {
    if (isDownloaded(song.id)) return;

    final progressNotifier = ref.read(downloadProgressProvider.notifier);
    progressNotifier.setProgress(song.id, 0.01);

    try {
      // ── 2. Prepare output paths ────────────────────────────────────────
      final docDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${docDir.path}/offline_audio');
      if (!dir.existsSync()) dir.createSync(recursive: true);

      final filePath = '${dir.path}/${song.id}.audio';
      final tempPath = '${dir.path}/${song.id}.tmp';
      final tempFile = File(tempPath);
      if (tempFile.existsSync()) tempFile.deleteSync();

      // ── 1. Resolve stream URL ───────────────────────────────────────────
      String? streamUrl;

      // Primary: YoutubeExplode (forced onto ANDROID client, preferring itag 18)
      final yt = yt_explode.YoutubeExplode();
      try {
        final manifest = await yt.videos.streamsClient.getManifest(
          song.id,
          ytClients: [yt_explode.YoutubeApiClient.android],
        );

        final muxed = manifest.muxed.toList();
        if (muxed.isNotEmpty) {
          final chosen = muxed.firstWhere(
            (s) => s.tag == 18,
            orElse: () => muxed.first,
          );
          streamUrl = chosen.url.toString();
        }

        if (streamUrl == null || streamUrl.isEmpty) {
          final audioOnly = manifest.audioOnly.toList();
          if (audioOnly.isNotEmpty) {
            audioOnly.sort((a, b) => b.bitrate.compareTo(a.bitrate));
            streamUrl = audioOnly.first.url.toString();
          }
        }
      } catch (e) {
        _log.warning('YoutubeExplode download resolve failed for ${song.id}: $e');
      } finally {
        yt.close();
      }

      // Secondary fallback: InnerTube player endpoint
      if (streamUrl == null || streamUrl.isEmpty) {
        final client = ref.read(innertubeClientProvider);
        final result = await client.player(song.id);
        result.fold(
          (data) {
            final streamingData = data['streamingData'] as Map<String, dynamic>?;
            if (streamingData != null) {
              streamUrl = pickAudioStreamUrl(streamingData, quality: 'HIGH');
            }
          },
          (failure) {
            _log.warning('InnerTube player failed for ${song.id}: $failure');
          },
        );
      }

      final resolvedUrl = streamUrl;
      if (resolvedUrl == null || resolvedUrl.isEmpty) {
        throw Exception('No playable audio stream found for ${song.id}');
      }

      _log.info('Downloading "${song.title}" via chunked relay...');
      await _downloadUrlInChunks(
        streamUrl: resolvedUrl,
        outputFile: tempFile,
        songId: song.id,
        progressNotifier: progressNotifier,
      );

      // ── 3. Atomic rename ───────────────────────────────────────────────
      if (tempFile.existsSync()) {
        tempFile.renameSync(filePath);
      } else {
        throw Exception('Temp file missing after download');
      }

      // ── 5. Mark as downloaded ──────────────────────────────────────────
      progressNotifier.setProgress(song.id, 1.0);
      final next = [song, ...state.where((s) => s.id != song.id)];
      state = next;
      await _saveToPrefs(next);
      _log.info('Downloaded "${song.title}" → $filePath');
    } catch (e, st) {
      _log.warning('Download failed for ${song.id}: $e\n$st');
      // Clean up any partial temp file
      try {
        final docDir = await getApplicationDocumentsDirectory();
        final temp = File('${docDir.path}/offline_audio/${song.id}.tmp');
        if (temp.existsSync()) temp.deleteSync();
      } catch (_) {}
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
      if (file.existsSync()) file.deleteSync();
      final next = state.where((s) => s.id != songId).toList();
      state = next;
      await _saveToPrefs(next);
    } catch (e) {
      _log.warning('Error removing download $songId: $e');
    }
  }

  Future<void> _downloadUrlInChunks({
    required String streamUrl,
    required File outputFile,
    required String songId,
    required DownloadProgressNotifier progressNotifier,
  }) async {
    final uri = Uri.parse(streamUrl);
    int totalBytes = int.tryParse(uri.queryParameters['clen'] ?? '') ?? 0;

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20)
      ..idleTimeout = const Duration(seconds: 30);

    final output = outputFile.openWrite();
    var start = 0;
    const chunkSize = 512 * 1024;

    try {
      while (true) {
        var end = start + chunkSize - 1;
        if (totalBytes > 0 && end > totalBytes - 1) {
          end = totalBytes - 1;
        }

        final req = await client.getUrl(uri);
        req.headers.set(HttpHeaders.rangeHeader, 'bytes=$start-$end');
        req.headers.set(
          HttpHeaders.userAgentHeader,
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        );

        final res = await req.close();
        if (res.statusCode != HttpStatus.ok &&
            res.statusCode != HttpStatus.partialContent) {
          if (start > 0 &&
              (res.statusCode == HttpStatus.requestedRangeNotSatisfiable ||
                  res.statusCode == 416)) {
            break;
          }
          throw HttpException('HTTP ${res.statusCode}: ${res.reasonPhrase}');
        }

        if (totalBytes == 0) {
          final cr = res.headers.value(HttpHeaders.contentRangeHeader);
          if (cr != null) {
            final match = RegExp(r'/(\d+)').firstMatch(cr);
            if (match != null) {
              totalBytes = int.tryParse(match.group(1)!) ?? 0;
            }
          }
        }

        var chunkBytes = 0;
        await for (final data in res) {
          output.add(data);
          chunkBytes += data.length;
        }

        if (chunkBytes == 0) break;
        start += chunkBytes;

        if (totalBytes > 0) {
          final pct = (start / totalBytes).clamp(0.01, 0.99);
          progressNotifier.setProgress(songId, pct);
          if (start >= totalBytes) break;
        }
      }
    } finally {
      await output.flush();
      await output.close();
      client.close();
    }
  }

  // ── JSON serialization ──────────────────────────────────────────────────

  Map<String, dynamic> _songToJson(Song s) => {
    'id': s.id,
    'title': s.title,
    'artists': s.artists.map((a) => {'id': a.browseId, 'name': a.name}).toList(),
    'albumId': s.albumId,
    'albumTitle': s.albumTitle,
    'artworkUrl': s.artworkUrl,
    'duration': s.duration?.inSeconds,
    'isExplicit': s.isExplicit,
  };

  Song? _songFromJson(Map<String, dynamic> json) {
    try {
      final artistsList = (json['artists'] as List<dynamic>?)?.map((item) {
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
    NotifierProvider<DownloadedSongsNotifier, List<Song>>(
      DownloadedSongsNotifier.new,
    );
