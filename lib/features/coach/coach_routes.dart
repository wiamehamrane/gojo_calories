import 'package:go_router/go_router.dart';

import '../../app/router_keys.dart';
import '../../core/routing/app_page_transitions.dart';
import '../../core/routing/route_paths.dart';
import '../../core/routing/tab_page_transition.dart';
import 'presentation/screens/coach_detail_screen.dart';
import 'presentation/screens/coach_discover_screen.dart';

List<RouteBase> get coachShellRoutes => [
      GoRoute(
        path: RoutePaths.coaches,
        pageBuilder: (context, state) => tabTransitionPage(
          state: state,
          child: const CoachDiscoverScreen(),
        ),
      ),
    ];

List<RouteBase> get coachRoutes => [
      GoRoute(
        path: RoutePaths.coachDetail,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return smoothPushPage(
            state: state,
            child: CoachDetailScreen(coachId: id),
          );
        },
      ),
    ];
