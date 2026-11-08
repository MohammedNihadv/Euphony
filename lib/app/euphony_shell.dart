import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/tokens/brutal.dart';
import '../design/widgets/brand_badge.dart';
import '../domain/song.dart';
import '../features/library/library_screen.dart';
import '../features/player/desktop_mini_player_hud.dart';
import '../features/player/desktop_player_bar.dart';
import '../features/player/dynamic_island.dart';
import '../features/player/lyrics_sheet.dart';
import '../features/player/mini_player.dart';
import '../features/player/player_screen.dart';
import '../features/player/queue_sheet.dart';
import '../features/settings/settings_provider.dart';
import '../playback/desktop_media_controls.dart';
import '../playback/player_provider.dart';


class _Dest {
  const _Dest(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const _destinations = <_Dest>[
  _Dest(Icons.home_outlined, Icons.home_rounded, 'Home'),
  _Dest(Icons.search_outlined, Icons.search_rounded, 'Search'),
  _Dest(
    Icons.my_library_music_outlined,
    Icons.my_library_music_rounded,
    'Library',
  ),
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
    final volumeNotifier = ref.read(playerVolumeProvider.notifier);

    // 1. Dedicated hardware / bluetooth / headset media keys always work anywhere.
    // Note: On Windows, VK_MEDIA_PLAY_PAUSE (0xB3) is mapped by Flutter's HID translation table
    // to LogicalKeyboardKey.mediaFastForward (HID usage 0x00B3 = Fast Forward).
    // SMTC on Windows handles these OS-level media keys directly (both foreground and background).
    // If we also trigger playback actions here while the window is focused on Windows, the
    // duplicate event fired within milliseconds causes play/pause to immediately invert itself.
    // Therefore, on Windows we consume dedicated media keys here so SMTC handles them cleanly.
    if (key == LogicalKeyboardKey.mediaPlayPause ||
        key == LogicalKeyboardKey.mediaPlay ||
        key == LogicalKeyboardKey.mediaPause ||
        key == LogicalKeyboardKey.mediaFastForward ||
        event.physicalKey == PhysicalKeyboardKey.mediaPlayPause) {
      if (!kIsWeb && Platform.isWindows) {
        return true;
      }
      controller.togglePlayPause();
      return true;
    }
    if (key == LogicalKeyboardKey.mediaStop) {
      if (!kIsWeb && Platform.isWindows) {
        return true;
      }
      controller.stop();
      return true;
    }
    if (key == LogicalKeyboardKey.mediaTrackNext ||
        key == LogicalKeyboardKey.mediaSkip ||
        event.physicalKey == PhysicalKeyboardKey.mediaTrackNext) {
      if (!kIsWeb && Platform.isWindows) {
        return true;
      }
      controller.skipNext();
      return true;
    }
    if (key == LogicalKeyboardKey.mediaTrackPrevious ||
        event.physicalKey == PhysicalKeyboardKey.mediaTrackPrevious) {
      if (!kIsWeb && Platform.isWindows) {
        return true;
      }
      controller.skipPrevious();
      return true;
    }

    // 2. Guard: if user is typing into any text input field (e.g. search bar, dialogs),
    // NEVER intercept bare letters (m, l, q, f) or bare space!
    final focus = FocusManager.instance.primaryFocus;
    final ctx = focus?.context;
    bool isEditing = false;
    if (ctx != null) {
      if (ctx.widget is EditableText ||
          ctx.findAncestorWidgetOfExactType<EditableText>() != null ||
          ctx.findAncestorWidgetOfExactType<TextField>() != null ||
          ctx.findAncestorWidgetOfExactType<TextFormField>() != null) {
        isEditing = true;
      }
    }

    if (isEditing) {
      // While typing in an input field, only allow Ctrl-modified playback shortcuts:
      if (HardwareKeyboard.instance.isControlPressed) {
        if (key == LogicalKeyboardKey.arrowRight) {
          controller.skipNext();
          return true;
        }
        if (key == LogicalKeyboardKey.arrowLeft) {
          controller.skipPrevious();
          return true;
        }
        if (key == LogicalKeyboardKey.arrowUp) {
          volumeNotifier.stepUp();
          return true;
        }
        if (key == LogicalKeyboardKey.arrowDown) {
          volumeNotifier.stepDown();
          return true;
        }
      }
      // Return false so the key event passes directly to the focused input field!
      return false;
    }

    // 3. Desktop shortcuts when NOT typing into an input field:
    if (HardwareKeyboard.instance.isControlPressed) {
      if (key == LogicalKeyboardKey.arrowRight) {
        controller.skipNext();
        return true;
      }
      if (key == LogicalKeyboardKey.arrowLeft) {
        controller.skipPrevious();
        return true;
      }
      if (key == LogicalKeyboardKey.arrowUp) {
        volumeNotifier.stepUp();
        return true;
      }
      if (key == LogicalKeyboardKey.arrowDown) {
        volumeNotifier.stepDown();
        return true;
      }
      if (key == LogicalKeyboardKey.keyF) {
        _goBranch(1);
        return true;
      }
      if (key == LogicalKeyboardKey.keyM) {
        DesktopMediaControls().toggleMiniPlayer();
        return true;
      }
      if (key == LogicalKeyboardKey.digit1) {
        _goBranch(0);
        return true;
      }
      if (key == LogicalKeyboardKey.digit2) {
        _goBranch(1);
        return true;
      }
      if (key == LogicalKeyboardKey.digit3) {
        _goBranch(2);
        return true;
      }
      if (key == LogicalKeyboardKey.digit4) {
        _goBranch(3);
        return true;
      }
      return false;
    }

    // Bare keys when browsing (NOT focused on a text box):
    if (key == LogicalKeyboardKey.space) {
      controller.togglePlayPause();
      return true;
    }
    if (key == LogicalKeyboardKey.keyM) {
      volumeNotifier.toggleMute();
      return true;
    }
    if (key == LogicalKeyboardKey.keyL) {
      final song = ref.read(activeSongProvider);
      if (song != null) showLyricsSheet(context, song);
      return true;
    }
    if (key == LogicalKeyboardKey.keyQ) {
      showQueueSheet(context);
      return true;
    }
    if (key == LogicalKeyboardKey.keyF) {
      final song = ref.read(activeSongProvider);
      if (song != null) {
        Navigator.of(context, rootNavigator: true).push(buildPlayerRoute());
      }
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
    // Dynamically update desktop OS window caption with current playing song
    ref.listen<Song?>(activeSongProvider, (previous, next) {
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        final title = next != null
            ? '${next.title} • ${next.artistNames} — Euphony'
            : 'Euphony';
        SystemChrome.setApplicationSwitcherDescription(
          ApplicationSwitcherDescription(label: title),
        );
      }
    });

    ref.listen<String?>(playbackErrorProvider, (previous, next) {
      if (next == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(next), behavior: SnackBarBehavior.floating),
        );
      ref.read(playbackErrorProvider.notifier).clear();
    });

    return ValueListenableBuilder<bool>(
      valueListenable: DesktopMediaControls.isMiniPlayer,
      builder: (context, isMini, child) {
        if (isMini &&
            !kIsWeb &&
            (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
          return const Scaffold(
            backgroundColor: Color(0xFF101018),
            body: DesktopMiniPlayerHud(),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= _desktopBreakpoint) {
              return _buildDesktop(context);
            }
            return _buildMobile(context);
          },
        );
      },
    );
  }

  // ── Mobile: glass nav bar floating over content ─────────────────────────
  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          navigationShell,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _GlassBrutalNavBar(
              selectedIndex: navigationShell.currentIndex,
              onSelected: _goBranch,
            ),
          ),
          const Positioned.fill(child: DynamicIsland()),
        ],
      ),
    );
  }

  // ── Desktop: glass sidebar + content + full-width desktop player bar ────
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
          const DesktopPlayerBar(),
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
    final settings = ref.watch(settingsControllerProvider);
    final showMiniPlayer = !settings.dynamicIsland;

    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mini player sits above the nav bar when Dynamic Island is disabled or not docked
          if (showMiniPlayer) const MiniPlayer(),

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
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

class _DesktopSidebar extends ConsumerWidget {
  const _DesktopSidebar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 236,
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
                    shortcut: 'Ctrl+${i + 1}',
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                  ),

                // ── Divider & Collection Header ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1.5,
                          color: context.eu.divider.withValues(alpha: 0.7),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'YOUR MUSIC',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: context.eu.ink.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1.5,
                          color: context.eu.divider.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Quick Collection Links ───────────────────────────────────
                _QuickCollectionItem(
                  icon: Icons.favorite_rounded,
                  iconColor: EuBrutal.alert,
                  label: 'Liked Songs',
                  onTap: () {
                    ref.read(librarySelectedTabProvider.notifier).selectTab(0);
                    onSelected(2);
                  },
                ),
                _QuickCollectionItem(
                  icon: Icons.download_done_rounded,
                  iconColor: EuBrutal.accent,
                  label: 'Downloads',
                  onTap: () {
                    ref.read(librarySelectedTabProvider.notifier).selectTab(1);
                    onSelected(2);
                  },
                ),
                _QuickCollectionItem(
                  icon: Icons.queue_music_rounded,
                  iconColor: isDark ? Colors.amberAccent : Colors.orange,
                  label: 'Playlists',
                  onTap: () {
                    ref.read(librarySelectedTabProvider.notifier).selectTab(2);
                    onSelected(2);
                  },
                ),
                _QuickCollectionItem(
                  icon: Icons.history_rounded,
                  iconColor: context.eu.ink.withValues(alpha: 0.7),
                  label: 'History',
                  onTap: () {
                    ref.read(librarySelectedTabProvider.notifier).selectTab(4);
                    onSelected(2);
                  },
                ),

                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Text(
                        'Euphony Desktop',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: context.eu.ink.withValues(alpha: 0.4),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: EuBrutal.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: EuBrutal.accent, width: 1),
                        ),
                        child: const Text(
                          'v1.0.1',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: EuBrutal.accent,
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
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.dest,
    required this.shortcut,
    required this.selected,
    required this.onTap,
  });

  final _Dest dest;
  final String shortcut;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? EuBrutal.onAccent : context.eu.ink;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Tooltip(
        message: '${dest.label} ($shortcut)',
        waitDuration: const Duration(milliseconds: 500),
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
                  Expanded(
                    child: Text(
                      dest.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                        color: fg,
                      ),
                    ),
                  ),
                  if (selected)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickCollectionItem extends StatefulWidget {
  const _QuickCollectionItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  @override
  State<_QuickCollectionItem> createState() => _QuickCollectionItemState();
}

class _QuickCollectionItemState extends State<_QuickCollectionItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _hovered
                  ? context.eu.ink.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(widget.icon, size: 18, color: widget.iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.eu.ink.withValues(alpha: 0.85),
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
