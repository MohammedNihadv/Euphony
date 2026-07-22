import 'dart:async';
import 'dart:math' as math;

import 'failure.dart';
import 'log.dart';
import 'result.dart';

final _log = logFor('retry');

/// Retries [body] with exponential back-off, capped at [maxAttempts].
///
/// Harmony retried failed InnerTube calls by calling itself again with no cap
/// and no delay, which turned one bad response into a recursion storm. This is
/// the bounded replacement: attempts are counted, delays grow, and a failure
/// the [Failure.isRetryable] check rejects (a parse error, a 404) fails fast.
Future<Result<T>> retry<T>(
  Future<Result<T>> Function() body, {
  int maxAttempts = 3,
  Duration initialDelay = const Duration(milliseconds: 300),
  double multiplier = 2.0,
  Duration maxDelay = const Duration(seconds: 8),
  bool Function(Failure failure)? retryIf,
}) async {
  assert(maxAttempts > 0, 'maxAttempts must be positive');
  final shouldRetry = retryIf ?? (failure) => failure.isRetryable;

  var delay = initialDelay;
  for (var attempt = 1; ; attempt++) {
    final result = await body();
    if (result case Ok<T>()) return result;

    final failure = (result as Err<T>).failure;
    if (attempt >= maxAttempts || !shouldRetry(failure)) {
      if (attempt > 1) {
        _log.warning('giving up after $attempt attempts: $failure');
      }
      return result;
    }

    _log.fine('attempt $attempt failed ($failure), retrying in $delay');
    await Future<void>.delayed(delay);
    delay = Duration(
      milliseconds: math.min(
        (delay.inMilliseconds * multiplier).round(),
        maxDelay.inMilliseconds,
      ),
    );
  }
}
