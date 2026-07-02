import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/routing/route_paths.dart';
import '../core/widgets/main_scaffold.dart';
import '../features/auth/auth_routes.dart';
import '../features/home/home_routes.dart';
import '../features/food/food_routes.dart';
import '../features/exercise/exercise_routes.dart';
import '../features/events/events_routes.dart';
import '../features/profile/profile_routes.dart';
import '../features/referrals/referrals_routes.dart';
import '../features/tasks/tasks_routes.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: RoutePaths.splash,
  routes: [
    ...authRoutes,
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        ...homeRoutes,
        ...foodShellRoutes,
        ...eventsShellRoutes,
        ...profileShellRoutes,
      ],
    ),
    ...profileRoutes,
    ...exerciseRoutes,
    ...referralRoutes,
    ...foodRoutes,
    ...tasksRoutes,
  ],
);
