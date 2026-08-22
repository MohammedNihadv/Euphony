import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/failure.dart';
import '../../data/providers.dart';
import '../../data/remote/innertube/innertube_utils.dart';
import '../../data/repository/settings_repository.dart';
import '../../design/theme/theme_controller.dart';
import '../../design/tokens/brutal.dart';
import '../../design/tokens/tokens.dart';
import '../../domain/album.dart';
import '../../domain/artist.dart';
import '../../domain/music_item.dart';
import '../../domain/playlist.dart';
import '../../domain/search_results.dart';
import '../../domain/song.dart';
import '../../playback/player_provider.dart';
import '../common/song_options_sheet.dart';
import '../settings/log_exporter.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  Timer? _suggestionDebounce;
  var _suggestionRequest = 0;
  var _suggestions = <String>[];
  var _loadingSuggestions = false;

  SearchResults? _results;
  Failure? _failure;
  var _searching = false;
  String? _activeFilter;

  @override
  void dispose() {
    _suggestionDebounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _search(
    String rawQuery, {
    String? params,
    String? filterLabel,
  }) async {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      setState(() {
        _results = null;
        _failure = null;
        _activeFilter = null;
      });
      return;
    }

    _suggestionDebounce?.cancel();
    setState(() {
      _suggestions = const [];
      _loadingSuggestions = false;
      _searching = true;
      _failure = null;
      _activeFilter = filterLabel;
      _focusNode.unfocus();
    });

    final searchDao = ref.read(searchHistoryDaoProvider);
    final repository = ref.read(searchRepositoryProvider);

    await searchDao.record(query);
    final result = await repository.search(
      query,
      filter: _filterForLabel(filterLabel),
      params: params,
    );

    if (!mounted) return;
    result.fold(
      (results) {
        setState(() {
          _results = results;
          _searching = false;
        });
        _applyArtwork(results);
      },
      (failure) => setState(() {
        _failure = failure;
        _searching = false;
      }),
    );
  }

  void _queueSuggestions(String query) {
    _suggestionDebounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      setState(() {
        _suggestions = const [];
        _loadingSuggestions = false;
      });
      return;
    }

    setState(() => _loadingSuggestions = true);
    _suggestionDebounce = Timer(const Duration(milliseconds: 240), () async {
      if (!mounted) return;
      final repository = ref.read(searchRepositoryProvider);
      final request = ++_suggestionRequest;
      final result = await repository.suggestions(trimmed);
      if (!mounted || request != _suggestionRequest) return;
      result.fold(
        (suggestions) => setState(() {
          _suggestions = suggestions.take(6).toList();
          _loadingSuggestions = false;
        }),
        (_) => setState(() {
          _suggestions = const [];
          _loadingSuggestions = false;
        }),
      );
    });
  }

  void _clearSearch() {
    _controller.clear();
    _suggestionDebounce?.cancel();
    setState(() {
      _suggestions = const [];
      _results = null;
      _failure = null;
      _activeFilter = null;
      _searching = false;
      _loadingSuggestions = false;
    });
    ref.read(themeControllerProvider.notifier).resetArtwork();
    _focusNode.requestFocus();
  }

  void _applyArtwork(SearchResults results) {
    final item =
        results.topResult ??
        results.sections.expand((section) => section.items).firstOrNull;
    final artworkUrl = _artworkUrlFor(item);
    if (artworkUrl == null) return;
    ref
        .read(themeControllerProvider.notifier)
        .applyArtwork(_artworkKeyFor(item), NetworkImage(artworkUrl));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Euphony'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.tune),
            onPressed: () => _showSettingsSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: CustomScrollView(
              slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                EuSpace.screenGutter,
                EuSpace.sm,
                EuSpace.screenGutter,
                EuSpace.lg,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Search', style: theme.textTheme.screenTitle),
                    const SizedBox(height: EuSpace.md),
                    Container(
                      decoration: EuBrutal.boxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                        shadows: EuBrutal.hardShadow,
                      ),
                      child: SearchBar(
                        controller: _controller,
                        focusNode: _focusNode,
                        hintText: 'Songs, albums, artists',
                        leading: const Icon(Icons.search, size: 24),
                        trailing: [
                          if (_controller.text.isNotEmpty)
                            IconButton(
                              tooltip: 'Clear',
                              icon: const Icon(Icons.close),
                              onPressed: _clearSearch,
                            ),
                        ],
                        onChanged: (value) {
                          setState(() {});
                          _queueSuggestions(value);
                        },
                        onSubmitted: _search,
                      ),
                    ),
                    const SizedBox(height: EuSpace.md),
                    if (_loadingSuggestions) const LinearProgressIndicator(),
                    _SuggestionStrip(
                      suggestions: _suggestions,
                      onSelected: (query) {
                        _controller.text = query;
                        _search(query);
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (_searching)
              const SliverToBoxAdapter(child: LinearProgressIndicator())
            else if (_failure != null)
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: EuSpace.screenGutter,
                ),
                sliver: SliverToBoxAdapter(
                  child: _FailurePanel(
                    failure: _failure!,
                    onRetry: () =>
                        _search(_controller.text, filterLabel: _activeFilter),
                  ),
                ),
              )
            else if (_results == null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  EuSpace.screenGutter,
                  0,
                  EuSpace.screenGutter,
                  EuSpace.xxxl,
                ),
                sliver: SliverToBoxAdapter(
                  child: _SearchLanding(
                    onSelected: (query) {
                      _controller.text = query;
                      _search(query);
                    },
                  ),
                ),
              )
            else
              _ResultSlivers(
                results: _results!,
                activeFilter: _activeFilter,
                onFilterSelected: (label, params) => _search(
                  _results!.query,
                  params: params,
                  filterLabel: label,
                ),
              ),
          ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const _SettingsSheet(),
    );
  }
}

class _GenreItem {
  const _GenreItem(this.title, this.icon, this.color);
  final String title;
  final IconData icon;
  final Color color;
}

class _SearchLanding extends ConsumerWidget {
  const _SearchLanding({required this.onSelected});

  final ValueChanged<String> onSelected;

  // A curated brutalist set: bold and colour-blocked, but drawn from a tighter,
  // more harmonious range than the old neon rainbow so the grid reads as one
  // considered palette instead of eight clashing swatches.
  static const _genres = [
    _GenreItem('Pop', Icons.favorite_rounded, Color(0xFF7C5CFF)),
    _GenreItem('Hip-Hop', Icons.graphic_eq_rounded, Color(0xFFE85D9E)),
    _GenreItem('Rock', Icons.bolt_rounded, Color(0xFFE24D3D)),
    _GenreItem('Indie', Icons.brush_rounded, Color(0xFF1FB6A6)),
    _GenreItem('Dance', Icons.blur_on_rounded, Color(0xFFF5A623)),
    _GenreItem('Chill', Icons.spa_rounded, Color(0xFF4C9BE8)),
    _GenreItem('Top Charts', Icons.trending_up_rounded, Color(0xFF9B6DE8)),
    _GenreItem('Workout', Icons.fitness_center_rounded, Color(0xFFE24D6A)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(searchHistoryDaoProvider);
    final theme = Theme.of(context);
    // More category columns on wider (desktop) windows so the tiles don't blow
    // up into a couple of huge blocks.
    final width = MediaQuery.sizeOf(context).width;
    final categoryCols = width >= 1500
        ? 5
        : width >= 1100
        ? 4
        : width >= 720
        ? 3
        : 2;

    return StreamBuilder(
      stream: dao.watchRecent(limit: 8),
      builder: (context, snapshot) {
        final rows = snapshot.data ?? const [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (rows.isNotEmpty) ...[
              Text(
                'Recent searches',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: EuSpace.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final row in rows)
                    GestureDetector(
                      onTap: () => onSelected(row.query),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.3,
                            ),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.history,
                              size: 16,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.7,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              row.query,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => dao.remove(row.query),
                              child: Icon(
                                Icons.close_rounded,
                                size: 15,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: EuSpace.xl),
            ],

            Text(
              'Browse Categories',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: EuSpace.md),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: categoryCols,
                childAspectRatio: 2.2,
                crossAxisSpacing: EuSpace.md,
                mainAxisSpacing: EuSpace.md,
              ),
              itemCount: _genres.length,
              itemBuilder: (context, index) {
                final item = _genres[index];
                return GestureDetector(
                  onTap: () => onSelected(item.title),
                  child: Container(
                    padding: const EdgeInsets.all(EuSpace.md),
                    decoration: EuBrutal.boxDecoration(
                      color: item.color,
                      borderRadius: BorderRadius.circular(14),
                      shadows: EuBrutal.smHardShadow,
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -8,
                          bottom: -12,
                          child: Transform.rotate(
                            angle: 0.35,
                            child: Icon(
                              item.icon,
                              size: 56,
                              color:
                                  (item.color.computeLuminance() > 0.5
                                          ? const Color(0xFF0D0D14)
                                          : Colors.white)
                                      .withValues(alpha: 0.28),
                            ),
                          ),
                        ),
                        Text(
                          item.title,
                          style: TextStyle(
                            // Pick ink or white by the tile's own brightness, so
                            // every label clears contrast without a hardcoded
                            // per-colour lookup.
                            color: item.color.computeLuminance() > 0.5
                                ? const Color(0xFF0D0D14)
                                : Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _SuggestionStrip extends StatelessWidget {
  const _SuggestionStrip({required this.suggestions, required this.onSelected});

  final List<String> suggestions;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < suggestions.length; i++) ...[
            ListTile(
              dense: true,
              leading: Icon(
                Icons.north_west_rounded,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              title: Text(
                suggestions[i],
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () => onSelected(suggestions[i]),
            ),
            if (i < suggestions.length - 1)
              Divider(
                height: 1,
                indent: 52,
                endIndent: 16,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
          ],
        ],
      ),
    );
  }
}

class _ResultSlivers extends StatelessWidget {
  const _ResultSlivers({
    required this.results,
    required this.activeFilter,
    required this.onFilterSelected,
  });

  final SearchResults results;
  final String? activeFilter;
  final void Function(String label, String params) onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (results.didYouMean != null) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: EuSpace.sm),
          child: Text(
            'Showing results for ${results.didYouMean}',
            style: Theme.of(context).textTheme.itemSubtitle,
          ),
        ),
      );
    }

    if (results.filters.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: EuSpace.md),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final entry in results.filters.entries) ...[
                  Builder(
                    builder: (context) {
                      final isSelected = activeFilter == entry.key;
                      final scheme = Theme.of(context).colorScheme;
                      return GestureDetector(
                        onTap: () => onFilterSelected(entry.key, entry.value),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? EuBrutal.highlight
                                : scheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? context.eu.ink
                                  : context.eu.ink.withValues(alpha: 0.35),
                              width: isSelected ? 2 : 1.5,
                            ),
                            boxShadow: isSelected
                                ? EuBrutal.smHardShadow
                                : null,
                          ),
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              color: isSelected
                                  ? EuBrutal.onHighlight
                                  : scheme.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: EuSpace.sm),
                ],
              ],
            ),
          ),
        ),
      );
    }
    if (results.topResult != null) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: EuSpace.lg),
          child: _TopResultCard(
            item: results.topResult!,
            sectionItems: results.sections.expand((s) => s.items).toList(),
          ),
        ),
      );
    }

    if (results.isEmpty) {
      children.add(const _EmptyState());
    } else {
      for (final section in results.sections) {
        if (section.items.isEmpty) continue;
        children.add(_SectionBlock(section: section));
      }
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        EuSpace.screenGutter,
        0,
        EuSpace.screenGutter,
        EuSpace.xxxl,
      ),
      sliver: SliverList.list(children: children),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.section});

  final SearchSection section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EuSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title, style: Theme.of(context).textTheme.sectionTitle),
          const SizedBox(height: EuSpace.sm),
          for (final item in section.items)
            _MusicItemTile(item: item, sectionItems: section.items),
        ],
      ),
    );
  }
}

class _TopResultCard extends ConsumerWidget {
  const _TopResultCard({required this.item, this.sectionItems});

  final MusicItem item;
  final List<MusicItem>? sectionItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: EuBrutal.boxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        shadows: EuBrutal.hardShadow,
      ),
      child: Material(
        type: MaterialType.canvas,
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navigateToItem(ref, context, item, sectionItems),
          onLongPress: () {
            if (item is SongItem) {
              showSongOptionsSheet(context, (item as SongItem).song);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(EuSpace.md),
            child: Row(
              children: [
                _Artwork(url: _artworkUrlFor(item), size: 88),
                const SizedBox(width: EuSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: EuBrutal.highlight,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: EuBrutal.onHighlight,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          'TOP MATCH',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: EuBrutal.onHighlight,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                        ),
                      ),
                      const SizedBox(height: EuSpace.xs),
                      Text(
                        _titleFor(item),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: EuSpace.xxs),
                      Text(
                        _subtitleFor(item),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.itemSubtitle
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (item is SongItem)
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: EuBrutal.accent,
                      side: BorderSide(color: context.eu.ink, width: 2),
                    ),
                    icon: const Icon(
                      Icons.play_arrow,
                      color: EuBrutal.onAccent,
                    ),
                    onPressed: () =>
                        _navigateToItem(ref, context, item, sectionItems),
                  )
                else
                  Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MusicItemTile extends ConsumerWidget {
  const _MusicItemTile({required this.item, this.sectionItems});

  final MusicItem item;
  final List<MusicItem>? sectionItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: EuSpace.sm),
      decoration: EuBrutal.boxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        shadows: EuBrutal.smHardShadow,
      ),
      child: Material(
        type: MaterialType.canvas,
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          onTap: () => _navigateToItem(ref, context, item, sectionItems),
          onLongPress: () {
            if (item is SongItem) {
              showSongOptionsSheet(context, (item as SongItem).song);
            }
          },
          minVerticalPadding: EuSpace.sm,
          leading: _Artwork(url: _artworkUrlFor(item), size: 52),
          title: Text(
            _titleFor(item),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            _subtitleFor(item),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: item is SongItem
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.play_circle_fill,
                        color: EuBrutal.accent,
                        size: 32,
                      ),
                      onPressed: () {
                        if (item is SongItem) {
                          _navigateToItem(ref, context, item, sectionItems);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, size: 22),
                      onPressed: () {
                        if (item case SongItem(:final song)) {
                          showSongOptionsSheet(context, song);
                        }
                      },
                    ),
                  ],
                )
              : const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Decode images at the actual display size (accounting for device pixel
    // ratio) instead of the full network resolution. This dramatically reduces
    // memory usage and speeds up rendering when many results appear at once.
    final cacheExtent = (size * MediaQuery.devicePixelRatioOf(context)).round();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: EuShape.artwork,
        border: Border.all(color: context.eu.ink, width: 2),
        color: scheme.surfaceContainerHighest,
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? Icon(Icons.music_note, color: scheme.onSurfaceVariant)
          : Image.network(
              url!,
              fit: BoxFit.cover,
              cacheWidth: cacheExtent,
              cacheHeight: cacheExtent,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded || frame != null) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: child,
                );
              },
              errorBuilder: (_, _, _) =>
                  Icon(Icons.music_note, color: scheme.onSurfaceVariant),
            ),
    );
  }
}

class _FailurePanel extends StatelessWidget {
  const _FailurePanel({required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(EuSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _failureTitle(failure),
              style: Theme.of(context).textTheme.sectionTitle,
            ),
            const SizedBox(height: EuSpace.xs),
            Text(
              failure.message ?? failure.toString(),
              style: Theme.of(context).textTheme.itemSubtitle,
            ),
            const SizedBox(height: EuSpace.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: EuSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.album,
            size: 44,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: EuSpace.md),
          Text('Find music', style: Theme.of(context).textTheme.sectionTitle),
          const SizedBox(height: EuSpace.xs),
          Text(
            'Search for a track, album, artist, or playlist.',
            style: Theme.of(context).textTheme.itemSubtitle,
          ),
        ],
      ),
    );
  }
}

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);
    final controller = ref.read(themeControllerProvider.notifier);

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(
        EuSpace.screenGutter,
        0,
        EuSpace.screenGutter,
        EuSpace.xl,
      ),
      children: [
        Text('Settings', style: Theme.of(context).textTheme.screenTitle),
        const SizedBox(height: EuSpace.md),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.system,
              icon: Icon(Icons.brightness_auto),
              label: Text('System'),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode),
              label: Text('Light'),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode),
              label: Text('Dark'),
            ),
          ],
          selected: {theme.mode},
          onSelectionChanged: (selection) =>
              controller.setMode(selection.first),
        ),
        Material(
          type: MaterialType.transparency,
          child: SwitchListTile(
            title: const Text('AMOLED dark'),
            value: theme.amoled,
            onChanged: (value) => controller.setAmoled(value: value),
          ),
        ),
        Material(
          type: MaterialType.transparency,
          child: SwitchListTile(
            title: const Text('Colour from artwork'),
            value: theme.source == ColourSource.artwork,
            onChanged: (value) => controller.setColourSource(
              value ? ColourSource.artwork : ColourSource.fixed,
            ),
          ),
        ),
        const Divider(height: 16),
        Material(
          type: MaterialType.transparency,
          child: ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Export Error Logs'),
            subtitle: const Text('Download log file to report issues'),
            onTap: () async {
              Navigator.of(context).pop();
              final success = await LogExporter.exportLogs();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Logs saved successfully! Share with developers.'
                          : 'Log export failed or cancelled.',
                    ),
                  ),
                );
              }
            },
          ),
        ),
        Material(
          type: MaterialType.transparency,
          child: ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('All Settings'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).pop();
              context.push('/settings');
            },
          ),
        ),
      ],
    );
  }
}

SearchFilter? _filterForLabel(String? label) => switch (label?.toLowerCase()) {
  'songs' => SearchFilter.songs,
  'videos' => SearchFilter.videos,
  'albums' => SearchFilter.albums,
  'artists' => SearchFilter.artists,
  'playlists' => SearchFilter.playlists,
  'community playlists' => SearchFilter.communityPlaylists,
  'featured playlists' => SearchFilter.featuredPlaylists,
  _ => null,
};

String _titleFor(MusicItem item) => switch (item) {
  SongItem(:final song) => song.title,
  AlbumItem(:final album) => album.title,
  ArtistItem(:final artist) => artist.name,
  PlaylistItem(:final playlist) => playlist.title,
  StationItem(:final title) => title,
};

String _subtitleFor(MusicItem item) => switch (item) {
  SongItem(:final song) => _songSubtitle(song),
  AlbumItem(:final album) => _albumSubtitle(album),
  ArtistItem(:final artist) => _artistSubtitle(artist),
  PlaylistItem(:final playlist) => _playlistSubtitle(playlist),
  StationItem() => 'Station',
};

/// Metadata lines use a middot separator, the convention every major music app
/// follows, and never repeat the row's own type. The redundant "Song" prefix is
/// dropped so a row reads "The Weeknd · After Hours", not "Song · Song".
const _dot = ' · ';

String _songSubtitle(Song song) {
  final parts = [
    if (song.kind == SongKind.video) 'Video',
    if (song.artistNames.isNotEmpty) song.artistNames,
    if (song.albumTitle != null && song.albumTitle != song.artistNames)
      song.albumTitle!,
    if (song.duration != null) _formatDuration(song.duration!),
  ];
  return parts.isEmpty ? 'Song' : parts.join(_dot);
}

String _albumSubtitle(Album album) {
  final parts = [
    'Album',
    if (album.artistNames.isNotEmpty) album.artistNames,
    if (album.year != null) album.year.toString(),
  ];
  return parts.join(_dot);
}

String _artistSubtitle(Artist artist) {
  final parts = [
    'Artist',
    if (artist.subscribers != null) '${artist.subscribers} subscribers',
  ];
  return parts.join(_dot);
}

String _playlistSubtitle(Playlist playlist) {
  final parts = [
    'Playlist',
    if (playlist.author != null) playlist.author!,
    if (playlist.trackCount != null) '${playlist.trackCount} songs',
  ];
  return parts.join(_dot);
}

String? _artworkUrlFor(MusicItem? item) => switch (item) {
  SongItem(:final song) => song.artwork?.low,
  AlbumItem(:final album) => album.artwork?.low,
  ArtistItem(:final artist) => artist.artwork?.low,
  PlaylistItem(:final playlist) => playlist.artwork?.low,
  StationItem(:final artworkUrl) => artworkUrl,
  null => null,
};

String _artworkKeyFor(MusicItem? item) => switch (item) {
  SongItem(:final song) => song.id,
  AlbumItem(:final album) => album.browseId,
  ArtistItem(:final artist) => artist.browseId,
  PlaylistItem(:final playlist) => playlist.id,
  StationItem(:final playlistId) => playlistId,
  null => 'search',
};

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

void _navigateToItem(
  WidgetRef ref,
  BuildContext context,
  MusicItem item, [
  List<MusicItem>? sectionItems,
]) {
  switch (item) {
    case SongItem(:final song):
      if (sectionItems != null) {
        final songs = sectionItems
            .whereType<SongItem>()
            .map((e) => e.song)
            .toList();
        final idx = songs.indexWhere((s) => s.id == song.id);
        if (idx >= 0) {
          ref.read(playerControllerProvider).playQueue(songs, startIndex: idx);
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
}

String _failureTitle(Failure failure) => switch (failure.kind) {
  FailureKind.network => 'Network unavailable',
  FailureKind.http => 'YouTube Music did not respond',
  FailureKind.parse => 'The response shape changed',
  FailureKind.notFound => 'Not found',
  FailureKind.unavailable => 'Unavailable',
  FailureKind.storage => 'Storage error',
  FailureKind.cancelled => 'Cancelled',
  FailureKind.unknown => 'Something went wrong',
};
