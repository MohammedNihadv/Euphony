import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/tokens/brutal.dart';
import '../features/player/mini_player.dart';
import '../playback/player_provider.dart';

class EuphonyShell extends ConsumerWidget {
  const EuphonyShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A track that will not resolve used to fail silently — the user tapped a
    // song and nothing happened, which reads as the app being broken. Reported
    // once here rather than in each screen that can start playback.
    ref.listen<String?>(playbackErrorProvider, (previous, next) {
      if (next == null) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(next), behavior: SnackBarBehavior.floating),
        );
      ref.read(playbackErrorProvider.notifier).clear();
    });

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          Container(
            decoration: BoxDecoration(
              color: context.eu.ink,
              border: Border(
                top: BorderSide(color: context.eu.ink, width: 2.5),
              ),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                navigationBarTheme: NavigationBarThemeData(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  indicatorColor: EuBrutal.accent,
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: EuBrutal.accent,
                      );
                    }
                    return const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    );
                  }),
                  iconTheme: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const IconThemeData(
                        color: EuBrutal.onAccent,
                        size: 24,
                      );
                    }
                    return const IconThemeData(size: 24);
                  }),
                ),
              ),
              child: NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: (index) => navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                ),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.search_outlined),
                    selectedIcon: Icon(Icons.search),
                    label: 'Search',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.my_library_music_outlined),
                    selectedIcon: Icon(Icons.my_library_music),
                    label: 'Library',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings),
                    label: 'Settings',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
