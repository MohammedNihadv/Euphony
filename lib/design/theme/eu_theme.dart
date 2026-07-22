import 'package:flutter/material.dart';

import '../tokens/tokens.dart';

/// Euphony's fallback seed, used before any artwork has been sampled.
const Color euFallbackSeed = Color(0xFF7C5CFF);

/// Builds the app's [ThemeData] from a [ColorScheme].
///
/// The scheme normally comes from the current track's artwork; see
/// `artwork_palette.dart`. Everything visual that is not colour lives in
/// `design/tokens/`, so this file only wires tokens into Material's
/// component themes — no widget should need to override them locally.
abstract final class EuTheme {
  static ThemeData light(ColorScheme scheme) => _build(scheme);

  static ThemeData dark(ColorScheme scheme, {bool amoled = false}) {
    final effective = amoled
        ? scheme.copyWith(
            surface: Colors.black,
            surfaceContainerLowest: Colors.black,
            surfaceContainerLow: const Color(0xFF0A0A0A),
            surfaceContainer: const Color(0xFF101010),
          )
        : scheme;
    return _build(effective, scaffoldBackground: amoled ? Colors.black : null);
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
        titleTextStyle: text.screenTitle?.copyWith(color: scheme.onSurface),
      ),

      cardTheme: CardThemeData(
        elevation: EuElevation.flat,
        color: scheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: EuShape.cardBorder,
        clipBehavior: Clip.antiAlias,
      ),

      listTileTheme: ListTileThemeData(
        shape: const RoundedRectangleBorder(borderRadius: EuShape.sm),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: EuSpace.lg,
          vertical: EuSpace.xxs,
        ),
        titleTextStyle: text.itemTitle?.copyWith(color: scheme.onSurface),
        subtitleTextStyle: text.itemSubtitle?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: EuShape.pill),
          padding: const EdgeInsets.symmetric(
            horizontal: EuSpace.xl,
            vertical: EuSpace.md,
          ),
          textStyle: text.action,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: EuShape.pill),
          textStyle: text.action,
        ),
      ),

      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: EuShape.pill),
        side: BorderSide.none,
        backgroundColor: scheme.surfaceContainerHigh,
        labelStyle: text.action,
        padding: const EdgeInsets.symmetric(
          horizontal: EuSpace.md,
          vertical: EuSpace.sm,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: EuElevation.sheet,
        shape: EuShape.sheetBorder,
        showDragHandle: true,
        clipBehavior: Clip.antiAlias,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: EuShape.lg),
        titleTextStyle: text.headlineSmall?.copyWith(color: scheme.onSurface),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: EuElevation.flat,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
      ),

      sliderTheme: SliderThemeData(
        trackHeight: 6,
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
        ),
        shape: const RoundedRectangleBorder(borderRadius: EuShape.md),
        insetPadding: const EdgeInsets.all(EuSpace.lg),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
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
