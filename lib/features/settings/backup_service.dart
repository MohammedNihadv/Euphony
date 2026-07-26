import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/log.dart';

final _log = logFor('BackupService');

class BackupService {
  /// Exports the local database to a user-selected location.
  static Future<bool> exportBackup() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      // drift_flutter uses the name provided plus '.sqlite'
      final dbFile = File('${docDir.path}/euphony.sqlite');

      if (!dbFile.existsSync()) {
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

      final docDir = await getApplicationDocumentsDirectory();
      final dbFile = File('${docDir.path}/euphony.sqlite');

      // Copy the backup over the existing DB
      await File(sourcePath).copy(dbFile.path);
      _log.info('Backup imported from $sourcePath');
      return true;
    } catch (e) {
      _log.severe('Import failed: $e');
      return false;
    }
  }
}
