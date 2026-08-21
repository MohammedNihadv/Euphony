import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/tokens/brutal.dart';
import '../design/widgets/brand_badge.dart';
import '../features/player/mini_player.dart';
import '../playback/player_provider.dart';
import 'update_prompt.dart';

/// One navigation destination, shared by the mobile bottom bar and the desktop
/// side rail so both stay in sync.
class _Dest {
  const _Dest(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const _destinations = <_Dest>[
  _Dest(Icons.home_outlined, Icons.home, 'Home'),
  _Dest(Icons.search_outlined, Icons.search, 'Search'),
  _Dest(Icons.my_library_music_outlined, Icons.my_library_music, 'Library'),
  _Dest(Icons.settings_outlined, Icons.settings, 'Settings'),
];

/// Below this width the app uses the phone layout (bottom nav); at or above it
/// switches to the desktop layout (left sidebar + full-width player bar), which
/// is what suits a resizable window on Windows, macOS and Linux.
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
    // Once the first frame is up, check for a newer release and prompt. This
    // is what makes update popups reach users who never open Settings.
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
    // A track that will not resolve used to fail silently — the user tapped a
    // song and nothing happened, which reads as the app being broken. Reported
    // once here rather than in each screen that can start playback.
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

  // -- Phone layout: bottom navigation with the mini player above it. --------
  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          Container(
            decoration: BoxDecoration(
              color: context.eu.ink,
              border: Border(
                top: BorderSide(color: context.eu.ink, width: 2.5),
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                navigationBarTheme: NavigationBarThemeData(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  indicatorColor: EuBrutal.accent,
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: EuBrutal.accent,
                      );
                    }
                    return const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    );
                  }),
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const IconThemeData(
                        color: EuBrutal.onAccent,
                        size: 24,
                      );
                    }
                    return const IconThemeData(size: 24);
                  }),
                ),
              ),
              child: NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _goBranch,
                destinations: [
                  for (final d in _destinations)
                    NavigationDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: d.label,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -- Desktop layout: fixed sidebar + content, player bar spanning the bottom.
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
                Expanded(
                  child: ClipRect(child: navigationShell),
                ),
              ],
            ),
          ),
          // Full-width player bar across the bottom, like a desktop player.
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

/// The desktop navigation rail: brand at the top, then the destinations as a
/// column of highlightable rows.
class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 232,
      decoration: BoxDecoration(
        color: context.eu.surface,
        border: Border(
          right: BorderSide(color: context.eu.divider, width: 1.5),
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
        color: selected ? EuBrutal.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(selected ? dest.selectedIcon : dest.icon, color: fg, size: 22),
                const SizedBox(width: 14),
                Text(
                  dest.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
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
