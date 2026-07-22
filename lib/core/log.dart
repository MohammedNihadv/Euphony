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
  });
}
