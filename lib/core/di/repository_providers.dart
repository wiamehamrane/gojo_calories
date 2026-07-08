import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../../features/events/data/repositories/events_repository.dart';
import '../../features/food/data/repositories/food_repository.dart';
import '../../features/profile/data/repositories/profile_repository.dart';
import '../../features/referrals/data/repositories/referrals_repository.dart';
import '../../features/social/data/repositories/feed_repository.dart';
import '../../features/social/data/repositories/friends_repository.dart';
import '../../features/social/data/repositories/groups_repository.dart';
import '../../features/social/data/repositories/memories_repository.dart';
import '../../features/stats/data/repositories/stats_repository.dart';
import '../../features/exercise/data/repositories/exercise_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);

final foodRepositoryProvider = Provider<FoodRepository>(
  (ref) => FoodRepository(),
);

final statsRepositoryProvider = Provider<StatsRepository>(
  (ref) => StatsRepository(),
);

final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => FeedRepository(),
);

final friendsRepositoryProvider = Provider<FriendsRepository>(
  (ref) => FriendsRepository(),
);

final memoriesRepositoryProvider = Provider<MemoriesRepository>(
  (ref) => MemoriesRepository(),
);

final groupsRepositoryProvider = Provider<GroupsRepository>(
  (ref) => GroupsRepository(),
);

final eventsRepositoryProvider = Provider<EventsRepository>(
  (ref) => EventsRepository(),
);

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(),
);

final referralsRepositoryProvider = Provider<ReferralsRepository>(
  (ref) => ReferralsRepository(),
);

final exerciseRepositoryProvider = Provider<ExerciseRepository>(
  (ref) => ExerciseRepository(),
);
