import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers.dart';
import '../../data/remote/innertube/parsers/home_parser.dart';
import '../../design/tokens/brutal.dart';
import '../../design/tokens/tokens.dart';
import '../../design/widgets/brand_badge.dart';
import '../../domain/music_item.dart';
import '../../playback/player_provider.dart';
import '../common/song_options_sheet.dart';
import '../settings/settings_provider.dart';

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
    final currentRegion = ref.watch(
      settingsControllerProvider.select((s) => s.contentRegion),
    );

    // Auto-reload home feed when user switches region in Settings
    ref.listen(settingsControllerProvider.select((s) => s.contentRegion), (
      prev,
      next,
    ) {
      if (prev != next) {
        _loadHomeFeed(force: true);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const EuphonyPageCapsule(
          label: 'Home',
          icon: Icons.home_rounded,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadHomeFeed(force: true),
          color: EuBrutal.accent,
          // Cap content width and centre it so a wide desktop window doesn't
          // stretch the banner and rows into thin full-bleed strips. No effect
          // on phones, where the screen is narrower than the cap.
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
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
                          _buildCategoryChip('New Releases'),
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
                        stream: Stream<void>.periodic(
                          const Duration(minutes: 1),
                        ),
                        builder: (context, _) => _HeroBanner(
                          greeting: _greetingMessage(),
                          region: currentRegion,
                        ),
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
                    // Featured & Top Charts Carousel (Demus / Billboard style)
                    if (_selectedCategory == 'All' ||
                        _selectedCategory == 'Music' ||
                        _selectedCategory == 'New Releases')
                      const SliverToBoxAdapter(
                        child: _FeaturedChartsCarousel(),
                      ),

                    // Featured Shelves / Sections
                    for (final section
                        in (_feed!.sections.where(_shouldShowSection).isNotEmpty
                            ? _feed!.sections.where(_shouldShowSection)
                            : _feed!.sections))
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

                    const SliverPadding(
                      padding: EdgeInsets.only(bottom: 110.0),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label) {
    final isSelected = _selectedCategory == label;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedCategory = label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? EuBrutal.accent
              : (isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? EuBrutal.accent
                : (isDark
                      ? Colors.white.withValues(alpha: 0.10)
                      : Colors.black.withValues(alpha: 0.08)),
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: EuBrutal.accent.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  bool _shouldShowSection(HomeSection section) {
    if (_selectedCategory == 'All') return true;
    final lower = section.title.toLowerCase();
    final items = section.items;
    final hasSongs = items.any((i) => i is SongItem);
    final hasAlbums = items.any((i) => i is AlbumItem);
    final hasPlaylists = items.any(
      (i) => i is PlaylistItem || i is StationItem,
    );

    if (_selectedCategory == 'Music') {
      if (hasSongs || hasAlbums) return true;
      return !lower.contains('playlist') && !lower.contains('mix');
    }
    if (_selectedCategory == 'Playlists') {
      if (hasPlaylists) return true;
      return lower.contains('playlist') ||
          lower.contains('mix') ||
          lower.contains('waves') ||
          lower.contains('fire') ||
          lower.contains('mass') ||
          lower.contains('hits') ||
          lower.contains('coke studio') ||
          lower.contains('radio') ||
          lower.contains('top') ||
          lower.contains('chart');
    }
    if (_selectedCategory == 'New Releases') {
      return lower.contains('new') ||
          lower.contains('release') ||
          lower.contains('album') ||
          lower.contains('single') ||
          lower.contains('fresh') ||
          lower.contains('drop') ||
          lower.contains('latest') ||
          lower.contains('music video') ||
          lower.contains('video') ||
          hasAlbums;
    }
    return true;
  }
}

/// Animated hero banner with live waveform bars, region indicator, and staggered text animation.
class _HeroBanner extends StatefulWidget {
  const _HeroBanner({required this.greeting, required this.region});
  final String greeting;
  final String region;

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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.22),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4F46E5).withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.35 : 0.22,
                ),
                blurRadius: 20,
                spreadRadius: -2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.greeting,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: EuBrutal.onAccent,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Pulsing live dot
                        FadeTransition(
                          opacity: _fadeAnim,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF22C55E),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Curated for ${widget.region} · Live releases',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: EuBrutal.onAccent.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Live animated equalizer soundwave
              const _AnimatedMusicBars(),
            ],
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
                  color: EuBrutal.onAccent,
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

  /// Returns true if this section looks like a fresh/new-releases shelf.
  static bool _isFreshSection(String title) {
    final l = title.toLowerCase();
    return l.contains('new release') ||
        l.contains('album') ||
        l.contains('single') ||
        l.contains('fresh') ||
        l.contains('drop') ||
        l.contains('latest') ||
        l.contains('music video') ||
        l.contains('release mix');
  }

  static bool _isTrendingSection(String title) {
    final l = title.toLowerCase();
    return l.contains('trending') ||
        l.contains('chart') ||
        l.contains('top') ||
        l.contains('hit') ||
        l.contains('biggest');
  }

  static String? _extractBadgeFor(String title) {
    final l = title.toLowerCase();
    if (l.contains('mollywood') || l.contains('malayalam')) return 'Mollywood';
    if (l.contains('kollywood') || l.contains('tamil')) return 'Kollywood';
    if (l.contains('tollywood') || l.contains('telugu')) return 'Tollywood';
    if (l.contains('bollywood') || l.contains('hindi')) return 'Bollywood';
    if (l.contains('hollywood') || l.contains('global')) return 'Hollywood';
    if (l.contains('pakistani') || l.contains('coke studio')) {
      return 'Pakistani';
    }
    if (l.contains('indie india') || l.contains('indie')) return 'Indie';
    if (l.contains('billboard') || l.contains('hot 100')) return 'Billboard';
    if (l.contains('hip-hop') || l.contains('rap')) return 'Hip-Hop';
    if (l.contains('k-pop')) return 'K-Pop';
    if (l.contains('j-pop')) return 'J-Pop';
    if (l.contains('pop')) return 'Pop';
    if (l.contains('new release')) return 'NEW';
    if (l.contains('trending')) return 'TRENDING';
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFresh = _isFreshSection(section.title);
    final isTrending = _isTrendingSection(section.title);
    final badgeTag = _extractBadgeFor(section.title);
    final isShowcase = badgeTag != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                section.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badgeTag != null) ...[
              const SizedBox(width: 8),
              _SectionBadge(label: badgeTag, color: EuBrutal.accent),
            ] else if (isFresh) ...[
              const SizedBox(width: 8),
              const _SectionBadge(label: 'NEW', color: EuBrutal.accent),
            ] else if (isTrending) ...[
              const SizedBox(width: 8),
              const _SectionBadge(label: 'LIVE', color: Color(0xFF22C55E)),
            ],
          ],
        ),
        const SizedBox(height: EuSpace.md),
        SizedBox(
          height: isShowcase ? 245 : 220,
          child: ListView.separated(
            clipBehavior: Clip.none,
            padding: const EdgeInsets.only(bottom: 8, left: 2, right: 16),
            scrollDirection: Axis.horizontal,
            itemCount: section.items.length,
            separatorBuilder: (_, index) => const SizedBox(width: EuSpace.md),
            itemBuilder: (context, index) {
              final item = section.items[index];
              if (isShowcase) {
                return _RegionalShowcaseCard(
                  item: item,
                  badgeTag: badgeTag,
                  sectionItems: section.items,
                );
              }
              return _HomeItemCard(item: item, sectionItems: section.items);
            },
          ),
        ),
      ],
    );
  }
}

/// Regional Industry Showcase Card (Tall aesthetic cover with neon sticker pill and glass reflection).
class _RegionalShowcaseCard extends ConsumerWidget {
  const _RegionalShowcaseCard({
    required this.item,
    required this.badgeTag,
    this.sectionItems,
  });

  final MusicItem item;
  final String badgeTag;
  final List<MusicItem>? sectionItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final artworkUrl = _artworkUrlFor(item);

    return Container(
      width: 156,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161626) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Artwork with top-left badge sticker and bottom gradient
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: artworkUrl != null
                          ? Image.network(
                              artworkUrl,
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
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(14),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: EuBrutal.accent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: context.eu.ink, width: 1.2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            offset: Offset(1, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        badgeTag,
                        style: const TextStyle(
                          color: EuBrutal.onAccent,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Title & details
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Text(
                      _subtitleFor(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(
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
      ),
    );
  }
}

/// Small pill badge rendered next to a section title.
class _SectionBadge extends StatelessWidget {
  const _SectionBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: context.eu.ink.withValues(alpha: isDark ? 0.5 : 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontWeight: FontWeight.w900,
          fontSize: 10,
          letterSpacing: 0.8,
        ),
      ),
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 145,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161626) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
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

class _FeaturedChartsCarousel extends StatefulWidget {
  const _FeaturedChartsCarousel();

  @override
  State<_FeaturedChartsCarousel> createState() =>
      _FeaturedChartsCarouselState();
}

class _FeaturedChartsCarouselState extends State<_FeaturedChartsCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;

  final List<_ChartCardData> _cards = const [
    _ChartCardData(
      badge: 'TOP CHART',
      title: 'Global Billboard Hits',
      subtitle: 'The 50 most-streamed tracks worldwide right now',
      tagline: 'Tap to explore charts',
      gradient: [Color(0xFF6366F1), Color(0xFF4338CA)],
      icon: Icons.trending_up_rounded,
      query: 'Billboard Hot 100',
    ),
    _ChartCardData(
      badge: 'COMMUNITY & LIVE',
      title: 'Acoustic & Unplugged',
      subtitle: 'Pure studio acoustic, live sessions & warm vocals',
      tagline: 'Tap to listen live',
      gradient: [Color(0xFFF59E0B), Color(0xFFD97706)],
      icon: Icons.graphic_eq_rounded,
      query: 'Acoustic live songs',
    ),
    _ChartCardData(
      badge: 'DISCOVERY',
      title: 'Indie Breakthroughs',
      subtitle: 'Fresh releases, underground gems & rising talent',
      tagline: 'Tap to discover',
      gradient: [Color(0xFF10B981), Color(0xFF047857)],
      icon: Icons.local_fire_department_rounded,
      query: 'Indie pop hits',
    ),
    _ChartCardData(
      badge: 'IMMERSIVE AUDIO',
      title: 'Midnight 8D Lo-Fi',
      subtitle: '360° spatial audio, chill lo-fi beats & ambient drift',
      tagline: 'Tap to immerse',
      gradient: [Color(0xFFEC4899), Color(0xFF9D174D)],
      icon: Icons.headphones_rounded,
      query: '8D audio songs',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.90);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            EuSpace.screenGutter,
            EuSpace.lg,
            EuSpace.screenGutter,
            EuSpace.xs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Featured & Charts',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Row(
                children: List.generate(
                  _cards.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: _currentPage == index ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? EuBrutal.accent
                          : (isDark ? Colors.white24 : Colors.black12),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 148,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _cards.length,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemBuilder: (context, index) {
              final card = _cards[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                child: GestureDetector(
                  onTap: () {
                    context.push(
                      '/search?q=${Uri.encodeComponent(card.query)}',
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: card.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? Colors.white24 : context.eu.ink,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: card.gradient.first.withValues(alpha: 0.35),
                          offset: const Offset(0, 6),
                          blurRadius: 16,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  card.badge,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    card.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    card.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(
                                        alpha: 0.82,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.play_circle_fill_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    card.tagline,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(card.icon, size: 26, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ChartCardData {
  const _ChartCardData({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.tagline,
    required this.gradient,
    required this.icon,
    required this.query,
  });

  final String badge;
  final String title;
  final String subtitle;
  final String tagline;
  final List<Color> gradient;
  final IconData icon;
  final String query;
}
