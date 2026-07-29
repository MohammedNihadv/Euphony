import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/failure.dart';
import '../../../core/log.dart';
import '../../../core/result.dart';
import '../../../core/retry.dart';
import 'innertube_constants.dart';

/// True on the web platform. Defined locally — the same way Flutter's
/// `kIsWeb` is — so this file (and the fixture-capture tool that imports it)
/// stays runnable on the plain Dart VM without pulling in `package:flutter`.
const bool kIsWeb = bool.fromEnvironment('dart.library.js_util');

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
    this._language = 'en',
    this._region = 'US',
  })  : _dio = dio ?? Dio(),
        _visitorIds = visitorIdStore ?? MemoryVisitorIdStore(),
        _now = clock ?? DateTime.now;

  final Dio _dio;
  final VisitorIdStore _visitorIds;
  final DateTime Function() _now;
  final String _language;
  final String _region;
  String? _visitorId;
  bool _initialised = false;

  /// The `hl` code sent with every request.
  String get language => _language;

  Map<String, String> get _headers {
    final visitorId = _visitorId;
    if (kIsWeb) {
      return {
        'content-type': 'application/json',
        'X-Goog-Visitor-Id': ?visitorId,
      };
    }
    return {
      'user-agent': Innertube.userAgent,
      'accept': '*/*',
      'accept-encoding': 'gzip, deflate',
      'content-type': 'application/json',
      'content-encoding': 'gzip',
      'origin': Innertube.domain,
      'cookie': 'CONSENT=YES+1',
      'X-Goog-Visitor-Id': ?visitorId,
    };
  }

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
          'gl': _region,
        },
        'user': <String, dynamic>{},
      },
      'playbackContext': {
        'contentPlaybackContext': {'signatureTimestamp': daysSinceEpoch - 1},
      },
    };
  }

  /// Loads or generates the visitor id. Safe to call more than once.
  Future<void> initialise() async {
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
    // A browser cannot fetch the page itself — the same-origin policy blocks
    // it. Behind the dev proxy the fetch goes through a plain socket, so the
    // scrape works there and web behaves like the real target.
    if (kIsWeb && Innertube.devProxy.isEmpty) {
      return const Ok(Innertube.fallbackVisitorId);
    }
    return guard(() async {
      final response = await _dio.get<String>(
        Innertube.requestBase,
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
    await initialise();
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

  /// Fetches the "up next" radio queue seeded from [videoId].
  ///
  /// This is what powers autoplay: YouTube returns a `playlistPanelRenderer`
  /// of related tracks that keep the music going after the current queue ends.
  /// The `RDAMVM<videoId>` playlist id and `wAEB` params are the radio-mode
  /// values YouTube's own client sends (ported from Harmony's getWatchPlaylist).
  Future<Result<Map<String, dynamic>>> next(String videoId) => post(
    Innertube.next,
    {
      ...context,
      'videoId': videoId,
      'playlistId': 'RDAMVM$videoId',
      'isAudioOnly': true,
      'enablePersistentPlaylistPanel': true,
      'tunerSettingValue': 'AUTOMIX_SETTING_NORMAL',
      'params': 'wAEB',
    },
  );

  /// Fetches player metadata and streaming formats for [videoId].
  ///
  /// Uses the `ANDROID_MUSIC` client context instead of `WEB_REMIX`, because
  /// YouTube returns direct (non-ciphered) stream URLs only for mobile clients.
  /// The `WEB_REMIX` client gets ciphered-only formats which require signature
  /// deciphering that Euphony does not implement.
  Future<Result<Map<String, dynamic>>> player(String videoId) async {
    await initialise();

    // 1. Try TVHTML5_SIMPLY_EMBEDDED_PLAYER (never signature-ciphered, 100% reliable)
    final tvRes = await _fetchPlayerWithClient(
      videoId,
      clientName: 'TVHTML5_SIMPLY_EMBEDDED_PLAYER',
      clientVersion: '2.0',
      apiKey: Innertube.apiKey,
      userAgent: Innertube.userAgent,
    );

    if (_hasPlayableFormat(tvRes)) {
      return tvRes;
    }

    // 2. Try ANDROID_VR Client (never signature-ciphered by YouTube)
    final vrRes = await _fetchPlayerWithClient(
      videoId,
      clientName: 'ANDROID_VR',
      clientVersion: '1.56.20',
      apiKey: Innertube.apiKey,
      userAgent:
          'com.google.android.apps.youtube.vr/1.56.20 (Linux; U; Android 11)',
      androidSdkVersion: 30,
    );

    if (_hasPlayableFormat(vrRes)) {
      return vrRes;
    }

    // 3. Try IOS Client (never signature-ciphered by YouTube)
    final iosRes = await _fetchPlayerWithClient(
      videoId,
      clientName: 'IOS',
      clientVersion: '19.45.4',
      apiKey: Innertube.apiKey,
      userAgent:
          'com.google.ios.youtube/19.45.4 (iPhone; CPU iPhone OS 17_5 like Mac OS X)',
    );

    if (_hasPlayableFormat(iosRes)) {
      return iosRes;
    }

    // 4. Fallback to Web Remix Client
    return _fetchPlayerWithClient(
      videoId,
      clientName: Innertube.clientName,
      clientVersion: '1.20231219.01.00',
      apiKey: Innertube.apiKey,
      userAgent: Innertube.userAgent,
    );
  }

  bool _hasPlayableFormat(Result<Map<String, dynamic>> res) {
    if (res case Ok(:final value)) {
      final streamingData = value['streamingData'] as Map<String, dynamic>?;
      if (streamingData == null) return false;
      final adaptive = streamingData['adaptiveFormats'] as List? ?? [];
      final muxed = streamingData['formats'] as List? ?? [];
      for (final f in [...adaptive, ...muxed]) {
        if (f is Map<String, dynamic> &&
            (f['url'] as String? ?? '').isNotEmpty) {
          return true;
        }
      }
    }
    return false;
  }

  Future<Result<Map<String, dynamic>>> _fetchPlayerWithClient(
    String videoId, {
    required String clientName,
    required String clientVersion,
    required String apiKey,
    required String userAgent,
    int? androidSdkVersion,
  }) async {
    final now = _now();
    final daysSinceEpoch = now
        .difference(DateTime.fromMillisecondsSinceEpoch(0))
        .inDays;

    final isWebClient = clientName == 'WEB_REMIX' || clientName == 'WEB';
    final body = <String, dynamic>{
      'context': {
        'client': {
          'clientName': clientName,
          'clientVersion': clientVersion,
          '?androidSdkVersion': androidSdkVersion,
          'hl': _language,
          'userAgent': userAgent,
        },
        'user': <String, dynamic>{},
      },
      if (isWebClient)
        'playbackContext': {
          'contentPlaybackContext': {'signatureTimestamp': daysSinceEpoch - 1},
        },
      'videoId': videoId,
    };

    final isYouTubeClient =
        clientName == 'TVHTML5_SIMPLY_EMBEDDED_PLAYER' ||
        clientName == 'ANDROID_VR' ||
        clientName == 'IOS' ||
        clientName == 'ANDROID';
    final baseDomain = isYouTubeClient
        ? 'https://www.youtube.com/'
        : Innertube.requestBase;
    final url =
        '${baseDomain}youtubei/v1/${Innertube.player}'
        '?prettyPrint=false&alt=json&key=$apiKey';

    final headers = <String, String>{
      'user-agent': userAgent,
      'accept': '*/*',
      'accept-encoding': 'gzip, deflate',
      'content-type': 'application/json',
      'X-Goog-Api-Format-Version': '2',
    };

    return retry(() async {
      try {
        final response = await _dio.post<dynamic>(
          url,
          data: body,
          options: Options(headers: headers, validateStatus: (_) => true),
        );

        final status = response.statusCode ?? 0;
        if (status != 200) {
          _log.warning('player $videoId ($clientName) -> HTTP $status');
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
    }, maxAttempts: 2);
  }

  void close() => _dio.close();
}
