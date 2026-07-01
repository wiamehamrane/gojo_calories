import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/repository_providers.dart';

class Friend {
  final String id;
  final String? name;
  final String email;

  Friend({required this.id, this.name, required this.email});

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
      final data = await ref.read(friendsRepositoryProvider).getFriends();
      state = AsyncValue.data(data.map((f) => Friend.fromJson(f)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<List<UserSearchResult>> searchUsers(String query) async {
    try {
      final data = await ref.read(friendsRepositoryProvider).searchUsers(query);
      return data.map((u) => UserSearchResult.fromJson(u)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> addFriend(String userId) async {
    try {
      await ref.read(friendsRepositoryProvider).addFriend(userId);
      await fetchFriends();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> removeFriend(String userId) async {
    try {
      await ref.read(friendsRepositoryProvider).removeFriend(userId);
      await fetchFriends();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final friendsProvider = NotifierProvider<FriendsNotifier, AsyncValue<List<Friend>>>(
  FriendsNotifier.new,
);
