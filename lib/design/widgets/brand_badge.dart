import 'package:flutter/material.dart';
import '../tokens/brutal.dart';

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
