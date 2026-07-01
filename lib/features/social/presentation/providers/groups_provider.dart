import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/repository_providers.dart';

final myGroupsProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.read(groupsRepositoryProvider).getMyGroups();
});

final discoverGroupsProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.read(groupsRepositoryProvider).discoverGroups();
});

final communityFeedProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.read(groupsRepositoryProvider).getCommunityFeed();
});

class GroupsNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> joinGroup(String groupId) async {
    await ref.read(groupsRepositoryProvider).joinGroup(groupId);
    ref.invalidate(myGroupsProvider);
    ref.invalidate(discoverGroupsProvider);
  }
}

final groupsNotifierProvider =
    NotifierProvider<GroupsNotifier, AsyncValue<void>>(GroupsNotifier.new);
