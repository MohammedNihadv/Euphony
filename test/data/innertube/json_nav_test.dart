import 'package:euphony/core/failure.dart';
import 'package:euphony/data/remote/innertube/json_nav.dart';
import 'package:test/test.dart';

void main() {
  const response = <String, dynamic>{
    'contents': {
      'tabs': [
        {
          'tabRenderer': {'title': 'Home', 'index': 0},
        },
      ],
      'count': 3,
    },
  };

  group('nav', () {
    test('resolves a path of keys and indices', () {
      final result = nav<String>(
        response,
        const JsonPath(['contents', 'tabs', 0, 'tabRenderer', 'title']),
      );
      expect(result.valueOrNull, 'Home');
    });

    test('names the exact path that broke, not just "something failed"', () {
      final result = nav<String>(
        response,
        const JsonPath(['contents', 'tabs', 0, 'shelfRenderer', 'title']),
      );

      final failure = result.failureOrNull;
      expect(failure, isA<ParseFailure>());
      expect(
        (failure! as ParseFailure).path,
        'contents.tabs[0].shelfRenderer',
        reason: 'this string is what makes a broken parser findable',
      );
    });

    test('lists the sibling keys that were there instead', () {
      final result = nav<String>(
        response,
        const JsonPath(['contents', 'tabs', 0, 'shelfRenderer']),
      );
      expect(result.failureOrNull.toString(), contains('tabRenderer'));
    });

    test('reports an index past the end of a list', () {
      final result = nav<Object>(
        response,
        const JsonPath(['contents', 'tabs', 7]),
      );
      expect(result.failureOrNull.toString(), contains('out of range'));
      expect(result.failureOrNull.toString(), contains('length 1'));
    });

    test('reports a type mismatch rather than throwing', () {
      final result = nav<String>(
        response,
        const JsonPath(['contents', 'count']),
      );
      expect(result.isErr, isTrue);
      expect(result.failureOrNull.toString(), contains('expected String'));
    });

    test('reports indexing a map and keying a list', () {
      expect(
        nav<Object>(
          response,
          const JsonPath(['contents', 0]),
        ).failureOrNull.toString(),
        contains('cannot apply index'),
      );
      expect(
        nav<Object>(
          response,
          const JsonPath(['contents', 'tabs', 'first']),
        ).failureOrNull.toString(),
        contains('cannot apply key'),
      );
    });

    test('an empty path returns the root', () {
      expect(
        nav<Map<String, dynamic>>(response, const JsonPath([])).valueOrNull,
        same(response),
      );
    });
  });

  group('navOrNull', () {
    test('returns the value when present', () {
      expect(
        navOrNull<int>(response, const JsonPath(['contents', 'count'])),
        3,
      );
    });

    test('returns null for a genuinely optional field', () {
      expect(
        navOrNull<String>(response, const JsonPath(['contents', 'absent'])),
        isNull,
      );
    });
  });

  group('navAny', () {
    test('takes the first path that resolves', () {
      final result = navAny<String>(response, const [
        JsonPath(['contents', 'header', 'title']),
        JsonPath(['contents', 'tabs', 0, 'tabRenderer', 'title']),
      ]);
      expect(result.valueOrNull, 'Home');
    });

    test('reports every path it tried when none match', () {
      final result = navAny<String>(response, const [
        JsonPath(['a']),
        JsonPath(['b', 'c']),
      ]);
      final message = result.failureOrNull.toString();
      expect(message, contains('a'));
      expect(message, contains('b.c'));
      expect(message, contains('none of 2 paths'));
    });
  });

  group('JsonPath', () {
    test('renders keys with dots and indices with brackets', () {
      expect(
        const JsonPath(['contents', 'tabs', 0, 'title']).render(),
        'contents.tabs[0].title',
      );
    });

    test('concatenates', () {
      const base = JsonPath(['contents', 'tabs']);
      expect((base + [0, 'title']).render(), 'contents.tabs[0].title');
    });
  });
}
