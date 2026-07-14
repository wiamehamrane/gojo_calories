import 'package:go_router/go_router.dart';
import '../../core/routing/route_paths.dart';
import '../../core/routing/app_page_transitions.dart';
import 'presentation/screens/log_exercise_screen.dart';
import 'presentation/screens/run_intensity_screen.dart';
import 'presentation/screens/weight_lifting_screen.dart';
import 'presentation/screens/describe_exercise_screen.dart';
import 'presentation/screens/manual_exercise_screen.dart';

List<RouteBase> get exerciseRoutes => [
      GoRoute(
        path: RoutePaths.logExercise,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const LogExerciseScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.runIntensity,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const RunIntensityScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.weightLifting,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const WeightLiftingScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.describeExercise,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const DescribeExerciseScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.manualExercise,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const ManualExerciseScreen(),
        ),
      ),
    ];
