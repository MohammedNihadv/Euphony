import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../design/tokens/brutal.dart';
import '../../design/tokens/tokens.dart';
import '../../domain/artist.dart';
import '../../playback/player_provider.dart';

class ArtistScreen extends ConsumerStatefulWidget {
  const ArtistScreen({required this.browseId, super.key});

  final String browseId;

  @override
  ConsumerState<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends ConsumerState<ArtistScreen> {
  Artist? _artist;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadArtist();
  }

  Future<void> _loadArtist() async {
    final repo = ref.read(musicDetailRepositoryProvider);
    final result = await repo.fetchArtist(widget.browseId);

    if (!mounted) return;
    result.fold(
      (artist) => setState(() {
        _artist = artist;
        _loading = false;
      }),
      (failure) => setState(() {
        _error = failure.message ?? 'Failed to load artist';
        _loading = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          tooltip: 'Back',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(
          _artist?.name ?? 'Artist',
          style: theme.textTheme.screenTitle?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: EuBrutal.accent),
              )
            : _error != null
            ? Center(child: Text(_error!, style: theme.textTheme.titleMedium))
            : _artist == null
            ? const Center(child: Text('Artist not found'))
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: ListView(
                padding: const EdgeInsets.all(EuSpace.screenGutter),
                children: [
                  // Artist Header Card
                  Container(
                    padding: const EdgeInsets.all(EuSpace.lg),
                    decoration: EuBrutal.boxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      shadows: EuBrutal.hardShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: context.eu.ink,
                              width: 2.5,
                            ),
                            color: EuBrutal.highlight,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _artist!.artworkUrl != null
                              ? Image.network(
                                  _artist!.artworkUrl!,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: EuBrutal.onHighlight,
                                ),
                        ),
                        const SizedBox(width: EuSpace.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _artist!.name,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (_artist!.subscribers != null)
                                Text(
                                  _artist!.subscribers!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: context.eu.ink.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: EuSpace.xl),

                  // Artist Sections (Top Songs / Albums)
                  for (final section in _artist!.sections) ...[
                    Text(
                      section.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: EuSpace.md),
                    for (int i = 0; i < section.songs.length; i++)
                      Builder(
                        builder: (context) {
                          final song = section.songs[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: EuSpace.sm),
                            decoration: EuBrutal.boxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              shadows: EuBrutal.smHardShadow,
                            ),
                            child: Material(
                              type: MaterialType.canvas,
                              color: theme.colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              child: ListTile(
                                onTap: () => ref
                                    .read(playerControllerProvider)
                                    .playQueue(section.songs, startIndex: i),
                                title: Text(
                                  song.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Text(song.artistNames),
                                trailing: const Icon(
                                  Icons.play_circle_fill,
                                  color: EuBrutal.accent,
                                  size: 32,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: EuSpace.xl),
                  ],
                ],
              ),
                ),
              ),
      ),
    );
  }
}
