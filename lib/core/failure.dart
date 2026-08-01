/// Why an operation failed.
///
/// Every layer below `features/` reports errors as a [Failure] rather than a
/// bare exception or a null, so the UI can decide between "retry", "you're
/// offline" and "this is broken, tell the developer".
enum FailureKind {
  /// No connectivity, DNS failure, socket closed.
  network,

  /// Server answered, but with a non-success status.
  http,

  /// Response arrived but did not have the shape we expect — the signal that
  /// YouTube changed something and a parser needs updating.
  parse,

  /// The requested entity does not exist (deleted video, private playlist).
  notFound,

  /// Region-locked, age-gated, or premium-only content.
  unavailable,

  /// Local database or file system problem.
  storage,

  /// Operation was cancelled by the caller.
  cancelled,

  /// Anything not otherwise classified.
  unknown,
}

class Failure implements Exception {
  const Failure(
    this.kind, {
    this.message,
    this.cause,
    this.stackTrace,
    this.statusCode,
  });

  const Failure.network({String? message, Object? cause})
    : this(FailureKind.network, message: message, cause: cause);

  const Failure.http({String? message, Object? cause, int? statusCode})
    : this(
        FailureKind.http,
        message: message,
        cause: cause,
        statusCode: statusCode,
      );

  const Failure.notFound({String? message})
    : this(FailureKind.notFound, message: message);

  const Failure.unavailable({String? message})
    : this(FailureKind.unavailable, message: message);

  const Failure.storage({String? message, Object? cause})
    : this(FailureKind.storage, message: message, cause: cause);

  const Failure.cancelled({String? message})
    : this(FailureKind.cancelled, message: message);

  const Failure.unknown({String? message, Object? cause})
    : this(FailureKind.unknown, message: message, cause: cause);

  final FailureKind kind;
  final String? message;
  final Object? cause;
  final StackTrace? stackTrace;
  final int? statusCode;

  /// Whether retrying the same call could plausibly succeed.
  bool get isRetryable => switch (kind) {
    FailureKind.network => true,
    FailureKind.http => statusCode == null || statusCode! >= 500,
    FailureKind.parse ||
    FailureKind.notFound ||
    FailureKind.unavailable ||
    FailureKind.storage ||
    FailureKind.cancelled ||
    FailureKind.unknown => false,
  };

  /// A user-friendly error message suitable for displaying in the UI.
  String get userMessage {
    switch (kind) {
      case FailureKind.network:
        return 'Network connection failed. Please check your internet.';
      case FailureKind.http:
        return 'Server error (HTTP ${statusCode ?? 'Unknown'}). Please try again later.';
      case FailureKind.notFound:
        return message ?? 'The requested content could not be found.';
      case FailureKind.unavailable:
        return message ?? 'This content is unavailable or region-locked.';
      case FailureKind.parse:
        return 'App requires an update to read this content.';
      default:
        // Exclude raw URLs or JSON dumps from the UI.
        if (message != null && !message!.startsWith('http') && message!.length < 100) {
          return message!;
        }
        return 'Something went wrong. Please try again.';
    }
  }

  @override
  String toString() {
    final buffer = StringBuffer('Failure(${kind.name}');
    if (statusCode != null) buffer.write(' $statusCode');
    if (message != null) buffer.write(': $message');
    if (cause != null) buffer.write(' <- $cause');
    buffer.write(')');
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          kind == other.kind &&
          message == other.message &&
          statusCode == other.statusCode;

  @override
  int get hashCode => Object.hash(kind, message, statusCode);
}

/// A [Failure] carrying the JSON path that could not be resolved.
///
/// Harmony's `nav()` swallowed every miss; Euphony records the exact path so a
/// broken parser names itself in the logs and in golden tests.
class ParseFailure extends Failure {
  const ParseFailure(this.path, {String? message, Object? cause})
    : super(FailureKind.parse, message: message, cause: cause);

  /// The navigation path that failed, e.g. `contents.sectionListRenderer`.
  final String path;

  @override
  String toString() =>
      'ParseFailure($path${message == null ? '' : ': $message'})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParseFailure && path == other.path && message == other.message;

  @override
  int get hashCode => Object.hash(FailureKind.parse, path, message);
}
