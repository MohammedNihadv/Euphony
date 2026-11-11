import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

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
              Text(
                'Euphony',
                style: TextStyle(
                  color: isDark ? Colors.white : EuBrutal.accent,
                  fontWeight: FontWeight.w900,
                  fontSize: fontSize,
                  letterSpacing: -0.6,
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
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.8,
                ),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A sleek, floating Liquid Glass capsule badge used across all page AppBars
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
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          // Expansive floating drop shadow
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            offset: const Offset(0, 6),
            blurRadius: 18,
            spreadRadius: -2,
          ),
          // Tight caustic contact shadow
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF0F172A)).withValues(
              alpha: isDark ? 0.20 : 0.04,
            ),
            offset: const Offset(0, 2),
            blurRadius: 6,
            spreadRadius: -1,
          ),
          // Upper specular crest light for liquid curvature
          BoxShadow(
            color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.85),
            offset: const Offset(0, 1.2),
            blurRadius: 1,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              borderRadius: BorderRadius.circular(22),
              // Luminous liquid glass rim border
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.28)
                    : Colors.white.withValues(alpha: 0.85),
                width: 1.2,
              ),
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
                Icon(icon, size: 14, color: EuBrutal.accent),
                const SizedBox(width: 5),
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
          ),
        ),
      ),
    );
  }
}

/// A floating Liquid Glass circular button for AppBar actions & back buttons.
class EuphonyGlassIconButton extends StatelessWidget {
  const EuphonyGlassIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 40,
    this.iconSize = 20,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget button = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            offset: const Offset(0, 6),
            blurRadius: 18,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF0F172A)).withValues(
              alpha: isDark ? 0.20 : 0.04,
            ),
            offset: const Offset(0, 2),
            blurRadius: 6,
            spreadRadius: -1,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.85),
            offset: const Offset(0, 1.2),
            blurRadius: 1,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
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
              borderRadius: BorderRadius.circular(size / 2),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.28)
                    : Colors.white.withValues(alpha: 0.85),
                width: 1.2,
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(size / 2),
                onTap: () {
                  HapticFeedback.lightImpact();
                  onPressed();
                },
                child: Center(
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: iconColor ?? (isDark ? Colors.white : Colors.black87),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

/// A premium, unified AppBar for subpages (Album, Artist, Discography) with
/// the back button and brand capsule merged into ONE unified glass pill.
class EuphonySubpageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EuphonySubpageAppBar({
    super.key,
    required this.categoryLabel,
    this.icon,
    this.title,
    this.actions,
    this.onBackPressed,
    this.backIcon = Icons.arrow_back_ios_new_rounded,
    this.backIconSize = 15.0,
  });

  final String categoryLabel;
  final IconData? icon;
  final String? title;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final IconData backIcon;
  final double backIconSize;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 6);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    void handleBack() {
      HapticFeedback.lightImpact();
      if (onBackPressed != null) {
        onBackPressed!();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go('/');
      }
    }

    // Build a unified pill: back-arrow + divider + brand + divider + category
    final Widget pill = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            offset: const Offset(0, 6),
            blurRadius: 18,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.85),
            offset: const Offset(0, 1.2),
            blurRadius: 1,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
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
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.28)
                    : Colors.white.withValues(alpha: 0.85),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Back button inside the pill
                Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: handleBack,
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      child: Icon(
                        backIcon,
                        size: backIconSize,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
                // Thin divider
                Container(
                  width: 1.0,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
                // Brand badge
                const EuphonyBrandBadge(fontSize: 14),
                // Thin divider
                Container(
                  width: 1.0,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  color: isDark ? Colors.white24 : Colors.black12,
                ),
                // Category icon (if any) + label
                if (icon != null) ...[
                  Icon(icon, size: 13, color: EuBrutal.accent),
                  const SizedBox(width: 4),
                ],
                Text(
                  categoryLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 0.3,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 14,
        automaticallyImplyLeading: false,
        title: pill,
        actions: actions != null
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!,
                  ),
                ),
              ]
            : null,
      ),
    );
  }
}

