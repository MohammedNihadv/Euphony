import 'package:euphony/data/remote/innertube/parsers/album_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures.dart';

void main() {
  test(
    'album title and artwork come from the two-column header, not the fallback',
    () {
      final root = loadFixture('album');

      final result = parseAlbumDetails(root, 'MPREb_fixture');

      result.fold(
        (details) {
          expect(details.album.title, isNot('Album'));
          expect(
            details.album.title,
            'Daft Punk-Inspired Mycelium Groove Odyssey (1985 Edition)',
          );
          expect(details.album.artworkUrl, isNotNull);
        },
        (failure) => fail('parse failed: $failure'),
      );
    },
  );
}
