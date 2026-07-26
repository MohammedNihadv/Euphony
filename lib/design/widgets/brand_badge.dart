import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../tokens/brutal.dart';

/// Animated waveform bars – identical to the logo mark.
class _WaveformBars extends StatefulWidget {
  const _WaveformBars({super.key, this.size = 22, this.color = Colors.white});
  final double size;
  final Color color;

  @override
  State<_WaveformBars> createState() => _WaveformBarsState();
}

class _WaveformBarsState extends State<_WaveformBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  // Heights for 5 bars, cycling out of phase
  static const _phases = [0.0, 0.8, 1.6, 2.4, 0.4];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
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
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(5, (i) {
              final t = (_ctrl.value * 2 * math.pi) + _phases[i];
              final frac = (math.sin(t) * 0.5 + 0.5).clamp(0.3, 1.0);
              return Container(
                width: widget.size * 0.10,
                height: widget.size * frac,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

/// Reusable Neo-Brutalist brand badge for Euphony headers, dialogs, and splash screens.
class EuphonyBrandBadge extends StatelessWidget {
  const EuphonyBrandBadge({
    super.key,
    this.fontSize = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.showTagline = false,
    this.animate = false,
  });

  final double fontSize;
  final EdgeInsets padding;
  final bool showTagline;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: padding,
          decoration: BoxDecoration(
            color: EuBrutal.highlight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: EuBrutal.ink, width: 2.5),
            boxShadow: EuBrutal.smHardShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: EuBrutal.ink, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/app.icon.png',
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Euphony',
                style: TextStyle(
                  color: EuBrutal.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: fontSize,
                  letterSpacing: 0.0,
                ),
              ),
            ],
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 4),
          const Text(
            'PURE AUDIO • NEO-BRUTALIST',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: EuBrutal.ink,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ],
    );
  }
}
