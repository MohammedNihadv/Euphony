import 'package:flutter/material.dart';

import '../tokens/brutal.dart';

/// The Euphony logo mark — the app icon in a framed tile with an accent glow,
/// sized to actually be legible. Used on its own and inside [EuphonyBrandBadge].
class EuphonyLogoMark extends StatelessWidget {
  const EuphonyLogoMark({super.key, this.size = 34, this.radius = 10});

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: EuBrutal.accent.withValues(alpha: 0.40),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset('assets/images/app.icon.png', fit: BoxFit.cover),
    );
  }
}

/// The header brand lockup: the logo mark beside the wordmark with luminous gradient typography.
class EuphonyBrandBadge extends StatelessWidget {
  const EuphonyBrandBadge({
    super.key,
    this.fontSize = 22,
    this.showTagline = false,
    this.animate = false,
    this.padding = EdgeInsets.zero,
  });

  final double fontSize;
  final bool showTagline;
  final bool animate;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              EuphonyLogoMark(size: fontSize * 1.35, radius: fontSize * 0.38),
              const SizedBox(width: 9),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: isDark
                      ? const [Colors.white, Color(0xFFDDD6FE)]
                      : const [Color(0xFF1E1035), EuBrutal.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: Text(
                  'Euphony',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: fontSize,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
            ],
          ),
          if (showTagline) ...[
            const SizedBox(height: 3),
            Text(
              'Pure sound, in your colours',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A sleek, neo-glassmorphic capsule badge used across all main page AppBars
/// (e.g. "Euphony | Home", "Euphony | Explore", "Euphony | Library", "Euphony | Settings").
class EuphonyPageCapsule extends StatelessWidget {
  const EuphonyPageCapsule({
    super.key,
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const EuphonyBrandBadge(fontSize: 15),
          Container(
            width: 1.2,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          Icon(
            icon,
            size: 14,
            color: EuBrutal.accent,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.4,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
