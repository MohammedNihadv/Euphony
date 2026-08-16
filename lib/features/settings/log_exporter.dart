import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/log.dart';

final _log = logFor('LogExporter');

class LogExporter {
  /// Compiles system metadata and captured runtime log history into a `.txt`
  /// file and prompts the user to download/save it.
  static Future<bool> exportLogs() async {
    try {
      PackageInfo? info;
      try {
        info = await PackageInfo.fromPlatform();
      } catch (_) {}

      final appVersion = info != null
          ? '${info.version}+${info.buildNumber}'
          : '0.2.2+4';
      final packageName = info?.packageName ?? 'com.mhdni.euphony';

      final buffer = StringBuffer();
      buffer.writeln('====================================================');
      buffer.writeln('          EUPHONY ERROR LOG EXPORT');
      buffer.writeln('====================================================');
      buffer.writeln('App Version: $appVersion');
      buffer.writeln('Package:     $packageName');
      buffer.writeln('Platform:    ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
      buffer.writeln('Export Time: ${DateTime.now().toIso8601String()}');
      buffer.writeln('====================================================\n');

      final logs = getLogHistory();
      if (logs.isEmpty) {
        buffer.writeln('No log entries recorded in this session.');
      } else {
        buffer.writeln('--- RECENT LOG MESSAGES (${logs.length} entries) ---\n');
        for (final entry in logs) {
          buffer.writeln(entry);
          buffer.writeln('---');
        }
      }

      final bytes = utf8.encode(buffer.toString());
      final now = DateTime.now();
      final timestampStr =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_'
          '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
      final fileName = 'euphony_error_logs_$timestampStr.txt';

      final destPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Euphony Error Logs',
        fileName: fileName,
        type: FileType.any,
        bytes: bytes,
      );

      if (destPath == null) return false;

      final tempDir = await Directory.systemTemp.createTemp('euphony_logs');
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(bytes, flush: true);

      if (destPath.startsWith('content://')) {
        final plugin = const MethodChannel('com.mhdni.euphony/export');
        await plugin.invokeMethod('writeToContentUri', {
          'uri': destPath,
          'sourcePath': tempFile.path,
        });
      } else {
        if (destPath.isNotEmpty) {
          try {
            await tempFile.copy(destPath);
          } catch (_) {
            // bytes may have already been written by saveFile
          }
        }
      }

      try {
        await tempFile.delete();
      } catch (_) {}

      _log.info('Logs exported to $destPath');
      return true;
    } catch (e, st) {
      _log.severe('Log export failed: $e\n$st');
      return false;
    }
  }
}
