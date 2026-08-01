import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../design/tokens/brutal.dart';
import '../../design/tokens/tokens.dart';
import '../../domain/song.dart';

/// Shows a Neo-Brutalist lyrics modal sheet for the given [song].
void showLyricsSheet(BuildContext context, Song song) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    barrierColor: Colors.black54,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      side: BorderSide(color: EuBrutal.ink, width: 2.5),
    ),
    builder: (context) => _LyricsSheet(song: song),
  );
}

class _LyricsSheet extends StatefulWidget {
  const _LyricsSheet({required this.song});

  final Song song;

  @override
  State<_LyricsSheet> createState() => _LyricsSheetState();
}

class _LyricsSheetState extends State<_LyricsSheet> {
  String? _plainLyrics;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLyrics();
  }

  Future<void> _fetchLyrics() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final artist = Uri.encodeComponent(widget.song.artistNames);
    final title = Uri.encodeComponent(widget.song.title);
    final dur = widget.song.duration?.inSeconds ?? 200;
    final url =
        'https://lrclib.net/api/get?artist_name=$artist&track_name=$title&duration=$dur';

    try {
      final response = await Dio().get<Map<String, dynamic>>(
        url,
        options: Options(responseType: ResponseType.json),
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!;
        final plain = data['plainLyrics'] as String?;
        final synced = data['syncedLyrics'] as String?;

        if (synced != null && synced.isNotEmpty) {
          final cleaned = synced.replaceAll(RegExp(r'\[\d+:\d+\.\d+\]\s*'), '');
          setState(() {
            _plainLyrics = cleaned;
            _loading = false;
          });
        } else if (plain != null && plain.isNotEmpty) {
          setState(() {
            _plainLyrics = plain;
            _loading = false;
          });
        } else {
          setState(() {
            _error = 'No lyrics found for this song';
            _loading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Lyrics not available';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Could not load lyrics right now';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(EuSpace.lg),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: EuBrutal.highlight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: EuBrutal.onHighlight, width: 2),
                  ),
                  child: const Icon(Icons.lyrics, color: EuBrutal.onHighlight),
                ),
                const SizedBox(width: EuSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        widget.song.artistNames,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: EuBrutal.ink.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: EuBrutal.ink, thickness: 1.5),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: EuBrutal.accent),
                  )
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(EuSpace.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.music_off,
                            size: 48,
                            color: EuBrutal.alert,
                          ),
                          const SizedBox(height: EuSpace.md),
                          Text(
                            _error!,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(EuSpace.xl),
                    child: SelectableText(
                      _plainLyrics!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 18,
                        height: 1.6,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
