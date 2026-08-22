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
        boxShadow: EuBrutal.glow(EuBrutal.accent, strength: 0.45),
      ),
      clipBehavior: Clip.antiAlias,
      // The icon is full-bleed (purple tile + waveform), so it fills the frame
      // directly — no scaling needed.
      child: Image.asset('assets/images/app.icon.png', fit: BoxFit.cover),
    );
  }
}

/// The header brand lockup: the logo mark beside the wordmark.
///
/// Replaces the old yellow "sticker" slab, which read juvenile and buried the
/// logo. The mark is now large enough to recognise and the wordmark is clean
/// white on the dark canvas.
class EuphonyBrandBadge extends StatelessWidget {
  const EuphonyBrandBadge({
    super.key,
    this.fontSize = 22,
    this.showTagline = false,
    // Retained for source compatibility; the lockup no longer self-animates.
    this.animate = false,
    this.padding = EdgeInsets.zero,
  });

  final double fontSize;
  final bool showTagline;
  final bool animate;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              EuphonyLogoMark(size: fontSize * 1.5, radius: fontSize * 0.42),
              const SizedBox(width: 10),
              Text(
                'Euphony',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: fontSize,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          if (showTagline) ...[
            const SizedBox(height: 4),
            Text(
              'Pure sound, in your colours',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
