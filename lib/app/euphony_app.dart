import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/theme/eu_theme.dart';
import '../design/theme/theme_controller.dart';
import '../design/tokens/motion.dart';
import 'router.dart';
import 'splash.dart';

class EuphonyApp extends ConsumerWidget {
  const EuphonyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);

    // Euphony is dark-only: the identity is bold colour blocks glowing on a
    // near-black canvas, and the brutalist frame is a light outline that only
    // reads on dark. Both theme slots resolve to the dark build and the mode is
    // pinned, so a device set to "light" never lands on an unreadable screen.
    final darkTheme = EuTheme.dark(theme.scheme.dark, amoled: theme.amoled);

    return MaterialApp.router(
      title: 'Euphony',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: darkTheme,
      darkTheme: darkTheme,
      themeAnimationDuration: EuMotion.themeShift,
      themeAnimationCurve: EuMotion.emphasized,
      routerConfig: routerProvider,
      builder: (context, child) =>
          SplashOverlay(child: child ?? const SizedBox.shrink()),
    );
  }
}
