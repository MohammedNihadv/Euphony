import 'package:meta/meta.dart';

/// An artist as referenced from a song, album or search row.
///
/// Rows often carry an artist name with no browse id (the run is plain text,
/// not a link), so [browseId] is nullable and the UI must not assume it can
/// navigate from every artist chip.
@immutable
class ArtistRef {
  const ArtistRef({required this.name, this.browseId});

  final String name;
  final String? browseId;

  bool get isNavigable => browseId != null;

  @override
  String toString() =>
      'ArtistRef($name${browseId == null ? '' : ' @$browseId'})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtistRef && name == other.name && browseId == other.browseId;

  @override
  int get hashCode => Object.hash(name, browseId);
}

/// Joins artist names the way YouTube Music displays them.
String formatArtists(List<ArtistRef> artists) =>
    artists.map((a) => a.name).join(', ');
