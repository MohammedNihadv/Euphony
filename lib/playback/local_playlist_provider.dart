import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/providers.dart';
import '../domain/artist_ref.dart';
import '../domain/song.dart';

class LocalPlaylistNotifier extends Notifier<Map<String, List<Song>>> {
  static const _storageKey = 'euphony_local_playlist_tracks';

  @override
  Map<String, List<Song>> build() {
    return _loadFromPrefs();
  }

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  Map<String, List<Song>> _loadFromPrefs() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final map = <String, List<Song>>{};
      decoded.forEach((playlistId, tracksRaw) {
        if (tracksRaw is List) {
          map[playlistId] = tracksRaw
              .whereType<Map<String, dynamic>>()
              .map((json) => _songFromJson(json))
              .whereType<Song>()
              .toList();
        }
      });
      return map;
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveToPrefs() async {
    final jsonMap = <String, dynamic>{};
    state.forEach((playlistId, songs) {
      jsonMap[playlistId] = songs.map((s) => _songToJson(s)).toList();
    });
    await _prefs.setString(_storageKey, jsonEncode(jsonMap));
  }

  List<Song> getPlaylistTracks(String playlistId) {
    return state[playlistId] ?? const [];
  }

  Future<void> addSongToPlaylist(String playlistId, Song song) async {
    final current = state[playlistId] ?? [];
    if (current.any((s) => s.id == song.id)) return; // Avoid duplicate entries
    final updated = [...current, song];
    state = {...state, playlistId: updated};
    await _saveToPrefs();
  }

  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final current = state[playlistId] ?? [];
    final updated = current.where((s) => s.id != songId).toList();
    state = {...state, playlistId: updated};
    await _saveToPrefs();
  }

  Map<String, dynamic> _songToJson(Song song) => {
        'id': song.id,
        'title': song.title,
        'artistNames': song.artistNames,
        'albumTitle': song.albumTitle,
        'artworkUrl': song.artworkUrl,
        'durationSeconds': song.duration?.inSeconds,
      };

  Song? _songFromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final title = json['title'] as String?;
    if (id == null || title == null) return null;
    final durSec = json['durationSeconds'] as int?;
    final artistName = json['artistNames'] as String? ?? 'Unknown Artist';
    return Song(
      id: id,
      title: title,
      artists: [ArtistRef(name: artistName)],
      albumTitle: json['albumTitle'] as String?,
      artworkUrl: json['artworkUrl'] as String?,
      duration: durSec != null ? Duration(seconds: durSec) : null,
    );
  }
}

final localPlaylistTracksProvider =
    NotifierProvider<LocalPlaylistNotifier, Map<String, List<Song>>>(
  LocalPlaylistNotifier.new,
);
