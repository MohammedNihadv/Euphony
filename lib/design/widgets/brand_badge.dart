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
          Icon(icon, size: 14, color: EuBrutal.accent),
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

/// A premium, unified AppBar for subpages (Album, Artist, Discography) that
/// matches the homepage and library capsule aesthetic, with a dedicated
/// glassmorphic back button, breadcrumb capsule, and smooth tap feedback.
class EuphonySubpageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EuphonySubpageAppBar({
    super.key,
    required this.categoryLabel,
    required this.icon,
    this.title,
    this.actions,
    this.onBackPressed,
  });

  final String categoryLabel;
  final IconData icon;
  final String? title;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);

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

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleSpacing: 8,
      leadingWidth: 54,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.08),
              width: 1.0,
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: handleBack,
              child: Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 15,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          EuphonyPageCapsule(
            label: categoryLabel,
            icon: icon,
          ),
          if (title != null && title!.isNotEmpty) ...[
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                title!,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: actions != null
          ? [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions!,
                ),
              ),
            ]
          : null,
    );
  }
}

