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
      surfaceContainerLow: Colors.white,
      surfaceContainer: const Color(0xFFFFFBEB),
      surfaceContainerHigh: const Color(0xFFF3E8FF),
      surfaceContainerHighest: const Color(0xFFE0F2FE),
      onSurface: EuBrutal.ink,
    ),
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
    );
  }

  static ThemeData _build(ColorScheme scheme, {Color? scaffoldBackground}) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final text = EuType.build(base.textTheme);

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
        shape: const RoundedRectangleBorder(
          borderRadius: EuShape.md,
          side: EuBrutal.side,
        ),
        clipBehavior: Clip.antiAlias,
      ),

      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerLow),
        elevation: const WidgetStatePropertyAll(0),
        side: const WidgetStatePropertyAll(EuBrutal.side),
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
          shape: const RoundedRectangleBorder(
            borderRadius: EuShape.md,
            side: EuBrutal.side,
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
          shape: const RoundedRectangleBorder(
            borderRadius: EuShape.pill,
            side: EuBrutal.side,
          ),
          foregroundColor: scheme.onSurface,
          textStyle: text.action?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),

      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: EuShape.pill,
          side: EuBrutal.side,
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
        shape: const RoundedRectangleBorder(
          borderRadius: EuShape.sheetTop,
          side: EuBrutal.side,
        ),
        showDragHandle: true,
        clipBehavior: Clip.antiAlias,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: EuShape.lg,
          side: EuBrutal.side,
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
        shape: const RoundedRectangleBorder(
          borderRadius: EuShape.md,
          side: EuBrutal.side,
        ),
        insetPadding: const EdgeInsets.all(EuSpace.lg),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),

      dividerTheme: const DividerThemeData(
        color: EuBrutal.ink,
        thickness: 2,
        space: 2,
      ),

      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
