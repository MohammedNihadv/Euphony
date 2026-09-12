import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A mini animated waveform — 4 bars that pulse at slightly different rates and
/// phases when [playing] is `true`, and freeze when [playing] is `false`.
///
/// Used in the MiniPlayer and the full PlayerScreen to give a live visual
/// indication of active playback.
class AnimatedWaveform extends StatefulWidget {
  const AnimatedWaveform({
    super.key,
    this.playing = true,
    this.barCount = 4,
    this.color,
    this.width = 20,
    this.height = 20,
    this.barWidth = 3,
    this.gap = 2,
  });

  final bool playing;
  final int barCount;

  /// Bar colour. Defaults to the current theme's primary colour.
  final Color? color;

  final double width;
  final double height;
  final double barWidth;
  final double gap;

  @override
  State<AnimatedWaveform> createState() => _AnimatedWaveformState();
}

class _AnimatedWaveformState extends State<AnimatedWaveform>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  /// Slightly different durations per bar so they go in and out of phase.
  static const _durations = [520, 680, 440, 600];

  /// Each bar starts at a different phase in its cycle.
  static const _phases = [0.0, 0.3, 0.7, 0.5];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.barCount, (i) {
      final duration = Duration(
        milliseconds: _durations[i % _durations.length],
      );
      return AnimationController(vsync: this, duration: duration)
        ..value = _phases[i % _phases.length];
    });
    _animations = _controllers
        .map(
          (c) => Tween<double>(begin: 0.15, end: 1.0).animate(
            CurvedAnimation(parent: c, curve: Curves.easeInOut),
          ),
        )
        .toList();

    if (widget.playing) _startAll();
  }

  void _startAll() {
    for (final c in _controllers) {
      c.repeat(reverse: true);
    }
  }

  void _stopAll() {
    for (int i = 0; i < _controllers.length; i++) {
      _controllers[i].animateTo(
        0.25,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void didUpdateWidget(AnimatedWaveform old) {
    super.didUpdateWidget(old);
    if (old.playing != widget.playing) {
      if (widget.playing) {
        _startAll();
      } else {
        _stopAll();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: Listenable.merge(_controllers),
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(math.min(widget.barCount, 4), (i) {
              final fraction = _animations[i].value;
              final barHeight = widget.height * fraction;
              return Padding(
                padding: EdgeInsets.only(
                  right: i < widget.barCount - 1 ? widget.gap : 0,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 50),
                  width: widget.barWidth,
                  height: barHeight,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(widget.barWidth / 2),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
