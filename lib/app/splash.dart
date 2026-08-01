import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/tokens/brutal.dart';

/// The dark canvas the splash sits on — matched to the app and the native
/// launch background so the hand-off is seamless.
const Color _splashCanvas = Color(0xFF0D0D14);

/// Wraps the app and plays a one-time animated splash over it on cold start.
///
/// The native Android splash only shows a static launcher icon; this is the
/// branded moment — the Neo-Brutalist logo slab punches in with its hard
/// shadow, an equalizer of black-outlined bars dances beneath it, then the
/// whole thing lifts away to reveal the app already built underneath.
class SplashOverlay extends StatefulWidget {
  const SplashOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );
  late final AnimationController _bars = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..repeat();

  late final Animation<double> _pop = CurvedAnimation(
    parent: _intro,
    curve: Curves.easeOutBack,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0, 0.5, curve: Curves.easeOut),
  );

  bool _dismissed = false;
  double _opacity = 1;

  @override
  void initState() {
    super.initState();
    // Crucially, wait for the first *rendered* frame before starting the intro
    // and the dismiss timer. On a cold start the engine spends 2-3s warming up
    // with nothing painted; if the timer ran from build time it would elapse
    // during that invisible window and the splash would never actually be seen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _intro.forward();
      Future.delayed(const Duration(milliseconds: 1050), () {
        if (mounted) setState(() => _opacity = 0);
      });
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _bars.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (!_dismissed)
          Positioned.fill(
            child: IgnorePointer(
              ignoring: _opacity == 0,
              child: AnimatedOpacity(
                opacity: _opacity,
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeInOut,
                onEnd: () {
                  if (_opacity == 0 && mounted) {
                    setState(() => _dismissed = true);
                  }
                },
                child: _SplashContent(
                  pop: _pop,
                  fade: _fade,
                  bars: _bars,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SplashContent extends StatelessWidget {
  const _SplashContent({
    required this.pop,
    required this.fade,
    required this.bars,
  });

  final Animation<double> pop;
  final Animation<double> fade;
  final Animation<double> bars;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _splashCanvas,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: pop,
              child: FadeTransition(
                opacity: fade,
                child: _LogoSlab(),
              ),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: fade,
              child: SizedBox(height: 26, child: _Equalizer(animation: bars)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The brand slab — the yellow highlight tile with the icon and wordmark, at
/// splash scale.
class _LogoSlab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 24, 16),
      decoration: BoxDecoration(
        color: EuBrutal.highlight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: EuBrutal.ink, width: 3),
        boxShadow: const [
          BoxShadow(color: EuBrutal.ink, offset: Offset(6, 6)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: EuBrutal.onHighlight, width: 2.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Transform.scale(
              scale: 1.62,
              child: Image.asset(
                'assets/images/app.icon.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Text(
            'Euphony',
            style: TextStyle(
              color: EuBrutal.onHighlight,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Five chunky, black-outlined bars that bounce — the brutalist equalizer.
class _Equalizer extends StatelessWidget {
  const _Equalizer({required this.animation});

  final Animation<double> animation;

  static const _bars = [
    (0.0, EuBrutal.accent),
    (0.55, EuBrutal.alert),
    (0.2, EuBrutal.highlight),
    (0.8, EuBrutal.accent),
    (0.35, EuBrutal.alert),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (final (phase, color) in _bars) ...[
              _bar(phase, color),
              const SizedBox(width: 7),
            ],
          ],
        );
      },
    );
  }

  Widget _bar(double phase, Color color) {
    final t = (math.sin((animation.value + phase) * 2 * math.pi) + 1) / 2;
    return Container(
      width: 12,
      height: 8 + t * 18,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: EuBrutal.ink, width: 2),
      ),
    );
  }
}
