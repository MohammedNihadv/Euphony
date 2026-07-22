// Captures live InnerTube responses into test/fixtures/.
//
// Run it when you need to refresh what the golden tests assert against:
//
//   dart run tool/capture_fixtures.dart
//   dart run tool/capture_fixtures.dart search_songs   # just one
//
// Then re-run `flutter test`. A test that starts failing after a capture means
// YouTube changed the response and a parser needs updating — which is exactly
// the signal Harmony never had. Review the diff before committing it.
//
// Fixtures are large and mostly noise, so each one is trimmed to the subtree
// its parser actually reads.

import 'dart:convert';
import 'dart:io';

import 'package:euphony/core/result.dart';
import 'package:euphony/data/remote/innertube/innertube_client.dart';
import 'package:euphony/data/remote/innertube/innertube_constants.dart';
import 'package:euphony/data/remote/innertube/innertube_utils.dart';

/// Stable queries — these need to keep returning the same *kind* of result, so
/// pick things that will not vanish from the catalogue.
const _searchQuery = 'daft punk';
const _albumBrowseId = 'MPREb_0RYe0xF7sZb'; // a Daft Punk release
const _artistBrowseId = 'UC_kRDKYrUlrbtrSiyu5Tflg'; // Daft Punk
const _playlistId = 'RDCLAK5uy_kLWIr9gv1XLlPbaDS965-Db4TrBoUTxQ8'; // a YT mix

typedef Capture = ({
  String name,
  Future<Result<Map<String, dynamic>>> Function(InnertubeClient) run,
});

final _captures = <Capture>[
  (
    name: 'search_unfiltered',
    run: (client) => client.post(Innertube.search, {
      ...client.context,
      'query': _searchQuery,
    }),
  ),
  (
    name: 'search_songs',
    run: (client) => client.post(Innertube.search, {
      ...client.context,
      'query': _searchQuery,
      'params': searchParams(filter: SearchFilter.songs)!,
    }),
  ),
  (
    name: 'search_albums',
    run: (client) => client.post(Innertube.search, {
      ...client.context,
      'query': _searchQuery,
      'params': searchParams(filter: SearchFilter.albums)!,
    }),
  ),
  (
    name: 'search_artists',
    run: (client) => client.post(Innertube.search, {
      ...client.context,
      'query': _searchQuery,
      'params': searchParams(filter: SearchFilter.artists)!,
    }),
  ),
  (
    name: 'search_suggestions',
    run: (client) => client.post(Innertube.searchSuggestions, {
      ...client.context,
      'input': 'daf',
    }),
  ),
  (name: 'home', run: (client) => client.browse(Innertube.homeBrowseId)),
  (name: 'album', run: (client) => client.browse(_albumBrowseId)),
  (name: 'artist', run: (client) => client.browse(_artistBrowseId)),
  (name: 'playlist', run: (client) => client.browse('VL$_playlistId')),
];

/// Keys that carry no information a parser reads, but do carry most of the
/// bytes and change on every capture.
///
/// Dropping them keeps a re-capture's diff down to what actually changed on
/// YouTube's side, which is the only reason to review one.
/// Note what is *not* here: `accessibilityData` carries the "Explicit" badge
/// label, and `iconType` is how a menu entry is recognised as radio or shuffle.
/// Both look like noise and are load-bearing.
const _noise = {
  'trackingParams',
  'clickTrackingParams',
  'loggingDirectives',
  'responseContext',
  'loggingContext',
  'serializedShareEntity',
  'a11ySkipNavigationLabel',
};

Object? _trim(Object? node) {
  if (node is Map<String, dynamic>) {
    return {
      for (final entry in node.entries)
        if (!_noise.contains(entry.key)) entry.key: _trim(entry.value),
    };
  }
  if (node is List) {
    return [for (final item in node) _trim(item)];
  }
  return node;
}

Future<void> main(List<String> args) async {
  final wanted = args.toSet();
  final directory = Directory('test/fixtures');
  await directory.create(recursive: true);

  final client = InnertubeClient();
  await client.initialise();

  var failures = 0;
  for (final capture in _captures) {
    if (wanted.isNotEmpty && !wanted.contains(capture.name)) continue;

    stdout.write('${capture.name.padRight(20)} ');
    final result = await capture.run(client);

    switch (result) {
      case Ok(:final value):
        final file = File('${directory.path}/${capture.name}.json');
        await file.writeAsString(
          const JsonEncoder.withIndent('  ').convert(_trim(value)),
        );
        final kb = (await file.length()) ~/ 1024;
        stdout.writeln('ok (${kb}k)');
      case Err(:final failure):
        stdout.writeln('FAILED: $failure');
        failures++;
    }
  }

  client.close();
  if (failures > 0) {
    stderr.writeln('\n$failures capture(s) failed');
    exit(1);
  }
  stdout.writeln('\nFixtures written to ${directory.path}');
}
