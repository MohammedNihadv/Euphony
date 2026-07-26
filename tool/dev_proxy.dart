// A CORS proxy for running Euphony in a browser during development.
//
// InnerTube answers no `Access-Control-Allow-Origin` header, so Chrome blocks
// every request the app makes before it reaches the network — `flutter run -d
// chrome` renders the shell and nothing else. This forwards those same requests
// from a plain socket, where the same-origin policy does not apply, and hands
// the answer back with the headers a browser needs to accept it.
//
//   dart run tool/dev_proxy.dart
//   flutter run -d chrome --dart-define=EUPHONY_DEV_PROXY=http://localhost:8787
//
// Development only. Nothing ships with `EUPHONY_DEV_PROXY` set, and Android —
// the actual target — talks to YouTube directly.

import 'dart:io';

/// The upstream every request is forwarded to.
const String _upstream = 'music.youtube.com';

const int _defaultPort = 8787;

/// Headers the browser sets that must not be replayed upstream.
///
/// `host` has to name the upstream, and the hop-by-hop headers describe the
/// browser-to-proxy connection rather than the proxy-to-YouTube one.
const Set<String> _dropFromRequest = {
  'host',
  'origin',
  'referer',
  // Chrome asks for `br, zstd`; `HttpClient` only auto-decompresses gzip, so
  // forwarding the browser's list gets us a Brotli body we hand on as if it
  // were JSON. Replaced with plain gzip below.
  'accept-encoding',
  'connection',
  'keep-alive',
  'transfer-encoding',
  'upgrade',
  'proxy-connection',
  'content-length',
  'sec-fetch-dest',
  'sec-fetch-mode',
  'sec-fetch-site',
};

/// Headers that describe the upstream connection and would misdescribe ours.
///
/// `HttpClient` gunzips the body for us, so replaying `content-encoding` or the
/// original `content-length` would tell the browser to decode it a second time.
const Set<String> _dropFromResponse = {
  'content-encoding',
  'content-length',
  'transfer-encoding',
  'connection',
  'keep-alive',
  // Ours are authoritative — never forward upstream's.
  'access-control-allow-origin',
  'access-control-allow-headers',
  'access-control-allow-methods',
  'access-control-expose-headers',
};

Future<void> main(List<String> args) async {
  final port = args.isEmpty ? _defaultPort : int.tryParse(args.first);
  if (port == null) {
    stderr.writeln('usage: dart run tool/dev_proxy.dart [port]');
    exitCode = 64;
    return;
  }

  final HttpServer server;
  try {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  } on SocketException catch (error) {
    stderr.writeln('could not bind port $port: ${error.message}');
    stderr.writeln('another proxy may already be running.');
    exitCode = 69;
    return;
  }

  // Bound to loopback above, so it is not reachable from the network.
  final client = HttpClient()..userAgent = null;

  stdout.writeln('euphony dev proxy');
  stdout.writeln('  http://localhost:$port  ->  https://$_upstream');
  stdout.writeln(
    '  flutter run -d chrome '
    '--dart-define=EUPHONY_DEV_PROXY=http://localhost:$port',
  );
  stdout.writeln('  ctrl-c to stop');

  await for (final request in server) {
    // Deliberately not awaited: one slow upstream call must not hold up the
    // next request. `_handle` reports its own failures and always closes.
    unawaited(_handle(request, client));
  }
}

/// Marks a future as intentionally not awaited.
///
/// Hand-rolled so the tool needs no dependency outside `dart:io`.
void unawaited(Future<void> future) {
  future.catchError((Object error) {
    stderr.writeln('unhandled: $error');
  });
}

Future<void> _handle(HttpRequest request, HttpClient client) async {
  final response = request.response;
  _applyCors(request, response);

  // Preflight: the browser is only asking whether the real call is allowed.
  if (request.method == 'OPTIONS') {
    response.statusCode = HttpStatus.noContent;
    await response.close();
    return;
  }

  final target = Uri.https(
    _upstream,
    request.uri.path,
    request.uri.hasQuery ? request.uri.queryParameters : null,
  );

  try {
    final body = await _readBody(request);
    final upstream = await client.openUrl(request.method, target);

    // Follow redirects ourselves so the browser never sees a cross-origin hop
    // it would then refuse to follow.
    upstream.followRedirects = true;
    upstream.maxRedirects = 5;

    request.headers.forEach((name, values) {
      if (_dropFromRequest.contains(name.toLowerCase())) return;
      upstream.headers.set(name, values.join(', '));
    });
    // YouTube varies its answer on these, and the browser is not allowed to
    // set them itself.
    upstream.headers.set('origin', 'https://$_upstream');
    upstream.headers.set('referer', 'https://$_upstream/');
    // The one encoding `HttpClient` will transparently undo for us.
    upstream.headers.set('accept-encoding', 'gzip');
    if (request.headers.value('cookie') == null) {
      upstream.headers.set('cookie', 'CONSENT=YES+1');
    }

    if (body.isNotEmpty) {
      upstream.headers.contentLength = body.length;
      upstream.add(body);
    }

    final upstreamResponse = await upstream.close();

    response.statusCode = upstreamResponse.statusCode;
    upstreamResponse.headers.forEach((name, values) {
      if (_dropFromResponse.contains(name.toLowerCase())) return;
      response.headers.set(name, values.join(', '));
    });

    await response.addStream(upstreamResponse);
    stdout.writeln(
      '${upstreamResponse.statusCode} ${request.method} ${request.uri.path}',
    );
  } catch (error) {
    // A failed hop is a proxy failure, not an upstream answer — 502 keeps the
    // two distinguishable in the app's logs.
    stderr.writeln('502 ${request.method} ${request.uri.path}: $error');
    response.statusCode = HttpStatus.badGateway;
    response.headers.contentType = ContentType.text;
    response.write('dev proxy could not reach $_upstream: $error');
  } finally {
    await response.close();
  }
}

/// Collects the request body, which may arrive in several chunks.
Future<List<int>> _readBody(HttpRequest request) async {
  final chunks = <int>[];
  await for (final chunk in request) {
    chunks.addAll(chunk);
  }
  return chunks;
}

void _applyCors(HttpRequest request, HttpResponse response) {
  // Echo the caller's origin rather than `*`: the app may later send
  // credentials, which browsers refuse against a wildcard.
  final origin = request.headers.value('origin') ?? '*';
  response.headers
    ..set('access-control-allow-origin', origin)
    ..set('access-control-allow-credentials', 'true')
    ..set('access-control-allow-methods', 'GET, POST, OPTIONS')
    ..set('access-control-max-age', '86400');

  // Reflect whatever the preflight asked for; the app's header set changes as
  // the InnerTube client evolves and this should not need editing with it.
  final requested = request.headers.value('access-control-request-headers');
  response.headers.set(
    'access-control-allow-headers',
    requested ?? 'content-type, x-goog-visitor-id',
  );
}
