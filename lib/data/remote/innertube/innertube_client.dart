import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/failure.dart';
import '../../../core/log.dart';
import '../../../core/result.dart';
import '../../../core/retry.dart';
import 'innertube_constants.dart';

final _log = logFor('innertube');

/// Where a visitor id is kept between runs.
///
/// Implemented over shared_preferences in the app and over a plain map in
/// tests, so the client itself has no storage dependency.
abstract interface class VisitorIdStore {
  /// The stored id, or `null` if absent or past its expiry.
  String? read();

  Future<void> write(String id, DateTime expiresAt);
}

/// An in-memory [VisitorIdStore], for tests and for a first run before
/// preferences are available.
class MemoryVisitorIdStore implements VisitorIdStore {
  String? _id;
  DateTime? _expiresAt;

  @override
  String? read() {
    if (_id == null || _expiresAt == null) return null;
    return DateTime.now().isBefore(_expiresAt!) ? _id : null;
  }

  @override
  Future<void> write(String id, DateTime expiresAt) async {
    _id = id;
    _expiresAt = expiresAt;
  }
}

/// The YouTube Music private API client.
///
/// Ported from Harmony's `music_service.dart`, keeping its request context,
/// header set and visitor-id scrape — all of which are load-bearing; YouTube
/// answers differently or not at all without them. What changed:
///
/// * every call returns [Result], never `dynamic`;
/// * non-200 responses go through [retry] with capped exponential back-off
///   instead of Harmony's `_sendRequest` calling itself with no bound;
/// * the client only fetches and decodes — parsing lives in `parsers/`.
class InnertubeClient {
  InnertubeClient({
    Dio? dio,
    VisitorIdStore? visitorIdStore,
    DateTime Function()? clock,
  }) : _dio = dio ?? Dio(),
       _visitorIds = visitorIdStore ?? MemoryVisitorIdStore(),
       _now = clock ?? DateTime.now;

  final Dio _dio;
  final VisitorIdStore _visitorIds;
  final DateTime Function() _now;

  String _language = 'en';
  String? _visitorId;
  bool _initialised = false;

  /// The `hl` code sent with every request.
  String get language => _language;

  Map<String, String> get _headers => {
    'user-agent': Innertube.userAgent,
    'accept': '*/*',
    'accept-encoding': 'gzip, deflate',
    'content-type': 'application/json',
    'content-encoding': 'gzip',
    'origin': Innertube.domain,
    'cookie': 'CONSENT=YES+1',
    if (_visitorId != null) 'X-Goog-Visitor-Id': ?_visitorId,
  };

  /// The `context` block YouTube requires on every InnerTube call.
  ///
  /// `clientVersion` is a date stamp: YouTube rejects versions that are too old,
  /// so Harmony generated today's. `signatureTimestamp` is yesterday's day
  /// count since epoch, which the player endpoint needs to hand back stream
  /// URLs.
  Map<String, dynamic> get context {
    final now = _now();
    final version =
        '1.${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}.01.00';
    final daysSinceEpoch = now
        .difference(DateTime.fromMillisecondsSinceEpoch(0))
        .inDays;

    return {
      'context': {
        'client': {
          'clientName': Innertube.clientName,
          'clientVersion': version,
          'hl': _language,
        },
        'user': <String, dynamic>{},
      },
      'playbackContext': {
        'contentPlaybackContext': {'signatureTimestamp': daysSinceEpoch - 1},
      },
    };
  }

  /// Loads or generates the visitor id. Safe to call more than once.
  Future<void> initialise({String language = 'en'}) async {
    _language = language;
    if (_initialised) return;

    final stored = _visitorIds.read();
    if (stored != null) {
      _visitorId = stored;
      _initialised = true;
      _log.fine('reused stored visitor id');
      return;
    }

    final generated = await _generateVisitorId();
    _visitorId = generated.valueOr(Innertube.fallbackVisitorId);
    if (generated case Ok(:final value)) {
      await _visitorIds.write(value, _now().add(Innertube.visitorIdLifetime));
      _log.info('generated new visitor id');
    } else {
      _log.warning('visitor id generation failed, using the fallback');
    }
    _initialised = true;
  }

  /// Scrapes `VISITOR_DATA` out of the YouTube Music home page's `ytcfg.set`
  /// call. Without it YouTube treats every request as a brand new session and
  /// starts rate limiting.
  Future<Result<String>> _generateVisitorId() async {
    return guard(() async {
      final response = await _dio.get<String>(
        Innertube.domain,
        options: Options(headers: _headers, responseType: ResponseType.plain),
      );
      final match = RegExp(
        r'ytcfg\.set\s*\(\s*({.+?})\s*\)\s*;',
      ).firstMatch(response.data ?? '');
      if (match == null) {
        throw const ParseFailure('ytcfg.set', message: 'not found in page');
      }
      final config = json.decode(match.group(1)!) as Map<String, dynamic>;
      final visitorData = config['VISITOR_DATA'];
      if (visitorData is! String || visitorData.isEmpty) {
        throw const ParseFailure('ytcfg.VISITOR_DATA');
      }
      return visitorData;
    }, onError: (error, stack) => Failure.network(cause: error));
  }

  /// POSTs [body] to [endpoint] and returns the decoded response.
  ///
  /// [extraParams] is appended to the query string — continuation tokens
  /// arrive that way.
  Future<Result<Map<String, dynamic>>> post(
    String endpoint,
    Map<String, dynamic> body, {
    String extraParams = '',
    int maxAttempts = 3,
  }) async {
    await initialise(language: _language);
    final url =
        '${Innertube.baseUrl}$endpoint'
        '${Innertube.fixedParams}$extraParams';

    return retry(() => _postOnce(url, body), maxAttempts: maxAttempts);
  }

  Future<Result<Map<String, dynamic>>> _postOnce(
    String url,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post<dynamic>(
        url,
        data: body,
        options: Options(
          headers: _headers,
          // Handle every status ourselves so a 4xx becomes a typed failure
          // rather than a thrown DioException.
          validateStatus: (_) => true,
        ),
      );

      final status = response.statusCode ?? 0;
      if (status != 200) {
        _log.warning('$url -> HTTP $status');
        return Err(Failure.http(statusCode: status, message: url));
      }

      final data = response.data;
      if (data is Map<String, dynamic>) return Ok(data);
      if (data is String) {
        return Ok(json.decode(data) as Map<String, dynamic>);
      }
      return Err(
        ParseFailure(
          'response',
          message: 'expected a JSON object, got ${data.runtimeType}',
        ),
      );
    } on DioException catch (error) {
      return Err(Failure.network(message: error.message, cause: error));
    } on FormatException catch (error) {
      return Err(
        ParseFailure('response', message: 'malformed JSON', cause: error),
      );
    }
  }

  /// Browses [browseId], optionally with extra body fields.
  Future<Result<Map<String, dynamic>>> browse(
    String browseId, {
    Map<String, dynamic> extraBody = const {},
    String extraParams = '',
  }) => post(Innertube.browse, {
    ...context,
    'browseId': browseId,
    ...extraBody,
  }, extraParams: extraParams);

  void close() => _dio.close();
}
