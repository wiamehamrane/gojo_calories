import 'package:go_router/go_router.dart';
import '../../core/routing/route_paths.dart';
import 'presentation/screens/log_exercise_screen.dart';
import 'presentation/screens/run_intensity_screen.dart';
import 'presentation/screens/weight_lifting_screen.dart';
import 'presentation/screens/describe_exercise_screen.dart';
import 'presentation/screens/manual_exercise_screen.dart';

List<RouteBase> get exerciseRoutes => [
      GoRoute(
        path: RoutePaths.logExercise,
        builder: (context, state) => const LogExerciseScreen(),
      ),
      GoRoute(
        path: RoutePaths.runIntensity,
        builder: (context, state) => const RunIntensityScreen(),
      ),
      GoRoute(
        path: RoutePaths.weightLifting,
        builder: (context, state) => const WeightLiftingScreen(),
      ),
      GoRoute(
        path: RoutePaths.describeExercise,
        builder: (context, state) => const DescribeExerciseScreen(),
      ),
      GoRoute(
        path: RoutePaths.manualExercise,
        builder: (context, state) => const ManualExerciseScreen(),
      ),
    ];
