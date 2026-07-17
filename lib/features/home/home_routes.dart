import 'package:go_router/go_router.dart';
import '../../core/routing/route_paths.dart';
import '../../core/routing/tab_page_transition.dart';
import 'presentation/screens/home_screen.dart';

List<RouteBase> get homeRoutes => [
      GoRoute(
        path: RoutePaths.home,
        pageBuilder: (context, state) => tabTransitionPage(
          state: state,
          child: const HomeScreen(),
        ),
      ),
    ];
