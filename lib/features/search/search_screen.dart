import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/failure.dart';
import '../../data/providers.dart';
import '../../data/remote/innertube/innertube_utils.dart';
import '../../data/repository/settings_repository.dart';
import '../../design/theme/theme_controller.dart';
import '../../design/tokens/brutal.dart';
import '../../design/tokens/tokens.dart';
import '../../design/widgets/brand_badge.dart';
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
  const SearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

enum CatalogSource { studio, community }

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
  var _catalogSource = CatalogSource.studio;

  @override
  void initState() {
    super.initState();
    final q = widget.initialQuery?.trim();
    if (q != null && q.isNotEmpty) {
      _controller.text = q;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _search(q);
      });
    }
  }

  @override
  void didUpdateWidget(SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final q = widget.initialQuery?.trim();
    if (q != null && q.isNotEmpty && q != oldWidget.initialQuery?.trim()) {
      _controller.text = q;
      _search(q);
    }
  }

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
    final effectiveFilter =
        _filterForLabel(filterLabel) ??
        (_catalogSource == CatalogSource.community
            ? SearchFilter.videos
            : null);

    final result = await repository.search(
      query,
      filter: effectiveFilter,
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const EuphonyPageCapsule(
          label: 'Explore',
          icon: Icons.search_rounded,
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.tune_rounded, size: 20),
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
                    EuSpace.xs,
                    EuSpace.screenGutter,
                    EuSpace.lg,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Compact Frosted Glass Search Bar (~44px)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.30 : 0.06,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 3),
                              ),
                              if (_focusNode.hasFocus)
                                BoxShadow(
                                  color: EuBrutal.accent.withValues(
                                    alpha: 0.22,
                                  ),
                                  blurRadius: 14,
                                  spreadRadius: -2,
                                ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0x65161626)
                                      : Colors.white.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _focusNode.hasFocus
                                        ? EuBrutal.accent
                                        : (isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.12,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.08,
                                                )),
                                    width: _focusNode.hasFocus ? 1.4 : 1.0,
                                  ),
                                ),
                                child: SearchBar(
                                  constraints: const BoxConstraints(
                                    minHeight: 44.0,
                                    maxHeight: 44.0,
                                  ),
                                  padding: const WidgetStatePropertyAll(
                                    EdgeInsets.symmetric(horizontal: 14.0),
                                  ),
                                  elevation: const WidgetStatePropertyAll(0),
                                  backgroundColor: const WidgetStatePropertyAll(
                                    Colors.transparent,
                                  ),
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  hintText: 'Songs, albums, artists...',
                                  hintStyle: WidgetStatePropertyAll(
                                    TextStyle(
                                      fontSize: 13.5,
                                      color: isDark
                                          ? Colors.white38
                                          : Colors.black38,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  textStyle: WidgetStatePropertyAll(
                                    TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  leading: const Icon(
                                    Icons.search_rounded,
                                    size: 20,
                                    color: EuBrutal.accent,
                                  ),
                                  trailing: [
                                    if (_controller.text.isNotEmpty)
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        iconSize: 18,
                                        tooltip: 'Clear',
                                        icon: const Icon(Icons.close_rounded),
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
                            ),
                          ),
                        ),
                        const SizedBox(height: EuSpace.sm),
                        _buildCatalogSourceSwitcher(context),
                        const SizedBox(height: EuSpace.sm),
                        if (_loadingSuggestions)
                          const LinearProgressIndicator(),
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
                        onRetry: () => _search(
                          _controller.text,
                          filterLabel: _activeFilter,
                        ),
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
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.70),
      builder: (_) => const _SettingsSheet(),
    );
  }

  Widget _buildCatalogSourceSwitcher(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.09)
              : Colors.black.withValues(alpha: 0.07),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CatalogSourcePill(
              label: 'Studio Master',
              subtitle: 'Official & Hi-Fi',
              icon: Icons.verified_rounded,
              isSelected: _catalogSource == CatalogSource.studio,
              accentColor: EuBrutal.accent,
              onTap: () {
                if (_catalogSource == CatalogSource.studio) return;
                setState(() => _catalogSource = CatalogSource.studio);
                if (_controller.text.trim().isNotEmpty) {
                  _search(_controller.text);
                }
              },
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: _CatalogSourcePill(
              label: 'Live & Acoustic',
              subtitle: 'Covers & Rare Cuts',
              icon: Icons.graphic_eq_rounded,
              isSelected: _catalogSource == CatalogSource.community,
              accentColor: const Color(0xFFF59E0B),
              onTap: () {
                if (_catalogSource == CatalogSource.community) return;
                setState(() => _catalogSource = CatalogSource.community);
                if (_controller.text.trim().isNotEmpty) {
                  _search(_controller.text);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogSourcePill extends StatelessWidget {
  const _CatalogSourcePill({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.fastOutSlowIn,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? accentColor.withValues(alpha: 0.18)
                    : accentColor.withValues(alpha: 0.12))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: isSelected
                ? accentColor.withValues(alpha: 0.8)
                : Colors.transparent,
            width: isSelected ? 1.2 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.20),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor
                    : (isDark ? Colors.white12 : Colors.black12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 13,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? (isDark ? Colors.white : Colors.black87)
                          : (isDark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? accentColor
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
                    Material(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => onSelected(row.query),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
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
                                behavior: HitTestBehavior.opaque,
                                onTap: () => dao.remove(row.query),
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 15,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                  behavior: HitTestBehavior.opaque,
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
      child: Material(
        type: MaterialType.canvas,
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
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
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.4,
                  ),
                ),
            ],
          ],
        ),
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
                      final theme = Theme.of(context);
                      final isDark = theme.brightness == Brightness.dark;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          onFilterSelected(entry.key, entry.value);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? EuBrutal.accent
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.black.withValues(alpha: 0.05)),
                            borderRadius: BorderRadius.circular(14),
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
                                      color: EuBrutal.accent.withValues(
                                        alpha: 0.32,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 12,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: EuBrutal.accent.withValues(alpha: isDark ? 0.16 : 0.10),
            blurRadius: 18,
            spreadRadius: -4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0x85161628)
                  : Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.14)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1.0,
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
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
                      _Artwork(url: _artworkUrlFor(item), size: 84),
                      const SizedBox(width: EuSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [EuBrutal.accent, Color(0xFF9060FA)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: EuBrutal.accent.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'TOP MATCH',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 9.5,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: EuSpace.xs),
                            Text(
                              _titleFor(item),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: EuSpace.xxs),
                            Text(
                              _subtitleFor(item),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.itemSubtitle?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (item is SongItem)
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [EuBrutal.accent, Color(0xFF7B3FE4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: EuBrutal.accent.withValues(alpha: 0.40),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                            onPressed: () => _navigateToItem(
                              ref,
                              context,
                              item,
                              sectionItems,
                            ),
                          ),
                        )
                      else
                        Icon(
                          Icons.chevron_right_rounded,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                    ],
                  ),
                ),
              ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0x60161626)
            : Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.06),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _navigateToItem(ref, context, item, sectionItems),
          onLongPress: () {
            if (item is SongItem) {
              showSongOptionsSheet(context, (item as SongItem).song);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                _Artwork(url: _artworkUrlFor(item), size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _titleFor(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _subtitleFor(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item is SongItem)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.play_circle_fill_rounded,
                          color: EuBrutal.accent,
                          size: 32,
                        ),
                        onPressed: () =>
                            _navigateToItem(ref, context, item, sectionItems),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          size: 20,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                        onPressed: () {
                          if (item case SongItem(:final song)) {
                            showSongOptionsSheet(context, song);
                          }
                        },
                      ),
                    ],
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
              ],
            ),
          ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Decode images at the actual display size (accounting for device pixel
    // ratio) instead of the full network resolution. This dramatically reduces
    // memory usage and speeds up rendering when many results appear at once.
    final cacheExtent = (size * MediaQuery.devicePixelRatioOf(context)).round();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size > 60 ? 16 : 12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.16)
              : Colors.black.withValues(alpha: 0.08),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: size > 60 ? 12 : 8,
            offset: const Offset(0, 3),
          ),
        ],
        color: scheme.surfaceContainerHighest,
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? Icon(Icons.music_note_rounded, color: scheme.onSurfaceVariant)
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xF210101A) : const Color(0xF8F8FAFD),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.90),
              width: 1.2,
            ),
          ),
        ),
        child: SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(
              EuSpace.screenGutter,
              EuSpace.sm,
              EuSpace.screenGutter,
              EuSpace.xl,
            ),
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 4, bottom: 12),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: EuSpace.md),
                child: Text(
                  'QUICK SETTINGS',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
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
                  title: Text(
                    'AMOLED dark',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  value: theme.amoled,
                  onChanged: (value) => controller.setAmoled(value: value),
                ),
              ),
              Material(
                type: MaterialType.transparency,
                child: SwitchListTile(
                  title: Text(
                    'Colour from artwork',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  value: theme.source == ColourSource.artwork,
                  onChanged: (value) => controller.setColourSource(
                    value ? ColourSource.artwork : ColourSource.fixed,
                  ),
                ),
              ),
              Divider(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                height: 16,
              ),
              Material(
                type: MaterialType.transparency,
                child: ListTile(
                  leading: Icon(
                    Icons.bug_report_outlined,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  title: Text(
                    'Export Error Logs',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    'Download log file to report issues',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.black54,
                    ),
                  ),
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
                  leading: const Icon(
                    Icons.settings_outlined,
                    color: EuBrutal.accent,
                  ),
                  title: Text(
                    'All Settings',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: isDark ? Colors.white54 : Colors.black38,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push('/settings');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
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
const _dot = ' \u00b7 ';

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
