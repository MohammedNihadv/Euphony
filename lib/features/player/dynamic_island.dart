import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design/tokens/brutal.dart';
import '../../design/tokens/tokens.dart';
import '../../design/widgets/animated_waveform.dart';
import '../../domain/song.dart';
import '../../playback/player_provider.dart';
import '../settings/settings_provider.dart';
import 'player_screen.dart';

/// A floating "Dynamic Island" / Smart Capsule widget for mobile devices.
///
/// Mimics modern Android & iOS dynamic island capsules (Xiaomi HyperOS Live Island,
/// Oppo ColorOS Aqua Dynamics, Vivo OriginOS Island, Samsung Live Notifications).
/// Floats right beneath the top status bar / camera punch hole.
///
/// Features:
/// - Fully Automatic: Appears automatically when audio plays, auto-expands on track changes
///   for 3.8s to present track info, then smoothly collapses back to the compact pill.
/// - Compact state: Sleek pill showing mini album art, song title, and live equalizer.
/// - Expanded state: Morphs with a spring curve into a rich neo-brutalist glass card
///   with full playback controls, seekbar, live progress, and full-player shortcut.
/// - Gestures: Swipe up to tuck away; tap to expand/collapse.
class DynamicIsland extends ConsumerStatefulWidget {
  const DynamicIsland({super.key});

  @override
  ConsumerState<DynamicIsland> createState() => _DynamicIslandState();
}

class _DynamicIslandState extends ConsumerState<DynamicIsland> {
  bool _isExpanded = false;
  bool _manuallyOpened = false;
  bool _isTucked = false;
  Timer? _autoCollapseTimer;
  Timer? _pauseAutoHideTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final song = ref.read(activeSongProvider);
      final isPlaying = ref.read(isPlayingProvider);
      if (song != null && isPlaying) {
        _triggerAutoExpand();
      }
    });
  }

  @override
  void dispose() {
    _autoCollapseTimer?.cancel();
    _pauseAutoHideTimer?.cancel();
    super.dispose();
  }

  void _triggerAutoExpand() {
    _autoCollapseTimer?.cancel();
    _pauseAutoHideTimer?.cancel();
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isTucked = false;
      _isExpanded = true;
      _manuallyOpened = false;
    });
    // Automatically collapse after 3.8s if user hasn't manually opened controls
    _autoCollapseTimer = Timer(const Duration(milliseconds: 3800), () {
      if (mounted && _isExpanded && !_manuallyOpened) {
        setState(() {
          _isExpanded = false;
        });
      }
    });
  }

  void _schedulePauseAutoHide() {
    _pauseAutoHideTimer?.cancel();
    _pauseAutoHideTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && !ref.read(isPlayingProvider) && !_isExpanded) {
        setState(() {
          _isTucked = true;
        });
      }
    });
  }

  void _toggleExpanded() {
    HapticFeedback.lightImpact();
    _autoCollapseTimer?.cancel();
    _pauseAutoHideTimer?.cancel();
    setState(() {
      _isTucked = false;
      _isExpanded = !_isExpanded;
      _manuallyOpened = _isExpanded;
    });
  }

  void _collapse() {
    _autoCollapseTimer?.cancel();
    if (_isExpanded) {
      HapticFeedback.selectionClick();
      setState(() {
        _isExpanded = false;
        _manuallyOpened = false;
      });
      if (!ref.read(isPlayingProvider)) {
        _schedulePauseAutoHide();
      }
    }
  }

  void _tuck() {
    _autoCollapseTimer?.cancel();
    _pauseAutoHideTimer?.cancel();
    HapticFeedback.selectionClick();
    setState(() {
      _isExpanded = false;
      _manuallyOpened = false;
      _isTucked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    if (!settings.dynamicIsland) return const SizedBox.shrink();

    // Automatically trigger expansion when a new song starts or track changes
    ref.listen<Song?>(activeSongProvider, (previous, current) {
      if (current != null && (previous == null || previous.id != current.id)) {
        _triggerAutoExpand();
      } else if (current == null) {
        _autoCollapseTimer?.cancel();
        _pauseAutoHideTimer?.cancel();
        if (mounted) {
          setState(() {
            _isExpanded = false;
            _manuallyOpened = false;
            _isTucked = true;
          });
        }
      }
    });

    // Automatically trigger expansion when playback resumes, and auto-tuck when paused
    ref.listen<bool>(isPlayingProvider, (previous, current) {
      if (current == true && previous == false) {
        _triggerAutoExpand();
      } else if (current == false && previous == true) {
        if (_isExpanded && !_manuallyOpened) {
          _collapse();
        }
        _schedulePauseAutoHide();
      }
    });

    final Song? song = ref.watch(activeSongProvider);
    if (song == null) {
      if (_isExpanded) _collapse();
      return const SizedBox.shrink();
    }

    final bool isPlaying = ref.watch(isPlayingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;
    final screenWidth = MediaQuery.sizeOf(context).width;

    final targetWidth = _isExpanded
        ? math.min(screenWidth - 32, 420.0)
        : math.min(screenWidth - 48, 240.0);
    final targetHeight = _isExpanded ? 204.0 : 48.0;
    final notchTop = topPadding + 4.0;
    final targetTop = _isTucked ? -80.0 : notchTop;

    final capsuleWidget = Container(
      width: targetWidth,
      height: targetHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_isExpanded ? 26 : 24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.12),
            offset: Offset(0, _isExpanded ? 12 : 4),
            blurRadius: _isExpanded ? 28 : 14,
            spreadRadius: _isExpanded ? -2 : -1,
          ),
          if (_isExpanded)
            BoxShadow(
              color: EuBrutal.accent.withValues(alpha: isDark ? 0.3 : 0.18),
              blurRadius: 24,
              spreadRadius: -4,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_isExpanded ? 26 : 24),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 20,
            sigmaY: 20,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xF60F0F18)
                  : Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(
                _isExpanded ? 26 : 24,
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.22)
                    : Colors.black.withValues(alpha: 0.12),
                width: _isExpanded ? 1.6 : 1.1,
              ),
            ),
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                // Swipe up to tuck away into notch
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! < -100) {
                  _tuck();
                }
              },
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: _isExpanded ? null : _toggleExpanded,
                  onLongPress: _isExpanded
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context, rootNavigator: true)
                              .push(_buildPlayerRoute());
                        },
                  borderRadius: BorderRadius.circular(
                    _isExpanded ? 26 : 24,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _isExpanded
                        ? _buildExpandedContent(
                            context: context,
                            song: song,
                            isPlaying: isPlaying,
                            isDark: isDark,
                          )
                        : _buildCollapsedContent(
                            context: context,
                            song: song,
                            isPlaying: isPlaying,
                            isDark: isDark,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _collapse,
              child: ColoredBox(
                color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.35),
              ),
            ),
          ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 320),
          curve: Curves.fastOutSlowIn,
          top: targetTop,
          left: (screenWidth - targetWidth) / 2,
          width: targetWidth,
          height: targetHeight,
          child: IgnorePointer(
            ignoring: _isTucked,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 240),
              opacity: _isTucked ? 0.0 : 1.0,
              child: capsuleWidget,
            ),
          ),
        ),
      ],
    );
  }

  // ── Compact Island Pill (Docked at Notch) ──────────────────────────────────
  Widget _buildCollapsedContent({
    required BuildContext context,
    required Song song,
    required bool isPlaying,
    required bool isDark,
  }) {
    return Padding(
      key: const ValueKey('collapsed'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Album thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: EuBrutal.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.black12,
                  width: 1,
                ),
              ),
              child: song.artworkUrl != null && song.artworkUrl!.isNotEmpty
                  ? Image.network(
                      song.artworkUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.music_note_rounded,
                        size: 16,
                        color: EuBrutal.accent,
                      ),
                    )
                  : const Icon(
                      Icons.music_note_rounded,
                      size: 16,
                      color: EuBrutal.accent,
                    ),
            ),
          ),
          const SizedBox(width: 9),

          // Song title & artist
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.2,
                  ),
                ),
                if (song.artistNames.isNotEmpty)
                  Text(
                    song.artistNames,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.0,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Mini live audio waveform bars
          AnimatedWaveform(
            playing: isPlaying,
            barCount: 4,
            width: 18,
            height: 16,
            color: EuBrutal.accent,
          ),
          const SizedBox(width: 4),

          // Mini expand toggle button
          GestureDetector(
            onTap: _toggleExpanded,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Icon(
                Icons.unfold_more_rounded,
                size: 16,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Expanded Island Card ──────────────────────────────────────────────────
  Widget _buildExpandedContent({
    required BuildContext context,
    required Song song,
    required bool isPlaying,
    required bool isDark,
  }) {
    final AsyncValue<Duration> positionAsync = ref.watch(trackPositionProvider);
    final Duration position = positionAsync.asData?.value ?? Duration.zero;
    final Duration? totalDuration = ref.watch(totalDurationProvider);
    final total = totalDuration ?? song.duration ?? const Duration(minutes: 3, seconds: 30);
    final progress = total.inMilliseconds > 0
        ? (position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      key: const ValueKey('expanded'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row: Status badge + Collapse button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPlaying
                        ? const Color(0xFF22C55E).withValues(alpha: 0.16)
                        : Colors.orange.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isPlaying
                          ? const Color(0xFF22C55E)
                          : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isPlaying
                              ? const Color(0xFF22C55E)
                              : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          isPlaying ? 'DYNAMIC ISLAND · PLAYING' : 'DYNAMIC ISLAND · PAUSED',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: isPlaying
                                ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
                                : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Full player expand button
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      _collapse();
                      Navigator.of(context, rootNavigator: true)
                          .push(_buildPlayerRoute());
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.open_in_full_rounded,
                        size: 14,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Collapse chevron
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _collapse,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        size: 18,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Middle Row: Cover Art + Info + Progress
          Row(
            children: [
              // Cover art with neo-brutalist border
              GestureDetector(
                onTap: () {
                  _collapse();
                  Navigator.of(context, rootNavigator: true)
                      .push(_buildPlayerRoute());
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white24 : context.eu.ink,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: song.artworkUrl != null && song.artworkUrl!.isNotEmpty
                        ? Image.network(
                            song.artworkUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.music_note_rounded,
                              color: EuBrutal.accent,
                            ),
                          )
                        : const Icon(
                            Icons.music_note_rounded,
                            color: EuBrutal.accent,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title, Artist, & Progress (tap to open full player)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _collapse();
                    Navigator.of(context, rootNavigator: true)
                        .push(_buildPlayerRoute());
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        song.artistNames,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: isDark
                              ? Colors.white12
                              : Colors.black12,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            EuBrutal.accent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.black38,
                            ),
                          ),
                          Text(
                            _formatDuration(total),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white38
                                  : Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Bottom Controls: Skip Previous, Play/Pause, Skip Next, Expand to full player
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded),
                iconSize: 24,
                color: isDark ? Colors.white70 : Colors.black87,
                tooltip: 'Previous',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(playerControllerProvider).skipPrevious();
                },
              ),
              // Neo-Brutal circular Play/Pause button
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ref.read(playerControllerProvider).togglePlayPause();
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: EuBrutal.accent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white24 : context.eu.ink,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: EuBrutal.accent.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 22,
                    color: EuBrutal.onAccent,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                iconSize: 24,
                color: isDark ? Colors.white70 : Colors.black87,
                tooltip: 'Next',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(playerControllerProvider).skipNext();
                },
              ),
              IconButton(
                icon: const Icon(Icons.open_in_full_rounded),
                iconSize: 18,
                color: isDark ? Colors.white60 : Colors.black54,
                tooltip: 'Open Full Player',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _collapse();
                  Navigator.of(context, rootNavigator: true)
                      .push(_buildPlayerRoute());
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  PageRouteBuilder<void> _buildPlayerRoute() {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const PlayerScreen(),
      transitionDuration: EuMotion.standard,
      reverseTransitionDuration: EuMotion.quick,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: EuMotion.emphasized,
          reverseCurve: EuMotion.emphasizedIn,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
  }
}
