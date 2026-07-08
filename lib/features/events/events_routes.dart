import 'package:go_router/go_router.dart';
import '../../app/router_keys.dart';
import '../../core/routing/route_paths.dart';
import 'domain/models/event.dart';
import 'presentation/screens/create_event_screen.dart';
import 'presentation/screens/edit_event_screen.dart';
import 'presentation/screens/event_detail_screen.dart';
import 'presentation/screens/events_feed_screen.dart';
import 'presentation/screens/my_events_screen.dart';

List<RouteBase> get eventsShellRoutes => [
      GoRoute(
        path: RoutePaths.events,
        builder: (context, state) => const EventsFeedScreen(),
      ),
    ];

/// Full-screen event routes (pushed above the bottom-nav shell).
List<RouteBase> get eventsRoutes => [
      GoRoute(
        path: RoutePaths.createEvent,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CreateEventScreen(),
      ),
      GoRoute(
        path: RoutePaths.eventDetail,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => EventDetailScreen(
          eventId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.myEvents,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const MyEventsScreen(),
      ),
      GoRoute(
        path: RoutePaths.editEvent,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => EditEventScreen(
          event: state.extra as Event,
        ),
      ),
    ];
