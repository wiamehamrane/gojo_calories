import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import 'route_paths.dart';

/// Centralized navigation helpers that avoid silent `go()` failures during
/// async onboarding flows.
abstract final class AppNavigation {
  static void goToPaywall({BuildContext? context}) {
    _go(
      destination: RoutePaths.paywall,
      context: context,
    );
  }

  static void goToWeightSetup({BuildContext? context}) {
    _go(
      destination: RoutePaths.weightSetup,
      context: context,
    );
  }

  static void goToAuth({BuildContext? context}) {
    _go(
      destination: RoutePaths.auth,
      context: context,
    );
  }

  static void go(String destination, {BuildContext? context}) {
    _go(destination: destination, context: context);
  }

  static void _go({
    required String destination,
    BuildContext? context,
  }) {
    final destPath = destination.split('?').first;

    void navigateNow(String source) {
      try {
        if (context != null && context.mounted) {
          GoRouter.of(context).go(destination);
        } else {
          appRouter.go(destination);
        }
        debugPrint(
          '[AppNavigation] $source → $destination '
          '(now: ${appRouter.state.matchedLocation})',
        );
      } catch (e, st) {
        debugPrint('[AppNavigation] $source failed: $e\n$st');
        try {
          appRouter.go(destination);
        } catch (e2) {
          debugPrint('[AppNavigation] appRouter fallback failed: $e2');
        }
      }
    }

    bool isOnDestination() {
      final current = appRouter.state.matchedLocation;
      return current == destPath ||
          current == destination ||
          current.startsWith('$destPath/');
    }

    navigateNow('immediate');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isOnDestination()) navigateNow('post-frame');
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (!isOnDestination()) navigateNow('retry-200ms');
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!isOnDestination()) navigateNow('retry-600ms');
    });
  }
}
