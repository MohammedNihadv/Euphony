import 'package:flutter/material.dart';

import '../tokens/brutal.dart';
import '../tokens/tokens.dart';

/// Euphony's fallback seed, used before any artwork has been sampled.
const Color euFallbackSeed = EuBrutal.accent;

/// Builds the app's Neo-Brutalist [ThemeData] from a [ColorScheme].
abstract final class EuTheme {
  static ThemeData light(ColorScheme scheme) => _build(
    scheme.copyWith(
      primary: EuBrutal.accent,
      secondary: EuBrutal.alert,
      tertiary: EuBrutal.highlight,
      surface: const Color(0xFFFAF7F2),
      surfaceContainerLowest: const Color(0xFFF5F0EA),
      surfaceContainerLow: Colors.white,
      surfaceContainer: const Color(0xFFFFF9F0),
      surfaceContainerHigh: const Color(0xFFF3E8FF),
      surfaceContainerHighest: const Color(0xFFE8DFFF),
      onSurface: const Color(0xFF0D0D14),
      onSurfaceVariant: const Color(0xFF3D3D52),
    ),
    scaffoldBackground: const Color(0xFFFAF7F2),
    isLight: true,
  );

  static ThemeData dark(ColorScheme scheme, {bool amoled = false}) {
    final effective = amoled
        ? scheme.copyWith(
            primary: EuBrutal.accent,
            secondary: EuBrutal.alert,
            tertiary: EuBrutal.highlight,
            surface: Colors.black,
            surfaceContainerLowest: Colors.black,
            surfaceContainerLow: const Color(0xFF0F0F16),
            surfaceContainer: const Color(0xFF161622),
            surfaceContainerHigh: const Color(0xFF1E1E2E),
            surfaceContainerHighest: const Color(0xFF28283D),
            onSurface: Colors.white,
          )
        : scheme.copyWith(
            primary: EuBrutal.accent,
            secondary: EuBrutal.alert,
            tertiary: EuBrutal.highlight,
            surface: const Color(0xFF12121A),
            surfaceContainerLow: const Color(0xFF181824),
            surfaceContainer: const Color(0xFF202030),
            surfaceContainerHigh: const Color(0xFF29293F),
            surfaceContainerHighest: const Color(0xFF33334F),
            onSurface: const Color(0xFFF8F9FA),
          );
    return _build(
      effective,
      scaffoldBackground: amoled ? Colors.black : effective.surface,
      isLight: false,
    );
  }

  static ThemeData _build(
    ColorScheme scheme, {
    Color? scaffoldBackground,
    bool isLight = false,
  }) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final text = EuType.build(base.textTheme);
    // Adaptive ink: dark in light mode, light in dark mode.
    final inkColor =
        isLight ? const Color(0xFF0D0D14) : const Color(0xFFF4F3FA);
    final inkSide = BorderSide(color: inkColor, width: 2);
    final inkThinSide = BorderSide(color: inkColor, width: 1.5);

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: scaffoldBackground ?? scheme.surface,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: EuElevation.flat,
        centerTitle: false,
        titleTextStyle: text.screenTitle?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: EuElevation.flat,
        color: scheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: EuShape.md,
          side: inkSide,
        ),
        clipBehavior: Clip.antiAlias,
      ),

      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerLow),
        elevation: const WidgetStatePropertyAll(0),
        side: WidgetStatePropertyAll(inkSide),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: EuShape.md),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: EuSpace.md, vertical: EuSpace.xs),
        ),
        hintStyle: WidgetStatePropertyAll(
          text.bodyMedium?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      listTileTheme: ListTileThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: EuShape.sm,
          side: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: EuSpace.md,
          vertical: EuSpace.xs,
        ),
        titleTextStyle: text.itemTitle?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        subtitleTextStyle: text.itemSubtitle?.copyWith(
          color: scheme.onSurface.withValues(alpha: 0.75),
          fontWeight: FontWeight.w500,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: EuBrutal.onAccent,
          shape: RoundedRectangleBorder(
            borderRadius: EuShape.md,
            side: inkSide,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: EuSpace.xl,
            vertical: EuSpace.md,
          ),
          textStyle: text.action?.copyWith(fontWeight: FontWeight.w800),
          elevation: 0,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: EuShape.pill,
            side: inkSide,
          ),
          foregroundColor: scheme.onSurface,
          textStyle: text.action?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: EuShape.pill,
          side: inkThinSide,
        ),
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primary,
        secondarySelectedColor: scheme.secondary,
        labelStyle: text.action?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.onSurface,
        ),
        secondaryLabelStyle: text.action?.copyWith(
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: EuSpace.md,
          vertical: EuSpace.xs,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: EuElevation.sheet,
        shape: RoundedRectangleBorder(
          borderRadius: EuShape.sheetTop,
          side: inkSide,
        ),
        showDragHandle: true,
        clipBehavior: Clip.antiAlias,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: EuShape.lg,
          side: inkSide,
        ),
        titleTextStyle: text.headlineSmall?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w900,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: EuElevation.flat,
        height: 68,
        indicatorColor: scheme.primary,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        labelTextStyle: WidgetStatePropertyAll(
          text.labelMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),

      sliderTheme: SliderThemeData(
        trackHeight: 8,
        activeTrackColor: scheme.primary,
        inactiveTrackColor: scheme.surfaceContainerHighest,
        thumbColor: scheme.primary,
        overlayShape: SliderComponentShape.noOverlay,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: EuShape.md,
          side: inkSide,
        ),
        insetPadding: const EdgeInsets.all(EuSpace.lg),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),

      dividerTheme: DividerThemeData(
        color: inkColor.withValues(alpha: 0.12),
        thickness: 1,
        space: 1,
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
