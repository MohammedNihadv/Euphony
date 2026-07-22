import '../../../core/failure.dart';
import '../../../core/result.dart';

/// Walks a decoded InnerTube response along a path of map keys and list
/// indices.
///
/// Harmony's `nav()` wrapped the whole walk in `try { … } catch (e) { return
/// null; }` (developer guide 16.1). When YouTube renamed a renderer, every
/// caller got `null`, the UI drew an empty list, and nothing anywhere said
/// which key had moved — the bug took 23 duplicate issue reports to pin down.
///
/// Here a miss is a [ParseFailure] naming the exact prefix that resolved and
/// the step that did not, so a broken parser identifies itself in one log line
/// and in one failing golden test.
extension type const JsonPath(List<Object> steps) {
  /// `['contents', 'tabs', 0]` rendered as `contents.tabs[0]`.
  String render([int? upTo]) {
    final buffer = StringBuffer();
    final end = upTo ?? steps.length;
    for (var i = 0; i < end; i++) {
      final step = steps[i];
      if (step is int) {
        buffer.write('[$step]');
      } else {
        if (buffer.isNotEmpty) buffer.write('.');
        buffer.write(step);
      }
    }
    return buffer.toString();
  }

  JsonPath operator +(List<Object> more) => JsonPath([...steps, ...more]);
}

/// Navigates [root] along [path].
///
/// Returns [Err] with a [ParseFailure] if any step is missing or the value at
/// the end is not a [T].
Result<T> nav<T extends Object>(Object? root, JsonPath path) {
  Object? current = root;

  for (var i = 0; i < path.steps.length; i++) {
    final step = path.steps[i];

    if (current == null) {
      return Err(ParseFailure(path.render(i), message: 'null before "$step"'));
    }

    switch ((current, step)) {
      case (final Map<String, dynamic> map, final String key):
        if (!map.containsKey(key)) {
          return Err(
            ParseFailure(
              path.render(i + 1),
              message: 'key absent; siblings: ${_preview(map.keys)}',
            ),
          );
        }
        current = map[key] as Object?;

      case (final List<dynamic> list, final int index):
        if (index < 0 || index >= list.length) {
          return Err(
            ParseFailure(
              path.render(i + 1),
              message: 'index out of range (length ${list.length})',
            ),
          );
        }
        current = list[index] as Object?;

      default:
        return Err(
          ParseFailure(
            path.render(i + 1),
            message:
                'cannot apply ${step is int ? 'index' : 'key'} to '
                '${current.runtimeType}',
          ),
        );
    }
  }

  if (current == null) {
    return Err(ParseFailure(path.render(), message: 'resolved to null'));
  }
  if (current is! T) {
    return Err(
      ParseFailure(
        path.render(),
        message: 'expected $T, got ${current.runtimeType}',
      ),
    );
  }
  return Ok(current);
}

/// [nav] for values that are legitimately optional.
///
/// Use this only where the field's absence is normal (a song with no album, a
/// playlist with no description). Reaching for it to silence a failing path is
/// how Harmony's parsers went quiet.
T? navOrNull<T extends Object>(Object? root, JsonPath path) =>
    nav<T>(root, path).valueOrNull;

/// Tries each path in order and returns the first that resolves.
///
/// YouTube ships more than one renderer shape for the same content; this makes
/// that explicit instead of hiding it behind a chain of `??`.
Result<T> navAny<T extends Object>(Object? root, List<JsonPath> paths) {
  assert(paths.isNotEmpty, 'navAny needs at least one path');
  final tried = <String>[];

  for (final path in paths) {
    final result = nav<T>(root, path);
    if (result case Ok<T>()) return result;
    tried.add(path.render());
  }

  return Err(
    ParseFailure(
      tried.first,
      message:
          'none of ${tried.length} paths matched: '
          '${tried.join(' | ')}',
    ),
  );
}

String _preview(Iterable<String> keys) {
  final shown = keys.take(6).join(', ');
  return keys.length > 6 ? '$shown, …' : shown;
}
