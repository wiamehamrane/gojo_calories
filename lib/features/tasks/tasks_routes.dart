import 'package:go_router/go_router.dart';

import '../../core/routing/app_page_transitions.dart';
import '../../core/routing/route_paths.dart';
import 'presentation/screens/create_task_screen.dart';
import 'presentation/screens/task_timer_screen.dart';
import 'presentation/screens/tasks_screen.dart';

List<RouteBase> get tasksRoutes => [
      GoRoute(
        path: RoutePaths.tasks,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const TasksScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.createTask,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const CreateTaskScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.taskTimer,
        pageBuilder: (context, state) {
          final taskId = state.extra as String? ?? '';
          return smoothPushPage(
            state: state,
            child: TaskTimerScreen(taskId: taskId),
          );
        },
      ),
    ];
