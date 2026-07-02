import 'package:go_router/go_router.dart';

import '../../core/routing/route_paths.dart';
import 'presentation/screens/create_task_screen.dart';
import 'presentation/screens/task_timer_screen.dart';
import 'presentation/screens/tasks_screen.dart';

List<RouteBase> get tasksRoutes => [
      GoRoute(
        path: RoutePaths.tasks,
        builder: (context, state) => const TasksScreen(),
      ),
      GoRoute(
        path: RoutePaths.createTask,
        builder: (context, state) => const CreateTaskScreen(),
      ),
      GoRoute(
        path: RoutePaths.taskTimer,
        builder: (context, state) {
          final taskId = state.extra as String? ?? '';
          return TaskTimerScreen(taskId: taskId);
        },
      ),
    ];
