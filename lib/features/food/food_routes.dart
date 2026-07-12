import 'package:go_router/go_router.dart';
import '../../core/routing/route_paths.dart';
import 'presentation/screens/scan_food_screen.dart';
import 'presentation/screens/food_log_screen.dart';
import 'presentation/screens/food_detail_screen.dart';
import 'presentation/screens/fix_results_screen.dart';
import 'presentation/screens/food_database_screen.dart';

List<RouteBase> get foodShellRoutes => [
      GoRoute(
        path: RoutePaths.scan,
        builder: (context, state) => const ScanFoodScreen(),
      ),
      GoRoute(
        path: RoutePaths.log,
        builder: (context, state) => const FoodLogScreen(),
      ),
    ];

List<RouteBase> get foodRoutes => [
      GoRoute(
        path: RoutePaths.foodDatabase,
        builder: (context, state) => const FoodDatabaseScreen(),
      ),
      GoRoute(
        path: RoutePaths.foodDetail,
        builder: (context, state) {
          final log = state.extra as Map<String, dynamic>;
          return FoodDetailScreen(log: log);
        },
      ),
      GoRoute(
        path: RoutePaths.fixResults,
        builder: (context, state) {
          final log = state.extra as Map<String, dynamic>;
          return FixResultsScreen(log: log);
        },
      ),
    ];
