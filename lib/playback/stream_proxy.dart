import 'dart:async';
import 'dart:io';

import '../core/log.dart';

final _log = logFor('stream_proxy');

/// A loopback HTTP proxy that makes googlevideo audio streams playable.
///
/// googlevideo answers a range request only when it is **small and bounded**:
/// a probe on this device returned 206 for ranges up to 512 KB but 403 for an
/// open-ended range (`bytes=0-`), for no range at all, and for any single range
/// of 1 MB or more. ExoPlayer (the engine behind just_audio on Android) opens a
/// progressive stream with one large, open-ended request — exactly what
/// googlevideo refuses — so every track failed to load with "Source error /
/// 403" even though the URL itself was fine.
///
/// This proxy sits between ExoPlayer and googlevideo. ExoPlayer connects to
/// `http://127.0.0.1:<port>/<id>` and reads sequentially; for each read the
/// proxy fetches at most [_chunkSize] bytes from googlevideo with an explicit
/// bounded range, returns a proper `206` + `Content-Range`, and lets ExoPlayer
/// come back for the next chunk. A few-MB song becomes a dozen small requests,
/// all of which googlevideo accepts.
class StreamProxy {
  StreamProxy._(this._server, this.port);

  final HttpServer _server;
  final int port;

  /// Largest range googlevideo serves without a 403 on this class of URL.
  static const int _chunkSize = 512 * 1024;

  final Map<String, String> _urls = {};
  var _counter = 0;

  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 20)
    ..autoUncompress = false
    ..idleTimeout = const Duration(seconds: 30);

  static StreamProxy? _instance;

  /// Starts (or reuses) the shared proxy bound to loopback.
  static Future<StreamProxy> start() async {
    final existing = _instance;
    if (existing != null) return existing;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final proxy = StreamProxy._(server, server.port);
    proxy._listen();
    _instance = proxy;
    _log.info('stream proxy on 127.0.0.1:${server.port}');
    return proxy;
  }

  /// Registers [remoteUrl] and returns the local URL ExoPlayer should play.
  String localUrlFor(String remoteUrl) {
    final id = (_counter++).toString();
    _urls[id] = remoteUrl;
    return 'http://127.0.0.1:$port/$id';
  }

  void _listen() {
    _server.listen((request) async {
      final id = request.uri.pathSegments.isNotEmpty
          ? request.uri.pathSegments.first
          : '';
      final remote = _urls[id];
      if (remote == null) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      try {
        await _relay(request, remote);
      } catch (e) {
        _log.warning('relay error: $e');
        try {
          request.response.statusCode = HttpStatus.badGateway;
          await request.response.close();
        } catch (_) {}
      }
    });
  }

  Future<void> _relay(HttpRequest request, String remoteUrl) async {
    final uri = Uri.parse(remoteUrl);
    final total = int.tryParse(uri.queryParameters['clen'] ?? '');

    // Where ExoPlayer wants to read from, and (optionally) an explicit end.
    var start = 0;
    int? requestedEnd;
    final incoming = request.headers.value(HttpHeaders.rangeHeader);
    if (incoming != null) {
      final m = RegExp(r'bytes=(\d+)-(\d*)').firstMatch(incoming);
      if (m != null) {
        start = int.tryParse(m.group(1)!) ?? 0;
        final e = m.group(2);
        if (e != null && e.isNotEmpty) requestedEnd = int.tryParse(e);
      }
    }

    // Cap the upstream fetch to a chunk googlevideo will actually serve.
    var end = start + _chunkSize - 1;
    if (requestedEnd != null && requestedEnd < end) end = requestedEnd;
    if (total != null && total > 0 && end > total - 1) end = total - 1;

    final upstream = await _client.getUrl(uri);
    upstream.headers.set(HttpHeaders.rangeHeader, 'bytes=$start-$end');
    upstream.headers.set(
      HttpHeaders.userAgentHeader,
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    );
    final response = await upstream.close();

    // Relay status (206) and the byte-range headers ExoPlayer needs to page on.
    request.response.statusCode = response.statusCode;
    void copy(String name) {
      final v = response.headers.value(name);
      if (v != null) request.response.headers.set(name, v);
    }
    copy(HttpHeaders.contentTypeHeader);
    copy(HttpHeaders.contentRangeHeader);
    copy(HttpHeaders.contentLengthHeader);
    copy(HttpHeaders.acceptRangesHeader);
    request.response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');

    await response.pipe(request.response);
  }
}
