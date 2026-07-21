import 'package:go_router/go_router.dart';

import '../../app/router_keys.dart';
import '../../core/routing/app_page_transitions.dart';
import '../../core/routing/route_paths.dart';
import 'domain/models/coach_post.dart';
import 'presentation/screens/become_coach_screen.dart';
import 'presentation/screens/coach_detail_screen.dart';
import 'presentation/screens/coach_discover_screen.dart';
import 'presentation/screens/coach_hub_screen.dart';
import 'presentation/screens/coach_portfolio_screen.dart';
import 'presentation/screens/coach_post_viewer_screen.dart';
import 'presentation/screens/coach_social_profile_screen.dart';
import 'presentation/screens/create_coach_post_screen.dart';

List<RouteBase> get coachRoutes => [
      GoRoute(
        path: RoutePaths.coaches,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const CoachDiscoverScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.coachAbout,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return smoothPushPage(
            state: state,
            child: CoachDetailScreen(coachId: id),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.coachDetail,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return smoothPushPage(
            state: state,
            child: CoachSocialProfileScreen(coachId: id),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.coachHub,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const CoachHubScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.coachPortfolio,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const CoachPortfolioScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.coachCreatePost,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const CreateCoachPostScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.coachPostViewer,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          final extra = state.extra;
          List<CoachPost> posts = const [];
          var index = 0;
          var isOwner = false;
          String? coachName;
          String? coachAvatarUrl;
          if (extra is Map) {
            final rawPosts = extra['posts'];
            if (rawPosts is List<CoachPost>) {
              posts = rawPosts;
            }
            index = extra['index'] as int? ?? 0;
            isOwner = extra['isOwner'] as bool? ?? false;
            coachName = extra['coachName'] as String?;
            coachAvatarUrl = extra['coachAvatarUrl'] as String?;
          }
          return smoothPushPage(
            state: state,
            child: CoachPostViewerScreen(
              posts: posts,
              initialIndex: index,
              isOwner: isOwner,
              coachName: coachName,
              coachAvatarUrl: coachAvatarUrl,
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.becomeCoach,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) => smoothPushPage(
          state: state,
          child: const BecomeCoachScreen(),
        ),
      ),
    ];
