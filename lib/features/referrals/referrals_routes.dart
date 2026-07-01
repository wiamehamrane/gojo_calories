import 'package:go_router/go_router.dart';
import '../../core/routing/route_paths.dart';
import 'presentation/screens/referrals_screen.dart';

List<RouteBase> get referralRoutes => [
      GoRoute(
        path: RoutePaths.profileReferrals,
        builder: (context, state) => const ReferralsScreen(),
      ),
    ];
