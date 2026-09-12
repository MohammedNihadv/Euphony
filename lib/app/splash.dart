import 'package:flutter/material.dart';

import '../core/util/permissions.dart';

/// Wraps the app and initializes first-frame permissions on startup.
class SplashOverlay extends StatefulWidget {
  const SplashOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ensureNotificationPermission();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
