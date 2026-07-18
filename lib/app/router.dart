import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../core/routing/route_paths.dart';
import '../core/widgets/main_scaffold.dart';
import '../features/auth/auth_routes.dart';
import '../features/home/home_routes.dart';
import '../features/food/food_routes.dart';
import '../features/exercise/exercise_routes.dart';
import '../features/events/events_routes.dart';
import '../features/coach/coach_routes.dart';
import '../features/profile/profile_routes.dart';
import '../features/referrals/referrals_routes.dart';
import '../features/tasks/tasks_routes.dart';
import 'router_keys.dart';

export 'router_keys.dart';

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: RoutePaths.splash,
  debugLogDiagnostics: kDebugMode,
  routes: [
    ...authRoutes,
    ShellRoute(
      navigatorKey: shellNavigatorKey,
      builder: (context, state, child) => MainScaffold(child: child),
      routes: [
        ...homeRoutes,
        ...foodShellRoutes,
        ...eventsShellRoutes,
        ...coachShellRoutes,
        ...profileShellRoutes,
      ],
    ),
    ...profileRoutes,
    ...coachRoutes,
    ...eventsRoutes,
    ...exerciseRoutes,
    ...referralRoutes,
    ...foodRoutes,
    ...tasksRoutes,
  ],
);
