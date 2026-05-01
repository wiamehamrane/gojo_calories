import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/auth_screen.dart';
import '../../features/onboarding/presentation/screens/weight_setup_screen.dart';
import '../../features/onboarding/presentation/screens/paywall_screen.dart';
import '../../features/dashboard/presentation/screens/home_screen.dart';

// Import shell/layout widget
import '../widgets/main_scaffold.dart';

// Import remaining screens
import '../../features/food_log/presentation/screens/food_log_screen.dart';
import '../../features/food_log/presentation/screens/scan_food_screen.dart';
import '../../features/food_log/presentation/screens/food_detail_screen.dart';
import '../../features/food_log/presentation/screens/fix_results_screen.dart';

import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/dashboard/presentation/screens/log_exercise_screen.dart';
import '../../features/dashboard/presentation/screens/run_intensity_screen.dart';
import '../../features/dashboard/presentation/screens/saved_foods_screen.dart';
import '../../features/dashboard/presentation/screens/food_database_screen.dart';
import '../../features/dashboard/presentation/screens/weight_lifting_screen.dart';
import '../../features/dashboard/presentation/screens/describe_exercise_screen.dart';
import '../../features/dashboard/presentation/screens/manual_exercise_screen.dart';
import '../../features/profile/presentation/screens/personal_details_screen.dart';
import '../../features/profile/presentation/screens/preferences_screen.dart';
import '../../features/profile/presentation/screens/language_screen.dart';
import '../../features/profile/presentation/screens/nutrition_goals_screen.dart';
import '../../features/profile/presentation/screens/feature_request_screen.dart';
import '../../features/referrals/presentation/screens/referrals_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),

    // New Auth / Onboarding Flow
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
    GoRoute(
      path: '/onboarding/weight',
      builder: (context, state) => const WeightSetupScreen(),
    ),
    GoRoute(
      path: '/onboarding/paywall',
      builder: (context, state) => const PaywallScreen(),
    ),

    // App Shell
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainScaffold(child: child);
      },
      routes: [
        GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
        GoRoute(
          path: '/scan',
          builder: (context, state) => const ScanFoodScreen(),
        ),
        GoRoute(
          path: '/log',
          builder: (context, state) => const FoodLogScreen(),
        ),

        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),

    // Auxiliary App Routes
    GoRoute(
      path: '/profile/personal',
      builder: (context, state) => const PersonalDetailsScreen(),
    ),
    GoRoute(
      path: '/profile/preferences',
      builder: (context, state) => const PreferencesScreen(),
    ),
    GoRoute(
      path: '/profile/language',
      builder: (context, state) => const LanguageScreen(),
    ),
    GoRoute(
      path: '/profile/nutrition',
      builder: (context, state) => const NutritionGoalsScreen(),
    ),
    GoRoute(
      path: '/log_exercise',
      builder: (context, state) => const LogExerciseScreen(),
    ),
    GoRoute(
      path: '/run_intensity',
      builder: (context, state) => const RunIntensityScreen(),
    ),
    GoRoute(
      path: '/weight_lifting',
      builder: (context, state) => const WeightLiftingScreen(),
    ),
    GoRoute(
      path: '/describe_exercise',
      builder: (context, state) => const DescribeExerciseScreen(),
    ),
    GoRoute(
      path: '/manual_exercise',
      builder: (context, state) => const ManualExerciseScreen(),
    ),
    GoRoute(
      path: '/profile/referrals',
      builder: (context, state) => const ReferralsScreen(),
    ),
    GoRoute(
      path: '/saved_foods',
      builder: (context, state) => const SavedFoodsScreen(),
    ),
    GoRoute(
      path: '/food_database',
      builder: (context, state) => const FoodDatabaseScreen(),
    ),
    GoRoute(
      path: '/feature_request',
      builder: (context, state) => const FeatureRequestScreen(),
    ),
    GoRoute(
      path: '/food-detail',
      builder: (context, state) {
        final log = state.extra as Map<String, dynamic>;
        return FoodDetailScreen(log: log);
      },
    ),
    GoRoute(
      path: '/fix-results',
      builder: (context, state) {
        final log = state.extra as Map<String, dynamic>;
        return FixResultsScreen(log: log);
      },
    ),
  ],
);
