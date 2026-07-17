import 'package:go_router/go_router.dart';
import '../../core/routing/app_page_transitions.dart';
import '../../core/routing/route_paths.dart';
import 'presentation/screens/referrals_screen.dart';

List<RouteBase> get referralRoutes => [
      GoRoute(
        path: RoutePaths.profileReferrals,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const ReferralsScreen(),
        ),
      ),
    ];
