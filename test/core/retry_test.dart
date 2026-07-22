import 'package:euphony/core/failure.dart';
import 'package:euphony/core/result.dart';
import 'package:euphony/core/retry.dart';
import 'package:flutter_test/flutter_test.dart';

const _noDelay = Duration.zero;

void main() {
  test('returns immediately on success without retrying', () async {
    var calls = 0;
    final result = await retry(() async {
      calls++;
      return const Result<int>.ok(1);
    }, initialDelay: _noDelay);

    expect(result.valueOrNull, 1);
    expect(calls, 1);
  });

  test('retries a retryable failure up to maxAttempts', () async {
    var calls = 0;
    final result = await retry<int>(
      () async {
        calls++;
        return const Result<int>.err(Failure.network());
      },
      maxAttempts: 3,
      initialDelay: _noDelay,
    );

    expect(result.isErr, isTrue);
    expect(calls, 3);
  });

  test('stops as soon as an attempt succeeds', () async {
    var calls = 0;
    final result = await retry<int>(() async {
      calls++;
      return calls < 2
          ? const Result<int>.err(Failure.network())
          : const Result<int>.ok(9);
    }, initialDelay: _noDelay);

    expect(result.valueOrNull, 9);
    expect(calls, 2);
  });

  test('does not retry a non-retryable failure', () async {
    var calls = 0;
    final result = await retry<int>(
      () async {
        calls++;
        return const Result<int>.err(ParseFailure('contents'));
      },
      maxAttempts: 5,
      initialDelay: _noDelay,
    );

    expect(result.isErr, isTrue);
    expect(calls, 1, reason: 'a parse error will not fix itself');
  });

  test('honours a custom retryIf predicate', () async {
    var calls = 0;
    await retry<int>(
      () async {
        calls++;
        return const Result<int>.err(ParseFailure('contents'));
      },
      maxAttempts: 3,
      initialDelay: _noDelay,
      retryIf: (_) => true,
    );

    expect(calls, 3);
  });

  test('back-off grows but stays under maxDelay', () async {
    final started = DateTime.now();
    await retry<int>(
      () async => const Result<int>.err(Failure.network()),
      maxAttempts: 3,
      initialDelay: const Duration(milliseconds: 10),
      maxDelay: const Duration(milliseconds: 15),
    );
    final elapsed = DateTime.now().difference(started);

    // 10ms + 15ms of waiting, plus scheduling slack.
    expect(elapsed, greaterThanOrEqualTo(const Duration(milliseconds: 25)));
    expect(elapsed, lessThan(const Duration(seconds: 2)));
  });
}
