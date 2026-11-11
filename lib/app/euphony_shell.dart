import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/tokens/brutal.dart';
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

  void _goBranch(int index) {
    if (index != navigationShell.currentIndex) {
      HapticFeedback.selectionClick();
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

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
            backgroundColor: Color(0xFF111118),
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

  // ── Desktop: floating sidebar rail + rounded content panel + desktop player bar ────
  Widget _buildDesktop(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF1F3F7),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DesktopSidebar(
                    selectedIndex: navigationShell.currentIndex,
                    onSelected: _goBranch,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.06),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: navigationShell,
                      ),
                    ),
                  ),
                ],
              ),
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
                  // Expansive floating drop shadow
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.10),
                    offset: const Offset(0, 10),
                    blurRadius: 28,
                    spreadRadius: -2,
                  ),
                  // Caustic tight contact shadow
                  BoxShadow(
                    color: (isDark ? Colors.black : const Color(0xFF0F172A)).withValues(
                      alpha: isDark ? 0.25 : 0.05,
                    ),
                    offset: const Offset(0, 4),
                    blurRadius: 8,
                    spreadRadius: -1,
                  ),
                  // Upper specular crest light for liquid curvature
                  BoxShadow(
                    color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.85),
                    offset: const Offset(0, 1.5),
                    blurRadius: 1,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(34),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    decoration: BoxDecoration(
                      // Liquid Glass gradient: glossy surface reflection + crystal water core + bottom meniscus
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.22, 0.78, 1.0],
                        colors: isDark
                            ? [
                                Colors.white.withValues(alpha: 0.20),
                                const Color(0xFF1C1C2C).withValues(alpha: 0.32),
                                const Color(0xFF101018).withValues(alpha: 0.22),
                                const Color(0xFF28283E).withValues(alpha: 0.28),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.50),
                                Colors.white.withValues(alpha: 0.16),
                                const Color(0xFFE2E8F0).withValues(alpha: 0.08),
                                Colors.white.withValues(alpha: 0.25),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(34),
                      // Luminous liquid glass rim border
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.28)
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
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
                ? (isDark
                    ? Colors.white.withValues(alpha: 0.30)
                    : EuBrutal.accentDeep)
                : Colors.transparent,
            width: 1.2,
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
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 68),
                child: Text(
                  dest.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: EuBrutal.onAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
  }
}

// ---------------------------------------------------------------------------
// Desktop sidebar — unified collapsible rail & drawer
// Strictly adheres to Euphony design tokens & color codes
// ---------------------------------------------------------------------------

class _DesktopSidebar extends ConsumerStatefulWidget {
  const _DesktopSidebar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  ConsumerState<_DesktopSidebar> createState() => _DesktopSidebarState();
}

class _DesktopSidebarState extends ConsumerState<_DesktopSidebar> {
  bool _collapsed = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = _collapsed ? 76.0 : 236.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOutCubic,
      width: width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF13131A).withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: SafeArea(
            right: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isExpanded = !_collapsed && constraints.maxWidth > 180;
                return _buildSidebarContent(
                  context,
                  isDark,
                  isExpanded,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarContent(
    BuildContext context,
    bool isDark,
    bool isExpanded,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        // Top Brand Header
        _buildBrandHeader(context, isDark, isExpanded),
        const SizedBox(height: 10),

        // Scrollable Navigation & Quick Collections Area
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Primary Navigation Destinations (Home, Search, Library, Settings)
                for (int i = 0; i < _destinations.length; i++)
                  _DesktopSidebarItem(
                    icon: i == widget.selectedIndex
                        ? _destinations[i].selectedIcon
                        : _destinations[i].icon,
                    label: _destinations[i].label,
                    isExpanded: isExpanded,
                    selected: i == widget.selectedIndex,
                    shortcut: 'Ctrl+${i + 1}',
                    onTap: () => widget.onSelected(i),
                  ),

                // Thin sleek divider line
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeInOutCubic,
                      width: isExpanded ? 204.0 : 32.0,
                      height: 1.2,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                ),

                // Quick Collection Items (YOUR MUSIC)
                _DesktopSidebarItem(
                  icon: Icons.favorite_rounded,
                  iconColor: EuBrutal.alert,
                  label: 'Liked Songs',
                  isExpanded: isExpanded,
                  selected: false,
                  onTap: () {
                    ref.read(librarySelectedTabProvider.notifier).selectTab(0);
                    widget.onSelected(2);
                  },
                ),
                _DesktopSidebarItem(
                  icon: Icons.download_done_rounded,
                  label: 'Downloads',
                  isExpanded: isExpanded,
                  selected: false,
                  onTap: () {
                    ref.read(librarySelectedTabProvider.notifier).selectTab(1);
                    widget.onSelected(2);
                  },
                ),
                _DesktopSidebarItem(
                  icon: Icons.queue_music_rounded,
                  label: 'Playlists',
                  isExpanded: isExpanded,
                  selected: false,
                  onTap: () {
                    ref.read(librarySelectedTabProvider.notifier).selectTab(2);
                    widget.onSelected(2);
                  },
                ),
                _DesktopSidebarItem(
                  icon: Icons.history_rounded,
                  label: 'History',
                  isExpanded: isExpanded,
                  selected: false,
                  onTap: () {
                    ref.read(librarySelectedTabProvider.notifier).selectTab(4);
                    widget.onSelected(2);
                  },
                ),
              ],
            ),
          ),
        ),

        // Bottom Expand / Collapse Toggle Button
        _DesktopSidebarItem(
          icon: _collapsed
              ? Icons.keyboard_double_arrow_right_rounded
              : Icons.keyboard_double_arrow_left_rounded,
          label: 'Collapse',
          isExpanded: isExpanded,
          selected: false,
          iconColor: isDark ? Colors.white60 : Colors.black54,
          onTap: () => setState(() => _collapsed = !_collapsed),
        ),

        // Version badge when open
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
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
                    'v1.0.2',
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
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildBrandHeader(
    BuildContext context,
    bool isDark,
    bool isExpanded,
  ) {
    return SizedBox(
      height: 48,
      child: Tooltip(
        message: _collapsed ? 'Expand sidebar' : 'Euphony',
        waitDuration: const Duration(milliseconds: 350),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (_collapsed) {
              setState(() => _collapsed = false);
            }
          },
          child: isExpanded
              ? Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: [
                            BoxShadow(
                              color: EuBrutal.accent.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/images/app.icon.png',
                          width: 38,
                          height: 38,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Euphony',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    IconButton(
                      iconSize: 20,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      icon: Icon(
                        Icons.keyboard_double_arrow_left_rounded,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      tooltip: 'Collapse sidebar',
                      onPressed: () => setState(() => _collapsed = true),
                    ),
                    const SizedBox(width: 6),
                  ],
                )
              : Center(
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: [
                        BoxShadow(
                          color: EuBrutal.accent.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/images/app.icon.png',
                      width: 38,
                      height: 38,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _DesktopSidebarItem extends StatefulWidget {
  const _DesktopSidebarItem({
    required this.icon,
    required this.label,
    required this.isExpanded,
    required this.selected,
    required this.onTap,
    this.iconColor,
    this.shortcut,
  });

  final IconData icon;
  final String label;
  final bool isExpanded;
  final bool selected;
  final VoidCallback onTap;
  final Color? iconColor;
  final String? shortcut;

  @override
  State<_DesktopSidebarItem> createState() => _DesktopSidebarItemState();
}

class _DesktopSidebarItemState extends State<_DesktopSidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveIconColor = widget.selected
        ? EuBrutal.onAccent
        : (widget.iconColor ??
            (_hovered
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? Colors.white70 : Colors.black87)));

    final effectiveTextColor = widget.selected
        ? EuBrutal.onAccent
        : context.eu.ink;

    final tooltipMessage = widget.shortcut != null
        ? '${widget.label} (${widget.shortcut})'
        : widget.label;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Tooltip(
        message: !widget.isExpanded ? tooltipMessage : (widget.shortcut ?? ''),
        waitDuration: const Duration(milliseconds: 350),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onTap();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeInOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              height: 46,
              decoration: BoxDecoration(
                color: widget.selected
                    ? EuBrutal.accent
                    : (_hovered
                        ? (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05))
                        : Colors.transparent),
                borderRadius: BorderRadius.circular(14),
                boxShadow: widget.selected
                    ? [
                        BoxShadow(
                          color: EuBrutal.accent.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: widget.isExpanded
                  ? ClipRect(
                      child: Row(
                        children: [
                          SizedBox(
                            width: 44,
                            height: 46,
                            child: Center(
                              child: Icon(
                                widget.icon,
                                size: 22,
                                color: effectiveIconColor,
                              ),
                            ),
                          ),
                          Expanded(
                            child: ClipRect(
                              child: Text(
                                widget.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: widget.selected
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                  color: effectiveTextColor,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ),
                          if (widget.selected)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 8),
                        ],
                      ),
                    )
                  : Center(
                      child: Icon(
                        widget.icon,
                        size: 22,
                        color: effectiveIconColor,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
