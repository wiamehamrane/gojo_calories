import 'package:go_router/go_router.dart';
import '../../app/router_keys.dart';
import '../../core/routing/route_paths.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/auth_screen.dart';
import 'presentation/screens/verify_otp_screen.dart';
import 'presentation/screens/weight_setup_screen.dart';
import 'presentation/screens/paywall_screen.dart';

List<RouteBase> get authRoutes => [
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: RoutePaths.verifyOtp,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return VerifyOTPScreen(email: email);
        },
      ),
      GoRoute(
        path: RoutePaths.weightSetup,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const WeightSetupScreen(),
      ),
      GoRoute(
        path: RoutePaths.paywall,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const PaywallScreen(),
      ),
    ];
