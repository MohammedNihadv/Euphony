import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../data/remote/innertube/parsers/home_parser.dart';
import '../../design/tokens/brutal.dart';
import '../../design/tokens/tokens.dart';
import '../../design/widgets/brand_badge.dart';
import '../../domain/music_item.dart';
import '../../domain/song.dart';
import '../../playback/player_provider.dart';
import '../common/song_options_sheet.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  HomeFeed? _feed;
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadHomeFeed();
  }

  Future<void> _loadHomeFeed({bool force = false}) async {
    // Only show full loading spinner on first load (no cached data yet)
    if (_feed == null) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    final repo = ref.read(homeRepositoryProvider);
    final result = await repo.fetchHomeFeed(force: force);

    if (!mounted) return;
    result.fold(
      (feed) => setState(() {
        _feed = feed;
        _loading = false;
      }),
      (failure) => setState(() {
        _error = failure.message ?? 'Failed to load home feed';
        _loading = false;
      }),
    );
  }

  String _selectedCategory = 'All';

  String _greetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    // Quick Picks are horizontal tiles. On a wide desktop window a 2-column
    // grid stretched each cell tall and left it mostly empty, so scale the
    // column count with width and pin the tile height instead.
    final width = MediaQuery.sizeOf(context).width;
    final quickCols = width >= 1500
        ? 4
        : width >= 1100
        ? 3
        : 2;

    return Scaffold(
      appBar: AppBar(
        title: const EuphonyBrandBadge(animate: true),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadHomeFeed(force: true),
          color: EuBrutal.accent,
          child: CustomScrollView(
            slivers: [
              // Category Filter Pills (Spotify-style)
              SliverToBoxAdapter(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(
                    EuSpace.screenGutter,
                    EuSpace.sm,
                    EuSpace.screenGutter,
                    EuSpace.md,
                  ),
                  child: Row(
                    children: [
                      _buildCategoryChip('All'),
                      const SizedBox(width: EuSpace.sm),
                      _buildCategoryChip('Music'),
                      const SizedBox(width: EuSpace.sm),
                      _buildCategoryChip('Playlists'),
                      const SizedBox(width: EuSpace.sm),
                      _buildCategoryChip('Charts'),
                    ],
                  ),
                ),
              ),

              // Hero Banner (Neo-Brutalist)
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EuSpace.screenGutter,
                ),
                sliver: SliverToBoxAdapter(
                  child: StreamBuilder<void>(
                    stream: Stream<void>.periodic(const Duration(minutes: 1)),
                    builder: (context, _) =>
                        _HeroBanner(greeting: _greetingMessage()),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) =>
                      FadeTransition(opacity: anim, child: child),
                  child: _loading
                      ? const SizedBox(key: ValueKey('loading'))
                      : _error != null
                      ? Padding(
                          key: const ValueKey('error'),
                          padding: const EdgeInsets.all(EuSpace.xl),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 40),
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: EuBrutal.alert,
                              ),
                              const SizedBox(height: EuSpace.md),
                              Text(
                                _error!,
                                style: theme.textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: EuSpace.md),
                              FilledButton.icon(
                                onPressed: _loadHomeFeed,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Try Again'),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(key: ValueKey('content')),
                ),
              ),

              if (_loading)
                const _HomeSkeletonFeed()
              else if (_error != null)
                const SliverToBoxAdapter(child: SizedBox.shrink())
              else if (_feed != null) ...[
                // Quick Picks Grid (Image 3)
                if (_feed!.quickPicks.isNotEmpty &&
                    (_selectedCategory == 'All' ||
                        _selectedCategory == 'Music')) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      EuSpace.screenGutter,
                      EuSpace.lg,
                      EuSpace.screenGutter,
                      EuSpace.sm,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Quick Picks',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: EuSpace.screenGutter,
                      vertical: EuSpace.xs,
                    ),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: quickCols,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        mainAxisExtent: 84,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final song = _feed!.quickPicks[index];
                        return _QuickPickTile(
                          song: song,
                          queueSongs: _feed!.quickPicks,
                        );
                      }, childCount: _feed!.quickPicks.length.clamp(
                        0,
                        quickCols >= 3 ? 8 : 6,
                      )),
                    ),
                  ),
                ],

                // Shelves / Sections
                for (final section in _feed!.sections)
                  if (_shouldShowSection(section.title))
                    SliverPadding(
                      padding: const EdgeInsets.only(
                        left: EuSpace.screenGutter,
                        right: EuSpace.screenGutter,
                        top: EuSpace.md,
                        bottom: EuSpace.lg,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _HomeSectionBlock(section: section),
                      ),
                    ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 80.0)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = _selectedCategory == label;
    final scheme = Theme.of(context).colorScheme;

    // Selected: the bright highlight slab with dark text and a hard shadow.
    // Unselected: a quiet surface pill with the light frame and light text —
    // both read clearly on the dark canvas.
    final bg = isSelected ? EuBrutal.highlight : scheme.surfaceContainerHigh;
    final fg = isSelected ? EuBrutal.onHighlight : context.eu.ink;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? context.eu.ink
                : context.eu.ink.withValues(alpha: 0.35),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected ? EuBrutal.smHardShadow : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: fg,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  bool _shouldShowSection(String title) {
    if (_selectedCategory == 'All') return true;
    final lower = title.toLowerCase();
    if (_selectedCategory == 'Music') {
      return !lower.contains('playlist');
    }
    if (_selectedCategory == 'Playlists') {
      return lower.contains('playlist') ||
          lower.contains('mix') ||
          lower.contains('radio');
    }
    if (_selectedCategory == 'Charts') {
      return lower.contains('chart') ||
          lower.contains('top') ||
          lower.contains('trending') ||
          lower.contains('hit');
    }
    return true;
  }
}

/// Animated hero banner with live waveform bars and staggered text animation.
class _HeroBanner extends StatefulWidget {
  const _HeroBanner({required this.greeting});
  final String greeting;

  @override
  State<_HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<_HeroBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: EuBrutal.accent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.eu.ink, width: 2.5),
            boxShadow: [
              BoxShadow(color: context.eu.ink, offset: const Offset(5, 5)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.greeting,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: context.eu.ink,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Quick picks, trending tracks & recommendations',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: context.eu.ink.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: EuBrutal.highlight,
                  shape: BoxShape.circle,
                  border: Border.all(color: EuBrutal.onHighlight, width: 2.5),
                  boxShadow: EuBrutal.smHardShadow,
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  color: EuBrutal.onHighlight,
                  size: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal Quick Pick tile matching Image 3 (Neo-Brutalist card layout with black border and offset shadow).
class _QuickPickTile extends ConsumerWidget {
  const _QuickPickTile({required this.song, this.queueSongs});
  final Song song;
  final List<Song>? queueSongs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final artworkUrl = song.artwork?.medium ?? song.artworkUrl;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.eu.ink, width: 2),
        boxShadow: [
          BoxShadow(color: context.eu.ink, offset: const Offset(2, 2)),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (queueSongs != null) {
              final idx = queueSongs!.indexWhere((s) => s.id == song.id);
              if (idx >= 0) {
                ref
                    .read(playerControllerProvider)
                    .playQueue(queueSongs!, startIndex: idx);
              } else {
                ref.read(playerControllerProvider).playSong(song);
              }
            } else {
              ref.read(playerControllerProvider).playSong(song);
            }
          },
          onLongPress: () => showSongOptionsSheet(context, song),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      border: Border.all(color: context.eu.ink, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: artworkUrl != null
                        ? Image.network(
                            artworkUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: EuBrutal.highlight,
                              child: const Icon(
                                Icons.music_note,
                                size: 20,
                                color: EuBrutal.onHighlight,
                              ),
                            ),
                          )
                        : Container(
                            color: EuBrutal.highlight,
                            child: const Icon(
                              Icons.music_note,
                              size: 20,
                              color: EuBrutal.onHighlight,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.eu.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        song.artistNames,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.eu.ink.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Five bars that independently bounce up and down like a music equaliser.
class _AnimatedMusicBars extends StatefulWidget {
  const _AnimatedMusicBars();

  @override
  State<_AnimatedMusicBars> createState() => _AnimatedMusicBarsState();
}

class _AnimatedMusicBarsState extends State<_AnimatedMusicBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  // 5 bars, each with a different phase and speed multiplier
  static const _phases = [0.0, 0.45, 0.25, 0.7, 0.15];
  static const _speeds = [1.0, 1.4, 0.8, 1.2, 1.0];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(5, (i) {
            final t = (_ctrl.value + _phases[i]) % 1.0;
            final speed = _speeds[i];
            // Sine curve so it feels organic, not linear
            final frac = (0.5 - 0.5 * math.cos(t * speed * math.pi * 2)).clamp(
              0.0,
              1.0,
            );
            final height = 10.0 + frac * 30.0;
            return Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
              child: Container(
                width: 5,
                height: height,
                decoration: BoxDecoration(
                  color: context.eu.ink,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _HomeSectionBlock extends ConsumerWidget {
  const _HomeSectionBlock({required this.section});

  final HomeSection section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: EuSpace.md),
        SizedBox(
          height: 220,
          child: ListView.separated(
            clipBehavior: Clip.none,
            padding: const EdgeInsets.only(bottom: 8, left: 2, right: 16),
            scrollDirection: Axis.horizontal,
            itemCount: section.items.length,
            separatorBuilder: (_, index) => const SizedBox(width: EuSpace.md),
            itemBuilder: (context, index) {
              final item = section.items[index];
              return _HomeItemCard(item: item, sectionItems: section.items);
            },
          ),
        ),
      ],
    );
  }
}

class _HomeItemCard extends ConsumerWidget {
  const _HomeItemCard({required this.item, this.sectionItems});

  final MusicItem item;
  final List<MusicItem>? sectionItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      width: 145,
      decoration: EuBrutal.boxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        shadows: EuBrutal.smHardShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            switch (item) {
              case SongItem(:final song):
                if (sectionItems != null) {
                  final songs = sectionItems!
                      .whereType<SongItem>()
                      .map((e) => e.song)
                      .toList();
                  final idx = songs.indexWhere((s) => s.id == song.id);
                  if (idx >= 0) {
                    ref
                        .read(playerControllerProvider)
                        .playQueue(songs, startIndex: idx);
                  } else {
                    ref.read(playerControllerProvider).playSong(song);
                  }
                } else {
                  ref.read(playerControllerProvider).playSong(song);
                }
              case AlbumItem(:final album):
                context.push('/album/${album.browseId}');
              case ArtistItem(:final artist):
                context.push('/artist/${artist.browseId}');
              case PlaylistItem(:final playlist):
                context.push('/playlist/${playlist.id}');
              case StationItem(:final playlistId):
                context.push('/playlist/$playlistId');
            }
          },
          onLongPress: () {
            if (item is SongItem) {
              showSongOptionsSheet(context, (item as SongItem).song);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Clean Album Artwork Container with Neo-Brutalist Border
                AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _artworkUrlFor(item) != null
                        ? Image.network(
                            _artworkUrlFor(item)!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: EuBrutal.accent.withValues(alpha: 0.2),
                              child: const Icon(
                                Icons.music_note,
                                color: EuBrutal.accent,
                              ),
                            ),
                          )
                        : Container(
                            color: EuBrutal.accent.withValues(alpha: 0.2),
                            child: const Icon(
                              Icons.music_note,
                              color: EuBrutal.accent,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                // Song / Album Title
                Text(
                  _titleFor(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                // Artist / Subtitle
                Text(
                  _subtitleFor(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _titleFor(MusicItem item) => switch (item) {
    SongItem(:final song) => song.title,
    AlbumItem(:final album) => album.title,
    ArtistItem(:final artist) => artist.name,
    PlaylistItem(:final playlist) => playlist.title,
    StationItem(:final title) => title,
  };

  String _subtitleFor(MusicItem item) => switch (item) {
    SongItem(:final song) => song.artistNames,
    AlbumItem(:final album) => album.artistNames,
    ArtistItem() => 'Artist',
    PlaylistItem() => 'Playlist',
    StationItem() => 'Station',
  };

  String? _artworkUrlFor(MusicItem item) => switch (item) {
    SongItem(:final song) => song.artwork?.medium,
    AlbumItem(:final album) => album.artwork?.medium,
    ArtistItem(:final artist) => artist.artwork?.medium,
    PlaylistItem(:final playlist) => playlist.artwork?.medium,
    StationItem(:final artworkUrl) => artworkUrl,
  };
}

class _HomeSkeletonFeed extends StatefulWidget {
  const _HomeSkeletonFeed();

  @override
  State<_HomeSkeletonFeed> createState() => _HomeSkeletonFeedState();
}

class _HomeSkeletonFeedState extends State<_HomeSkeletonFeed>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  // Shimmer gradient color
  Color _shimmerBase(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerLow;
  Color _shimmerHighlight(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        horizontal: EuSpace.screenGutter,
        vertical: EuSpace.md,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: EuSpace.lg),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(EuSpace.lg),
                    decoration: EuBrutal.boxDecoration(
                      color: EuBrutal.accent.withValues(
                        alpha: 0.8 + 0.2 * _controller.value,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      shadows: EuBrutal.hardShadow,
                    ),
                    child: Row(
                      children: [
                        const EuphonyLogoMark(size: 40, radius: 11),
                        const SizedBox(width: EuSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Euphony Music',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: context.eu.ink,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tuning your frequencies... Loading tracks',
                                style: TextStyle(
                                  color: context.eu.ink.withValues(alpha: 0.7),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              context.eu.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final shimmer = LinearGradient(
                begin: Alignment(-1.5 + _controller.value * 3.0, 0),
                end: Alignment(-0.5 + _controller.value * 3.0, 0),
                colors: [
                  _shimmerBase(context),
                  _shimmerHighlight(context),
                  _shimmerBase(context),
                ],
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: EuSpace.md),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: shimmer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: context.eu.ink.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 160,
                                height: 13,
                                decoration: BoxDecoration(
                                  color: context.eu.ink.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 90,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: context.eu.ink.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }, childCount: 7),
      ),
    );
  }
}
