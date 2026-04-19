import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

final myGroupsProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    final res = await ApiClient.instance.get('groups/my');
    return res.data ?? [];
  } catch (e) {
    return [];
  }
});

final discoverGroupsProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    final res = await ApiClient.instance.get('groups/discover');
    return res.data ?? [];
  } catch (e) {
    return [];
  }
});

final communityFeedProvider = FutureProvider<List<dynamic>>((ref) async {
  try {
    final res = await ApiClient.instance.get('groups/feed');
    return res.data ?? [];
  } catch (e) {
    return [];
  }
});

class GroupsController {
  static Future<void> joinGroup(int groupId) async {
    try {
      await ApiClient.instance.post('groups/$groupId/join');
    } catch (e) {
      // Handle error
    }
  }
}
