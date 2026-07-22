import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design/theme/eu_theme.dart';
import '../design/theme/theme_controller.dart';
import '../design/tokens/tokens.dart';
import 'home_placeholder.dart';

class EuphonyApp extends ConsumerWidget {
  const EuphonyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeControllerProvider);

    return MaterialApp(
      title: 'Euphony',
      debugShowCheckedModeBanner: false,
      themeMode: theme.mode,
      theme: EuTheme.light(theme.scheme.light),
      darkTheme: EuTheme.dark(theme.scheme.dark, amoled: theme.amoled),
      // Colours change with the artwork, so every scheme change is a
      // cross-fade rather than a cut.
      themeAnimationDuration: EuMotion.themeShift,
      themeAnimationCurve: EuMotion.emphasized,
      home: const HomePlaceholder(),
    );
  }
}
