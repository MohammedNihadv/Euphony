import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    HardwareKeyboard.instance.addHandler(_handleGlobalKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) UpdatePrompt.maybeShowOnLaunch(context, ref);
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKey);
    super.dispose();
  }

  bool _handleGlobalKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final key = event.logicalKey;
    final controller = ref.read(playerControllerProvider);
    final player = ref.read(audioPlayerProvider);

    final isDedicatedMediaKey =
        key == LogicalKeyboardKey.mediaPlayPause ||
        key == LogicalKeyboardKey.mediaPlay ||
        key == LogicalKeyboardKey.mediaPause ||
        key == LogicalKeyboardKey.mediaTrackNext ||
        key == LogicalKeyboardKey.mediaTrackPrevious ||
        key == LogicalKeyboardKey.mediaFastForward ||
        key == LogicalKeyboardKey.mediaRewind ||
        key == LogicalKeyboardKey.mediaStop ||
        key == LogicalKeyboardKey.mediaSkip;

    // Do not intercept text editing keys if user is typing in a text field
    if (!isDedicatedMediaKey) {
      final primaryFocus = FocusManager.instance.primaryFocus;
      if (primaryFocus != null && primaryFocus.context != null) {
        final widget = primaryFocus.context!.widget;
        if (widget is EditableText) {
          return false;
        }
      }
    }

    final isShiftOrCtrl =
        HardwareKeyboard.instance.isShiftPressed ||
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    // 1. Play / Pause / Resume
    if (key == LogicalKeyboardKey.mediaPlayPause ||
        key == LogicalKeyboardKey.mediaPlay ||
        key == LogicalKeyboardKey.mediaPause ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.keyK) {
      controller.togglePlayPause();
      return true;
    }

    // 2. Stop
    if (key == LogicalKeyboardKey.mediaStop) {
      controller.stop();
      return true;
    }

    // 3. Skip to Next track
    if (key == LogicalKeyboardKey.mediaTrackNext ||
        key == LogicalKeyboardKey.mediaSkip ||
        (isShiftOrCtrl && (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyN))) {
      controller.skipNext();
      return true;
    }

    // 4. Skip to Previous track
    if (key == LogicalKeyboardKey.mediaTrackPrevious ||
        (isShiftOrCtrl && (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyP))) {
      controller.skipPrevious();
      return true;
    }

    // 5. Fast-Forward (10s)
    if (key == LogicalKeyboardKey.mediaFastForward ||
        key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyL) {
      final pos = player.position;
      final total = player.duration ?? Duration.zero;
      final target = pos + const Duration(seconds: 10);
      controller.seek(target > total ? total : target);
      return true;
    }

    // 6. Rewind / Backward (10s)
    if (key == LogicalKeyboardKey.mediaRewind ||
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.keyJ) {
      final pos = player.position;
      final target = pos - const Duration(seconds: 10);
      controller.seek(target < Duration.zero ? Duration.zero : target);
      return true;
    }

    return false;
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
      body: Stack(
        children: [
          Positioned.fill(child: navigationShell),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _GlassBrutalNavBar(
              selectedIndex: navigationShell.currentIndex,
              onSelected: _goBranch,
            ),
          ),
        ],
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

    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini player sits above the nav bar
          const MiniPlayer(),

          // Floating rounded capsule navigation bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Container(
              height: 62,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.14),
                    offset: const Offset(0, 10),
                    blurRadius: 28,
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: isDark ? 0.06 : 0.03,
                    ),
                    offset: const Offset(0, 2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0x80141422)
                          : Colors.white.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.16)
                            : Colors.white.withValues(alpha: 0.85),
                        width: 1.2,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (int i = 0; i < _destinations.length; i++)
                          _buildNavItem(
                            context: context,
                            index: i,
                            dest: _destinations[i],
                            isSelected: i == selectedIndex,
                            isDark: isDark,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required _Dest dest,
    required bool isSelected,
    required bool isDark,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 8,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: isSelected ? EuBrutal.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? context.eu.ink.withValues(alpha: isDark ? 0.7 : 0.9)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: EuBrutal.accent.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: Offset.zero,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? dest.selectedIcon : dest.icon,
              size: 20,
              color: isSelected
                  ? EuBrutal.onAccent
                  : context.eu.ink.withValues(alpha: 0.7),
            ),
            if (isSelected) ...[
              const SizedBox(width: 5),
              Text(
                dest.label,
                style: const TextStyle(
                  color: EuBrutal.onAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ],
        ),
      ),
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
