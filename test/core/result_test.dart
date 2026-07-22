import 'package:euphony/core/failure.dart';
import 'package:euphony/core/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('Ok carries its value', () {
      const result = Result<int>.ok(7);
      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
      expect(result.valueOrNull, 7);
      expect(result.failureOrNull, isNull);
      expect(result.unwrap(), 7);
    });

    test('Err carries its failure and does not unwrap', () {
      const failure = Failure.notFound(message: 'gone');
      const result = Result<int>.err(failure);
      expect(result.isErr, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, failure);
      expect(result.valueOr(3), 3);
      expect(result.unwrap, throwsA(failure));
    });

    test('map transforms Ok and passes Err through', () {
      expect(const Result<int>.ok(2).map((v) => v * 2).valueOrNull, 4);

      const failure = Failure.network();
      final mapped = const Result<int>.err(failure).map((v) => v * 2);
      expect(mapped.failureOrNull, failure);
    });

    test('flatMap chains', () {
      final chained = const Result<int>.ok(
        2,
      ).flatMap((v) => Result<String>.ok('$v'));
      expect(chained.valueOrNull, '2');
    });

    test('fold picks the matching branch', () {
      expect(const Result<int>.ok(1).fold((v) => 'ok', (f) => 'err'), 'ok');
      expect(
        const Result<int>.err(
          Failure.network(),
        ).fold((v) => 'ok', (f) => 'err'),
        'err',
      );
    });
  });

  group('guard', () {
    test('wraps a returned value in Ok', () async {
      final result = await guard(() async => 42);
      expect(result.valueOrNull, 42);
    });

    test('converts a thrown Failure into Err unchanged', () async {
      const failure = Failure.storage(message: 'disk full');
      final result = await guard<int>(() async => throw failure);
      expect(result.failureOrNull, failure);
    });

    test('converts an arbitrary throw into an unknown Failure', () async {
      final result = await guard<int>(() async => throw StateError('boom'));
      expect(result.failureOrNull?.kind, FailureKind.unknown);
    });
  });

  group('Failure.isRetryable', () {
    test('network failures are retryable', () {
      expect(const Failure.network().isRetryable, isTrue);
    });

    test('5xx is retryable, 4xx is not', () {
      expect(const Failure.http(statusCode: 503).isRetryable, isTrue);
      expect(const Failure.http(statusCode: 404).isRetryable, isFalse);
    });

    test('parse failures are not retryable', () {
      expect(const ParseFailure('contents.tabs').isRetryable, isFalse);
    });
  });

  test('ParseFailure names the path it could not resolve', () {
    const failure = ParseFailure('contents.sectionListRenderer');
    expect(failure.toString(), contains('contents.sectionListRenderer'));
  });
}
