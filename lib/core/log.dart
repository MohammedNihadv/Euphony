import 'dart:developer' as developer;

import 'package:logging/logging.dart';

/// Creates a logger for [name], conventionally the class or file using it.
Logger logFor(String name) => Logger(name);

/// True in a release build.
///
/// Read from the environment rather than `kReleaseMode` so that `core/`,
/// `data/` and `domain/` stay free of any Flutter import — that is what lets
/// the fixture-capture tool and the parser tests run on the plain Dart VM.
const bool isReleaseBuild = bool.fromEnvironment('dart.vm.product');

/// Ring buffer storing recent log entries (up to 500 entries) for user export.
final List<String> _logHistory = [];
const int _maxLogHistory = 500;

/// Returns the captured log history for downloading/exporting.
List<String> getLogHistory() => List.unmodifiable(_logHistory);

/// Clears captured log history.
void clearLogHistory() => _logHistory.clear();

/// Wires the `logging` package into the platform log.
///
/// In release builds only warnings and above are recorded, so a broken parser
/// still leaves a trace without shipping a debug firehose.
void initLogging({Level? level}) {
  Logger.root.level = level ?? (isReleaseBuild ? Level.WARNING : Level.ALL);
  Logger.root.onRecord.listen((record) {
    developer.log(
      record.message,
      time: record.time,
      level: record.level.value,
      name: record.loggerName,
      error: record.error,
      stackTrace: record.stackTrace,
    );

    final entry = StringBuffer(
      '[${record.time.toIso8601String()}] [${record.level.name}] ${record.loggerName}: ${record.message}',
    );
    if (record.error != null) {
      entry.write('\n  Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      entry.write('\n  Stack: ${record.stackTrace}');
    }
    _logHistory.add(entry.toString());
    if (_logHistory.length > _maxLogHistory) {
      _logHistory.removeAt(0);
    }

    // `developer.log` is a no-op on unattached release builds.
    // Mirror warnings and severe errors to stdout so Android logcat captures
    // production logs cleanly.
    if (record.level >= Level.WARNING) {
      // ignore: avoid_print
      print('[${record.level.name}] ${record.loggerName}: ${record.message}');
      if (record.error != null) {
        // ignore: avoid_print
        print('  error: ${record.error}');
      }
      if (record.stackTrace != null) {
        // ignore: avoid_print
        print('  stack: ${record.stackTrace}');
      }
    }
  });
}
