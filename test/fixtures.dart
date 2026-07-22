import 'dart:convert';
import 'dart:io';

/// Loads a captured InnerTube response from `test/fixtures/`.
///
/// The fixtures are real payloads, refreshed with
/// `dart run tool/capture_fixtures.dart`. Tests assert against them so that a
/// change on YouTube's side shows up as a failing test with a named path,
/// rather than as an empty screen in a release build.
Map<String, dynamic> loadFixture(String name) {
  final file = File('test/fixtures/$name.json');
  if (!file.existsSync()) {
    throw StateError(
      'Missing fixture "$name". Run: dart run tool/capture_fixtures.dart $name',
    );
  }
  return json.decode(file.readAsStringSync()) as Map<String, dynamic>;
}
