import 'package:euphony/data/remote/innertube/parsers/artist_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures.dart';

void main() {
  test('parses artist page with full discography sections and metadata', () {
    final root = loadFixture('artist');

    final result = parseArtistPage(root, 'UCRr1xG_2WIDs18a6cIiCxeA');

    result.fold(
      (artist) {
        expect(artist.name, 'Daft Punk');
        expect(artist.artworkUrl, isNotNull);
        expect(artist.sections, isNotEmpty);

        // Find the Albums section
        final albumsSection = artist.sections.firstWhere(
          (s) => s.title == 'Albums',
          orElse: () => throw Exception('Albums section not found'),
        );
        expect(albumsSection.albums, isNotEmpty);

        final firstAlbum = albumsSection.albums.first;
        expect(firstAlbum.title, 'Random Access Memories (Drumless Edition)');
        expect(firstAlbum.year, 2023);
        expect(firstAlbum.artistNames, 'Daft Punk');

        // Find Singles & EPs section
        final singlesSection = artist.sections.firstWhere(
          (s) => s.title == 'Singles & EPs',
          orElse: () => throw Exception('Singles & EPs section not found'),
        );
        expect(singlesSection.albums, isNotEmpty);
        expect(singlesSection.browseId, isNotNull);

        final firstSingle = singlesSection.albums.first;
        expect(firstSingle.title, 'GLBTM (Studio Outtakes)');
        expect(firstSingle.year, 2023);
        expect(firstSingle.artistNames, 'Daft Punk');

        // Find Related Artists section
        final relatedSection = artist.sections.firstWhere(
          (s) => s.title == 'Fans might also like',
          orElse: () => throw Exception('Fans might also like section not found'),
        );
        expect(relatedSection.relatedArtists, isNotEmpty);
        expect(relatedSection.relatedArtists.first.name, 'M83');
      },
      (failure) => fail('parse failed: $failure'),
    );
  });
}

