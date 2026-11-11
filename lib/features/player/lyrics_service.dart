import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/log.dart';
import '../../domain/song.dart';

final _log = logFor('lyrics_service');

/// A single timestamped line of synchronized lyrics.
class LyricLine {
  const LyricLine({required this.timestamp, required this.text});

  final Duration timestamp;
  final String text;
}

/// Lyrics payload containing synchronized lines, plain text, and sync status.
class SongLyrics {
  const SongLyrics({
    required this.songId,
    required this.syncedLines,
    this.plainLyrics,
    required this.isSynced,
  });

  final String songId;
  final List<LyricLine> syncedLines;
  final String? plainLyrics;
  final bool isSynced;

  Map<String, dynamic> toJson() => {
    'songId': songId,
    'synced': syncedLines
        .map((l) => {'ms': l.timestamp.inMilliseconds, 'text': l.text})
        .toList(),
    'plain': plainLyrics,
    'isSynced': isSynced,
  };

  factory SongLyrics.fromJson(Map<String, dynamic> json) {
    final rawSynced = json['synced'];
    final list = (rawSynced is List)
        ? rawSynced.map((item) {
            final map = item as Map<String, dynamic>;
            return LyricLine(
              timestamp: Duration(milliseconds: (map['ms'] as num).toInt()),
              text: map['text'] as String,
            );
          }).toList()
        : <LyricLine>[];
    return SongLyrics(
      songId: json['songId'] as String,
      syncedLines: list,
      plainLyrics: json['plain'] as String?,
      isSynced: json['isSynced'] as bool? ?? list.isNotEmpty,
    );
  }
}

/// Service that fetches, parses (.lrc format), and caches synchronized lyrics.
class LyricsService {
  LyricsService._();
  static final LyricsService instance = LyricsService._();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 7),
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  Directory? _cacheDir;

  Future<Directory> _getCacheDirectory() async {
    if (_cacheDir != null) return _cacheDir!;
    final dir = await getApplicationSupportDirectory();
    final cache = Directory('${dir.path}/lyrics_cache');
    if (!cache.existsSync()) {
      cache.createSync(recursive: true);
    }
    _cacheDir = cache;
    return cache;
  }

  /// Parses an .lrc formatted string into ordered [LyricLine] instances.
  static List<LyricLine> parseLrc(String lrcText) {
    final lines = <LyricLine>[];
    final timestampRegex = RegExp(r'\[(\d+):(\d+(?:\.\d+)?)\]');

    for (final rawLine in lrcText.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      final matches = timestampRegex.allMatches(line).toList();
      if (matches.isEmpty) continue;

      final text = line.replaceAll(timestampRegex, '').trim();

      for (final match in matches) {
        final minStr = match.group(1);
        final secStr = match.group(2);
        if (minStr != null && secStr != null) {
          final minutes = int.tryParse(minStr) ?? 0;
          final seconds = double.tryParse(secStr) ?? 0.0;
          final totalMs = (minutes * 60 * 1000) + (seconds * 1000).round();
          lines.add(LyricLine(
            timestamp: Duration(milliseconds: totalMs),
            text: text,
          ));
        }
      }
    }

    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return lines;
  }

  /// Cleans noise from track title (e.g. "(Official Music Video)", "[Remastered]",
  /// YouTube video suffixes, pipe separated metadata, and movie tags).
  static String cleanTrackTitle(String rawTitle) {
    var title = rawTitle;

    // 1. If title contains pipe '|', take the first segment (often the actual track title)
    if (title.contains('|')) {
      title = title.split('|').first;
    }

    // 2. Strip noise after dash/hyphen if it contains common video/release keywords
    final dashMatch = RegExp(
      r'\s*[-–—]\s*(official\s*(music)?\s*(video|audio)?|lyric(al)?\s*(video)?|video\s*song|audio\s*song|full\s*(video|song)?|remastered|hd|4k|from\s+.*|ost|promo|teaser|visualizer).*$',
      caseSensitive: false,
    );
    title = title.replaceAll(dashMatch, '');

    // 3. Strip bracketed/parenthesized tags
    title = title
        .replaceAll(
          RegExp(
            r'\s*[\(\[](official\s*(music)?\s*(video|audio)?|lyric(al)?\s*(video)?|audio|video\s*song|remastered|hd|4k|from\s+[^)\]]+|visualizer)[\)\]]',
            caseSensitive: false,
          ),
          '',
        )
        .replaceAll(RegExp(r'\s*[\(\[]feat\..*?[\)\]]', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*[\(\[]ft\..*?[\)\]]', caseSensitive: false), '')
        .trim();

    return title.isNotEmpty ? title : rawTitle.trim();
  }

  /// Helper to pick the best matching lyrics candidate (prioritizing synchronized lyrics).
  static Map<String, dynamic>? _pickBestLyrics(List<dynamic> list) {
    for (final item in list) {
      if (item is Map) {
        final synced = item['syncedLyrics']?.toString().trim();
        if (synced != null && synced.isNotEmpty) {
          return Map<String, dynamic>.from(item);
        }
      }
    }
    for (final item in list) {
      if (item is Map) {
        final plain = item['plainLyrics']?.toString().trim();
        if (plain != null && plain.isNotEmpty) {
          return Map<String, dynamic>.from(item);
        }
      }
    }
    return list.isNotEmpty && list.first is Map
        ? Map<String, dynamic>.from(list.first as Map)
        : null;
  }

  /// Fetches lyrics for [song], utilizing local disk cache first, followed by LRCLIB.
  Future<SongLyrics?> getLyrics(Song song) async {
    // 1. Check local offline cache
    try {
      final cache = await _getCacheDirectory();
      final cacheFile = File('${cache.path}/${song.id}.json');
      if (cacheFile.existsSync()) {
        final content = await cacheFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        _log.fine('loaded lyrics from offline cache for ${song.title}');
        return SongLyrics.fromJson(json);
      }
    } catch (e) {
      _log.warning('failed reading offline lyrics cache: $e');
    }

    // 2. Query LRCLIB
    final cleanTitle = cleanTrackTitle(song.title);
    final queryTitle = cleanTitle.isNotEmpty ? cleanTitle : song.title;

    Map<String, dynamic>? data;

    // A. Exact match by artist, track name, and duration
    try {
      final artist = Uri.encodeComponent(song.artistNames);
      final title = Uri.encodeComponent(queryTitle);
      final dur = song.duration?.inSeconds ?? 200;
      final url =
          'https://lrclib.net/api/get?artist_name=$artist&track_name=$title&duration=$dur';

      final response = await _dio.get<dynamic>(url);
      if (response.statusCode == 200 && response.data is Map) {
        data = Map<String, dynamic>.from(response.data as Map);
      }
    } catch (_) {}

    // B. Search query fallback (title + artist)
    if (data == null ||
        ((data['syncedLyrics'] == null || (data['syncedLyrics'] as String).trim().isEmpty) &&
         (data['plainLyrics'] == null || (data['plainLyrics'] as String).trim().isEmpty))) {
      try {
        final query = Uri.encodeComponent('$queryTitle ${song.artistNames}'.trim());
        final searchUrl = 'https://lrclib.net/api/search?q=$query';
        final response = await _dio.get<dynamic>(searchUrl);
        if (response.statusCode == 200 && response.data is List) {
          final candidate = _pickBestLyrics(response.data as List);
          if (candidate != null) data = candidate;
        }
      } catch (_) {}
    }

    // C. Search query by track name only
    if (data == null ||
        ((data['syncedLyrics'] == null || (data['syncedLyrics'] as String).trim().isEmpty) &&
         (data['plainLyrics'] == null || (data['plainLyrics'] as String).trim().isEmpty))) {
      try {
        final query = Uri.encodeComponent(queryTitle);
        final searchUrl = 'https://lrclib.net/api/search?q=$query';
        final response = await _dio.get<dynamic>(searchUrl);
        if (response.statusCode == 200 && response.data is List) {
          final candidate = _pickBestLyrics(response.data as List);
          if (candidate != null) data = candidate;
        }
      } catch (_) {}
    }

    // D. Final fallback: If queryTitle contains a hyphen/dash, search with first segment only
    if (data == null && queryTitle.contains(RegExp(r'[-–—]'))) {
      try {
        final shortTitle = queryTitle.split(RegExp(r'[-–—]')).first.trim();
        if (shortTitle.isNotEmpty && shortTitle != queryTitle) {
          final query = Uri.encodeComponent(shortTitle);
          final searchUrl = 'https://lrclib.net/api/search?q=$query';
          final response = await _dio.get<dynamic>(searchUrl);
          if (response.statusCode == 200 && response.data is List) {
            final candidate = _pickBestLyrics(response.data as List);
            if (candidate != null) data = candidate;
          }
        }
      } catch (_) {}
    }

    if (data == null) return null;

    final syncedStr = data['syncedLyrics']?.toString();
    final plainStr = data['plainLyrics']?.toString();

    List<LyricLine> syncedLines = [];
    if (syncedStr != null && syncedStr.trim().isNotEmpty) {
      syncedLines = parseLrc(syncedStr);
    }

    final hasSynced = syncedLines.isNotEmpty;
    final plain = plainStr?.trim() ??
        (hasSynced ? syncedLines.map((l) => l.text).join('\n') : null);

    if (!hasSynced && (plain == null || plain.isEmpty)) {
      return null;
    }

    final lyrics = SongLyrics(
      songId: song.id,
      syncedLines: syncedLines,
      plainLyrics: plain,
      isSynced: hasSynced,
    );

    // Save to offline cache
    try {
      final cache = await _getCacheDirectory();
      final cacheFile = File('${cache.path}/${song.id}.json');
      await cacheFile.writeAsString(jsonEncode(lyrics.toJson()));
      _log.info('cached lyrics offline for ${song.title}');
    } catch (e) {
      _log.warning('failed writing lyrics cache: $e');
    }

    return lyrics;
  }
}
