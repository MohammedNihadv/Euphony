import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design/tokens/motion.dart';
import '../features/album/album_screen.dart';
import '../features/artist/artist_screen.dart';
import '../features/home/home_screen.dart';
import '../features/library/library_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/settings_screen.dart';
import 'euphony_shell.dart';

final routerProvider = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          EuphonyShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              pageBuilder: (context, state) =>
                  NoTransitionPage(key: state.pageKey, child: const HomeScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              pageBuilder: (context, state) => NoTransitionPage(
                key: state.pageKey,
                child: SearchScreen(
                  initialQuery: state.uri.queryParameters['q'],
                ),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/library',
              pageBuilder: (context, state) =>
                  NoTransitionPage(key: state.pageKey, child: const LibraryScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) =>
                  NoTransitionPage(key: state.pageKey, child: const SettingsScreen()),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/album/:id',
      pageBuilder: (context, state) => _buildSmoothPage(
        state.pageKey,
        AlbumScreen(id: state.pathParameters['id']!, isPlaylist: false),
      ),
    ),
    GoRoute(
      path: '/playlist/:id',
      pageBuilder: (context, state) => _buildSmoothPage(
        state.pageKey,
        AlbumScreen(id: state.pathParameters['id']!, isPlaylist: true),
      ),
    ),
    GoRoute(
      path: '/artist/:id',
      pageBuilder: (context, state) => _buildSmoothPage(
        state.pageKey,
        ArtistScreen(browseId: state.pathParameters['id']!),
      ),
    ),
  ],
);

CustomTransitionPage<void> _buildSmoothPage(LocalKey key, Widget child) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: EuMotion.standard,
    reverseTransitionDuration: EuMotion.quick,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: EuMotion.emphasized,
        reverseCurve: EuMotion.emphasizedIn,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
