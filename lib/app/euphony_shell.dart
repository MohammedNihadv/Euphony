import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/tokens/brutal.dart';
import '../design/widgets/brand_badge.dart';
import '../features/player/mini_player.dart';
import '../playback/player_provider.dart';
import 'update_prompt.dart';

class _Dest {
  const _Dest(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const _destinations = <_Dest>[
  _Dest(Icons.home_outlined, Icons.home_rounded, 'Home'),
  _Dest(Icons.search_outlined, Icons.search_rounded, 'Search'),
  _Dest(Icons.my_library_music_outlined, Icons.my_library_music_rounded, 'Library'),
  _Dest(Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
];

const double _desktopBreakpoint = 900;

class EuphonyShell extends ConsumerStatefulWidget {
  const EuphonyShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<EuphonyShell> createState() => _EuphonyShellState();
}

class _EuphonyShellState extends ConsumerState<EuphonyShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) UpdatePrompt.maybeShowOnLaunch(context, ref);
    });
  }

  StatefulNavigationShell get navigationShell => widget.navigationShell;

  void _goBranch(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(playbackErrorProvider, (previous, next) {
      if (next == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(next), behavior: SnackBarBehavior.floating),
        );
      ref.read(playbackErrorProvider.notifier).clear();
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _desktopBreakpoint) {
          return _buildDesktop(context);
        }
        return _buildMobile(context);
      },
    );
  }

  // ── Mobile: glass nav bar floating over content ─────────────────────────
  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: _GlassBrutalNavBar(
        selectedIndex: navigationShell.currentIndex,
        onSelected: _goBranch,
      ),
    );
  }

  // ── Desktop: glass sidebar + content + full-width player bar ─────────────
  Widget _buildDesktop(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DesktopSidebar(
                  selectedIndex: navigationShell.currentIndex,
                  onSelected: _goBranch,
                ),
                Expanded(child: ClipRect(child: navigationShell)),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: context.eu.divider, width: 1.5),
              ),
            ),
            child: const MiniPlayer(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _GlassBrutalNavBar — mobile bottom navigation
// Neo-Brutalist shell (hard shadow + thick top border) + glass interior
// ---------------------------------------------------------------------------

class _GlassBrutalNavBar extends ConsumerWidget {
  const _GlassBrutalNavBar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mini player sits above the nav bar
        const MiniPlayer(),

        // Glass nav bar with brutalist top border
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                // Frosted glass fill with subtle tint
                color: isDark
                    ? const Color(0xFF12121C).withValues(alpha: 0.82)
                    : Colors.white.withValues(alpha: 0.82),
                // Brutalist top border — the visual "frame" of the nav slab
                border: Border(
                  top: BorderSide(color: context.eu.ink, width: 2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.35)
                        : Colors.black.withValues(alpha: 0.06),
                    offset: const Offset(0, -3),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Theme(
                data: theme.copyWith(
                  navigationBarTheme: NavigationBarThemeData(
                    labelTextStyle: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return TextStyle(
                          color: context.eu.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        );
                      }
                      return TextStyle(
                        color: context.eu.ink.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      );
                    }),
                  ),
                ),
                child: NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onSelected,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  indicatorColor: EuBrutal.accent,
                  labelBehavior:
                      NavigationDestinationLabelBehavior.onlyShowSelected,
                  destinations: [
                    for (final d in _destinations)
                      NavigationDestination(
                        icon: Icon(
                          d.icon,
                          color: context.eu.ink.withValues(alpha: 0.7),
                        ),
                        selectedIcon: Icon(
                          d.selectedIcon,
                          color: EuBrutal.onAccent,
                        ),
                        label: d.label,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop sidebar — glass panel + brutalist right border
// ---------------------------------------------------------------------------

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 232,
          decoration: BoxDecoration(
            // Glass fill
            color: isDark
                ? theme.colorScheme.surface.withValues(alpha: 0.75)
                : Colors.white.withValues(alpha: 0.7),
            // Brutalist right border
            border: Border(
              right: BorderSide(color: context.eu.ink, width: 1.5),
            ),
          ),
          child: SafeArea(
            right: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 24, 20, 20),
                  child: EuphonyBrandBadge(fontSize: 22),
                ),
                for (var i = 0; i < _destinations.length; i++)
                  _SidebarItem(
                    dest: _destinations[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                  ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Euphony',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: context.eu.ink.withValues(alpha: 0.35),
                    ),
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

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.dest,
    required this.selected,
    required this.onTap,
  });

  final _Dest dest;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? EuBrutal.onAccent : context.eu.ink;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              // Accent fill for selected — brutalist solid colour
              color: selected ? EuBrutal.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              // Hard shadow only when selected
              boxShadow: selected ? EuBrutal.smHardShadow : null,
            ),
            child: Row(
              children: [
                Icon(
                  selected ? dest.selectedIcon : dest.icon,
                  color: fg,
                  size: 22,
                ),
                const SizedBox(width: 14),
                Text(
                  dest.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        selected ? FontWeight.w900 : FontWeight.w700,
                    color: fg,
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
