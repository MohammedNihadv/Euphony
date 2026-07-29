import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/log.dart';

final _log = logFor('BackupService');

class BackupService {
  /// Finds the Drift database file.
  ///
  /// drift_flutter stores `euphony.sqlite`, but *which* directory depends on
  /// the platform and package version (documents vs application-support). The
  /// old code only checked the documents dir, so on any build where Drift chose
  /// support, export failed with "no database found". This checks the known
  /// locations and returns the first that exists.
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

  /// The directory Drift's database lives in, for writing an imported copy
  /// back to the right place.
  static Future<File> _databaseTarget() async {
    final existing = await _locateDatabase();
    if (existing != null) return existing;
    // No DB yet: default to the documents dir, matching drift_flutter's default.
    final docDir = await getApplicationDocumentsDirectory();
    return File('${docDir.path}/euphony.sqlite');
  }

  /// Exports the local database to a user-selected location.
  static Future<bool> exportBackup() async {
    try {
      final dbFile = await _locateDatabase();

      if (dbFile == null) {
        _log.warning('No database found to backup.');
        return false;
      }

      final destPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Euphony Backup',
        fileName: 'euphony_backup.sqlite',
        type: FileType.any,
      );

      if (destPath == null) return false; // User canceled

      await dbFile.copy(destPath);
      _log.info('Backup exported to $destPath');
      return true;
    } catch (e) {
      _log.severe('Export failed: $e');
      return false;
    }
  }

  /// Restores the local database from a user-selected backup file.
  static Future<bool> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Euphony Backup',
        type: FileType.any,
      );

      if (result == null || result.files.isEmpty) return false;

      final sourcePath = result.files.single.path;
      if (sourcePath == null) return false;

      final dbFile = await _databaseTarget();

      // Copy the backup over the existing DB, in whichever directory Drift uses.
      await File(sourcePath).copy(dbFile.path);
      _log.info('Backup imported from $sourcePath');
      return true;
    } catch (e) {
      _log.severe('Import failed: $e');
      return false;
    }
  }
}
