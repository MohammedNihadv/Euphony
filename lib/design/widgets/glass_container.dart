import 'dart:ui';

import 'package:flutter/material.dart';

/// A premium glassmorphism container.
///
/// Wraps its [child] with a [BackdropFilter] blur effect and a semi-transparent
/// fill, producing the frosted-glass look. Automatically falls back to an
/// opaque container when [BackdropFilter] is not supported (very old devices).
///
/// Usage:
/// ```dart
/// GlassContainer(
///   blur: 18,
///   tint: Colors.white.withValues(alpha: 0.08),
///   borderRadius: BorderRadius.circular(20),
///   child: MyContent(),
/// )
/// ```
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 16,
    this.tint,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.border,
    this.boxShadow,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;

  /// Sigma value for the blur effect.
  final double blur;

  /// Semi-transparent fill colour. Defaults to 8% white in dark mode.
  final Color? tint;

  final BorderRadiusGeometry borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final defaultTint = brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.white.withValues(alpha: 0.55);

    final effectiveTint = tint ?? defaultTint;
    final effectiveBorder =
        border ??
        Border.all(
          color: brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.6),
          width: 1,
        );

    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: boxShadow,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: effectiveTint,
              borderRadius: borderRadius,
              border: effectiveBorder,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
