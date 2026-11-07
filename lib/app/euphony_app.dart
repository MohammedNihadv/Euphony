import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/theme/eu_theme.dart';
import '../design/theme/theme_controller.dart';
import '../design/tokens/motion.dart';
import 'router.dart';
import 'splash.dart';

/// Desktop & mobile smooth scroll behavior supporting mouse dragging and trackpads.
class EuphonyScrollBehavior extends MaterialScrollBehavior {
  const EuphonyScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

class EuphonyApp extends ConsumerWidget {
  const EuphonyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);

    final lightTheme = EuTheme.light(theme.scheme.light);
    final darkTheme = EuTheme.dark(theme.scheme.dark, amoled: theme.amoled);

    return MaterialApp.router(
      title: 'Euphony',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const EuphonyScrollBehavior(),
      themeMode: theme.mode,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeAnimationDuration: EuMotion.themeShift,
      themeAnimationCurve: EuMotion.emphasized,
      routerConfig: routerProvider,
      builder: (context, child) =>
          SplashOverlay(child: child ?? const SizedBox.shrink()),
    );
  }
}
