import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class Friend {
  final String id;
  final String? name;
  final String email;

  Friend({
    required this.id,
    this.name,
    required this.email,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'],
      name: json['name'],
      email: json['email'],
    );
  }
}

class UserSearchResult {
  final String id;
  final String? name;
  final String email;
  final bool isFriend;

  UserSearchResult({
    required this.id,
    this.name,
    required this.email,
    required this.isFriend,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      isFriend: json['is_friend'],
    );
  }
}

class FriendsNotifier extends Notifier<AsyncValue<List<Friend>>> {
  @override
  AsyncValue<List<Friend>> build() {
    fetchFriends();
    return const AsyncValue.loading();
  }

  Future<void> fetchFriends() async {
    try {
      final res = await ApiClient.instance.get('friends');
      if (res.statusCode == 200) {
        final List<dynamic> data = res.data;
        state = AsyncValue.data(data.map((f) => Friend.fromJson(f)).toList());
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<UserSearchResult>> searchUsers(String query) async {
    try {
      final res = await ApiClient.instance.get('friends/search', queryParameters: {'query': query});
      if (res.statusCode == 200) {
        final List<dynamic> data = res.data;
        return data.map((u) => UserSearchResult.fromJson(u)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> addFriend(String userId) async {
    try {
      final res = await ApiClient.instance.post('friends/add/$userId');
      if (res.statusCode == 200) {
        fetchFriends();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeFriend(String userId) async {
    try {
      final res = await ApiClient.instance.delete('friends/remove/$userId');
      if (res.statusCode == 200) {
        fetchFriends();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

final friendsProvider = NotifierProvider<FriendsNotifier, AsyncValue<List<Friend>>>(() {
  return FriendsNotifier();
});
