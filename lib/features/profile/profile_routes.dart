import 'package:go_router/go_router.dart';
import '../../core/routing/route_paths.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/personal_details_screen.dart';
import 'presentation/screens/preferences_screen.dart';
import 'presentation/screens/language_screen.dart';
import 'presentation/screens/nutrition_goals_screen.dart';
import 'presentation/screens/feature_request_screen.dart';

List<RouteBase> get profileShellRoutes => [
      GoRoute(
        path: RoutePaths.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
    ];

List<RouteBase> get profileRoutes => [
      GoRoute(
        path: RoutePaths.profilePersonal,
        builder: (context, state) => const PersonalDetailsScreen(),
      ),
      GoRoute(
        path: RoutePaths.profilePreferences,
        builder: (context, state) => const PreferencesScreen(),
      ),
      GoRoute(
        path: RoutePaths.profileLanguage,
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: RoutePaths.profileNutrition,
        builder: (context, state) => const NutritionGoalsScreen(),
      ),
      GoRoute(
        path: RoutePaths.featureRequest,
        builder: (context, state) => const FeatureRequestScreen(),
      ),
    ];
