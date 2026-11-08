import 'dart:io';

import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/log.dart';
import '../../data/db/database.dart';

final _log = logFor('BackupService');

/// Metadata for a backup detected on the local filesystem.
class DetectedBackup {
  const DetectedBackup({
    required this.file,
    required this.fileName,
    required this.directoryPath,
    required this.likedSongsCount,
    required this.searchHistoryCount,
    required this.savedPlaylistsCount,
    required this.fileSizeBytes,
    required this.modifiedAt,
  });

  final File file;
  final String fileName;
  final String directoryPath;
  final int likedSongsCount;
  final int searchHistoryCount;
  final int savedPlaylistsCount;
  final int fileSizeBytes;
  final DateTime modifiedAt;

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get summary {
    final parts = <String>[];
    if (likedSongsCount > 0) parts.add('$likedSongsCount songs');
    if (searchHistoryCount > 0) parts.add('$searchHistoryCount searches');
    if (savedPlaylistsCount > 0) parts.add('$savedPlaylistsCount playlists');
    return parts.isEmpty ? 'Empty database' : parts.join(' • ');
  }
}

/// The outcome of a database restore operation.
class RestoreResult {
  const RestoreResult({
    required this.success,
    this.songsCount = 0,
    this.historyCount = 0,
    this.playlistsCount = 0,
    this.albumsCount = 0,
    this.errorMessage,
  });

  final bool success;
  final int songsCount;
  final int historyCount;
  final int playlistsCount;
  final int albumsCount;
  final String? errorMessage;

  String get message {
    if (!success) return errorMessage ?? 'Restore failed';
    final parts = <String>[];
    if (songsCount > 0) parts.add('$songsCount liked songs');
    if (historyCount > 0) parts.add('$historyCount search queries');
    if (playlistsCount > 0) parts.add('$playlistsCount playlists');
    return parts.isEmpty
        ? 'Backup restored successfully!'
        : 'Restored ${parts.join(', ')}!';
  }
}

class BackupService {
  /// Finds the active Drift database file.
  static Future<File?> _locateDatabase() async {
    final candidates = <Directory>[
      await getApplicationDocumentsDirectory(),
      await getApplicationSupportDirectory(),
    ];
    for (final dir in candidates) {
      final file = File('${dir.path}/euphony.sqlite');
      if (file.existsSync()) return file;
    }
    return null;
  }

  /// Exports the local database and preserves an auto-detected copy in Documents/Euphony.
  static Future<bool> exportBackup() async {
    try {
      final dbFile = await _locateDatabase();

      if (dbFile == null) {
        _log.warning('No database found to backup.');
        return false;
      }

      final bytes = await dbFile.readAsBytes();

      // Automatically maintain a copy in Documents/Euphony/euphony_backup.sqlite
      // so it is immediately detected by the auto-detection scanner.
      try {
        final docDir = await getApplicationDocumentsDirectory();
        final autoDir = Directory('${docDir.path}/Euphony');
        if (!autoDir.existsSync()) {
          autoDir.createSync(recursive: true);
        }
        final autoFile = File('${autoDir.path}/euphony_backup.sqlite');
        await autoFile.writeAsBytes(bytes, flush: true);
        _log.info('Auto-backup written to ${autoFile.path}');
      } catch (e) {
        _log.warning('Could not write auto-backup copy: $e');
      }

      final destPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Euphony Backup',
        fileName: 'euphony_backup.sqlite',
        type: FileType.any,
        bytes: bytes,
      );

      if (destPath == null) return true; // Auto-backup was already saved!

      if (destPath.isNotEmpty) {
        try {
          await dbFile.copy(destPath);
        } catch (_) {}
      }
      _log.info('Backup exported to $destPath');
      return true;
    } catch (e) {
      _log.severe('Export failed: $e');
      return false;
    }
  }

  /// Checks whether [file] starts with the standard SQLite 3 database header.
  static bool _isSqliteHeader(File file) {
    try {
      if (file.lengthSync() < 100) return false;
      final raf = file.openSync(mode: FileMode.read);
      try {
        final header = raf.readSync(16);
        final magic = String.fromCharCodes(header.take(15));
        return magic == 'SQLite format 3';
      } finally {
        raf.closeSync();
      }
    } catch (_) {
      return false;
    }
  }

  /// Automatically scans common directories on the device for Euphony backup files.
  static Future<List<DetectedBackup>> detectBackups([EuphonyDatabase? db]) async {
    final results = <DetectedBackup>[];
    final checkedPaths = <String>{};
    final candidateDirs = <Directory>[];

    // Documents
    try {
      final docDir = await getApplicationDocumentsDirectory();
      candidateDirs.add(docDir);
      candidateDirs.add(Directory('${docDir.path}/Euphony'));
    } catch (_) {}

    // Support
    try {
      final supDir = await getApplicationSupportDirectory();
      candidateDirs.add(supDir);
      candidateDirs.add(Directory('${supDir.path}/Euphony'));
    } catch (_) {}

    // Downloads
    try {
      final dlDir = await getDownloadsDirectory();
      if (dlDir != null) {
        candidateDirs.add(dlDir);
        candidateDirs.add(Directory('${dlDir.path}/Telegram Desktop'));
      }
    } catch (_) {}

    // Android standard external storage paths
    if (Platform.isAndroid) {
      for (final p in [
        '/storage/emulated/0/Download',
        '/storage/emulated/0/Download/Telegram',
        '/storage/emulated/0/Documents',
        '/storage/emulated/0/Documents/Euphony',
        '/storage/emulated/0/Music',
      ]) {
        candidateDirs.add(Directory(p));
      }
    }

    // Windows standard external directories
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        candidateDirs.add(Directory('$userProfile/Documents/Euphony'));
        candidateDirs.add(Directory('$userProfile/Documents'));
        candidateDirs.add(Directory('$userProfile/Downloads'));
        candidateDirs.add(Directory('$userProfile/Downloads/Telegram Desktop'));
      }
    }

    for (final dir in candidateDirs) {
      if (!dir.existsSync()) continue;
      try {
        final entries = dir.listSync();
        for (final entry in entries) {
          if (entry is! File) continue;
          final normPath = entry.path.replaceAll('\\', '/');
          if (checkedPaths.contains(normPath)) continue;
          checkedPaths.add(normPath);

          final nameLower = entry.uri.pathSegments.last.toLowerCase();
          // Skip the live database
          if (nameLower == 'euphony.sqlite') continue;

          // Check if it looks like a backup or sqlite file
          final isCandidate = nameLower.contains('backup') ||
              nameLower.endsWith('.sqlite') ||
              nameLower.endsWith('.db') ||
              nameLower.startsWith('euphony');

          if (!isCandidate) continue;
          if (!_isSqliteHeader(entry)) continue;

          int songs = 0;
          int history = 0;
          int playlists = 0;

          if (db != null) {
            final cleanPath = entry.path.replaceAll('\\', '/').replaceAll("'", "''");
            try {
              await db.customStatement('DETACH DATABASE probe_db;');
            } catch (_) {}

            try {
              await db.customStatement("ATTACH DATABASE '$cleanPath' AS probe_db;");
              try {
                final r = await db.customSelect('SELECT COUNT(*) AS c FROM probe_db.liked_songs;').getSingleOrNull();
                songs = r?.read<int>('c') ?? 0;
              } catch (_) {}
              try {
                final r = await db.customSelect('SELECT COUNT(*) AS c FROM probe_db.search_history;').getSingleOrNull();
                history = r?.read<int>('c') ?? 0;
              } catch (_) {}
              try {
                final r = await db.customSelect('SELECT COUNT(*) AS c FROM probe_db.saved_playlists;').getSingleOrNull();
                playlists = r?.read<int>('c') ?? 0;
              } catch (_) {}
              await db.customStatement('DETACH DATABASE probe_db;');
            } catch (_) {
              try {
                await db.customStatement('DETACH DATABASE probe_db;');
              } catch (_) {}
            }
          }

          final stat = entry.statSync();
          results.add(
            DetectedBackup(
              file: entry,
              fileName: entry.uri.pathSegments.last,
              directoryPath: dir.path,
              likedSongsCount: songs,
              searchHistoryCount: history,
              savedPlaylistsCount: playlists,
              fileSizeBytes: stat.size,
              modifiedAt: stat.modified,
            ),
          );
        }
      } catch (_) {}
    }

    results.sort((a, b) => b.modifiedAt.compareTo(a.modifiedAt));
    return results;
  }

  /// Restores data from [backupFile] into the active [EuphonyDatabase] using SQLite ATTACH.
  ///
  /// This seamlessly merges records without locking or corrupting open file handles,
  /// and updates Drift streams in real time with no app restart required.
  static Future<RestoreResult> restoreDatabase(
    File backupFile,
    EuphonyDatabase db,
  ) async {
    final cleanPath = backupFile.path.replaceAll('\\', '/').replaceAll("'", "''");
    try {
      try {
        await db.customStatement('DETACH DATABASE backup_db;');
      } catch (_) {}

      await db.customStatement("ATTACH DATABASE '$cleanPath' AS backup_db;");

      int songsRestored = 0;
      int historyRestored = 0;
      int playlistsRestored = 0;
      int albumsRestored = 0;

      // 1. Liked songs
      try {
        final r = await db.customSelect('SELECT COUNT(*) AS c FROM backup_db.liked_songs;').getSingleOrNull();
        songsRestored = r?.read<int>('c') ?? 0;
        await db.customStatement(
          'INSERT OR REPLACE INTO liked_songs (id, title, artists, album_title, artwork_url, duration_seconds, is_explicit, liked_at) '
          'SELECT id, title, artists, album_title, artwork_url, duration_seconds, is_explicit, liked_at FROM backup_db.liked_songs;',
        );
      } catch (e) {
        _log.warning('Could not merge liked_songs from backup: $e');
      }

      // 2. Search history
      try {
        final r = await db.customSelect('SELECT COUNT(*) AS c FROM backup_db.search_history;').getSingleOrNull();
        historyRestored = r?.read<int>('c') ?? 0;
        await db.customStatement(
          'INSERT OR REPLACE INTO search_history (query, last_used_at) '
          'SELECT query, last_used_at FROM backup_db.search_history;',
        );
      } catch (e) {
        _log.warning('Could not merge search_history from backup: $e');
      }

      // 3. Saved albums
      try {
        final r = await db.customSelect('SELECT COUNT(*) AS c FROM backup_db.saved_albums;').getSingleOrNull();
        albumsRestored = r?.read<int>('c') ?? 0;
        await db.customStatement(
          'INSERT OR REPLACE INTO saved_albums (browse_id, title, artists, artwork_url, year, saved_at) '
          'SELECT browse_id, title, artists, artwork_url, year, saved_at FROM backup_db.saved_albums;',
        );
      } catch (e) {
        _log.warning('Could not merge saved_albums from backup: $e');
      }

      // 4. Saved playlists
      try {
        final r = await db.customSelect('SELECT COUNT(*) AS c FROM backup_db.saved_playlists;').getSingleOrNull();
        playlistsRestored = r?.read<int>('c') ?? 0;
        await db.customStatement(
          'INSERT OR REPLACE INTO saved_playlists (id, title, author, artwork_url, track_count, saved_at) '
          'SELECT id, title, author, artwork_url, track_count, saved_at FROM backup_db.saved_playlists;',
        );
      } catch (e) {
        _log.warning('Could not merge saved_playlists from backup: $e');
      }

      await db.customStatement('DETACH DATABASE backup_db;');

      // Notify all active Drift tables so all Riverpod providers and UI streams re-render instantly!
      db.notifyUpdates({
        TableUpdate.onTable(db.likedSongs),
        TableUpdate.onTable(db.searchHistory),
        TableUpdate.onTable(db.savedAlbums),
        TableUpdate.onTable(db.savedPlaylists),
      });

      return RestoreResult(
        success: true,
        songsCount: songsRestored,
        historyCount: historyRestored,
        playlistsCount: playlistsRestored,
        albumsCount: albumsRestored,
      );
    } catch (e, st) {
      _log.severe('Restore error: $e', e, st);
      try {
        await db.customStatement('DETACH DATABASE backup_db;');
      } catch (_) {}
      return RestoreResult(success: false, errorMessage: e.toString());
    }
  }

  /// Prompts the user to pick any backup file manually and restores it directly.
  static Future<RestoreResult> importFromPicker(EuphonyDatabase db) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Euphony Backup File',
        type: FileType.any,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return const RestoreResult(success: false, errorMessage: 'Import cancelled');
      }

      final picked = result.files.single;
      File tempFile;
      if (picked.path != null && File(picked.path!).existsSync()) {
        tempFile = File(picked.path!);
      } else if (picked.bytes != null) {
        final tempDir = await getTemporaryDirectory();
        tempFile = File('${tempDir.path}/temp_restore_${DateTime.now().millisecondsSinceEpoch}.sqlite');
        await tempFile.writeAsBytes(picked.bytes!, flush: true);
      } else {
        return const RestoreResult(success: false, errorMessage: 'File could not be read');
      }

      return restoreDatabase(tempFile, db);
    } catch (e) {
      _log.severe('Pick and restore failed: $e');
      return RestoreResult(success: false, errorMessage: e.toString());
    }
  }
}
