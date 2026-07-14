import 'package:go_router/go_router.dart';
import '../../core/routing/app_page_transitions.dart';
import '../../core/routing/route_paths.dart';
import 'presentation/screens/scan_food_screen.dart';
import 'presentation/screens/food_log_screen.dart';
import 'presentation/screens/food_detail_screen.dart';
import 'presentation/screens/fix_results_screen.dart';
import 'presentation/screens/food_database_screen.dart';

List<RouteBase> get foodShellRoutes => [
      GoRoute(
        path: RoutePaths.scan,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const ScanFoodScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.log,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const FoodLogScreen(),
        ),
      ),
    ];

List<RouteBase> get foodRoutes => [
      GoRoute(
        path: RoutePaths.foodDatabase,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const FoodDatabaseScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.foodDetail,
        pageBuilder: (context, state) {
          final log = state.extra as Map<String, dynamic>;
          return smoothPushPage(
            state: state,
            child: FoodDetailScreen(log: log),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.fixResults,
        pageBuilder: (context, state) {
          final log = state.extra as Map<String, dynamic>;
          return smoothPushPage(
            state: state,
            child: FixResultsScreen(log: log),
          );
        },
      ),
    ];
