import 'package:go_router/go_router.dart';
import '../../app/router_keys.dart';
import '../../core/routing/route_paths.dart';
import '../../core/routing/app_page_transitions.dart';
import 'domain/models/event.dart';
import 'presentation/screens/create_event_screen.dart';
import 'presentation/screens/edit_event_screen.dart';
import 'presentation/screens/event_detail_screen.dart';
import 'presentation/screens/events_feed_screen.dart';
import 'presentation/screens/my_events_screen.dart';
import 'presentation/screens/share_meal_chooser_screen.dart';
import 'presentation/screens/share_existing_meal_screen.dart';
import 'presentation/screens/share_meal_screen.dart';
import 'presentation/screens/starred_meals_screen.dart';
import 'presentation/screens/public_profile_screen.dart';

List<RouteBase> get eventsShellRoutes => [
      GoRoute(
        path: RoutePaths.events,
        pageBuilder: (context, state) => tabTransitionPage(
          state: state,
          child: const EventsFeedScreen(),
        ),
      ),
    ];

/// Full-screen event routes (pushed above the bottom-nav shell).
List<RouteBase> get eventsRoutes => [
      GoRoute(
        path: RoutePaths.createEvent,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const CreateEventScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.eventDetail,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: EventDetailScreen(eventId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: RoutePaths.myEvents,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const MyEventsScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.editEvent,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: EditEventScreen(event: state.extra as Event),
        ),
      ),
      GoRoute(
        path: RoutePaths.shareMealChooser,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const ShareMealChooserScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.shareExistingMeal,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const ShareExistingMealScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.shareMeal,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: ShareMealScreen(
            prefill: state.extra as ShareMealPrefill?,
          ),
        ),
      ),
      GoRoute(
        path: RoutePaths.starredMeals,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const StarredMealsScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.publicProfile,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: PublicProfileScreen(
            userId: state.pathParameters['id']!,
          ),
        ),
      ),
    ];
