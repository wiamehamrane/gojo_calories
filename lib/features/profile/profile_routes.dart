import 'package:go_router/go_router.dart';
import '../../core/routing/route_paths.dart';
import '../../core/routing/app_page_transitions.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/personal_details_screen.dart';
import 'presentation/screens/preferences_screen.dart';
import 'presentation/screens/language_screen.dart';
import 'presentation/screens/nutrition_goals_screen.dart';
import 'presentation/screens/feature_request_screen.dart';
import '../clan/presentation/screens/clan_screen.dart';
import '../share/presentation/screens/share_access_screen.dart';
import '../share/presentation/screens/share_accept_screen.dart';
import '../share/presentation/screens/shared_client_diary_screen.dart';

List<RouteBase> get profileShellRoutes => [
      GoRoute(
        path: RoutePaths.profile,
        pageBuilder: (context, state) => tabTransitionPage(
          state: state,
          child: const ProfileScreen(),
        ),
      ),
    ];

List<RouteBase> get profileRoutes => [
      GoRoute(
        path: RoutePaths.profilePersonal,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const PersonalDetailsScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.profilePreferences,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const PreferencesScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.profileLanguage,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const LanguageScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.profileNutrition,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const NutritionGoalsScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.featureRequest,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const FeatureRequestScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.profileClan,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const ClanScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.profileShare,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const ShareAccessScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.shareClientDiary,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          final name = extra?['name'] as String? ?? 'Client';
          return smoothPushPage(
            state: state,
            child: SharedClientDiaryScreen(
              ownerId: id,
              displayName: name,
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.shareJoin,
        pageBuilder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return smoothPushPage(
            state: state,
            child: ShareAcceptScreen(token: token),
          );
        },
      ),
    ];
