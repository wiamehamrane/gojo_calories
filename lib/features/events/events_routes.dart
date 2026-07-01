import 'package:go_router/go_router.dart';
import '../../core/routing/route_paths.dart';
import 'presentation/screens/events_feed_screen.dart';

List<RouteBase> get eventsShellRoutes => [
      GoRoute(
        path: RoutePaths.events,
        builder: (context, state) => const EventsFeedScreen(),
      ),
    ];
