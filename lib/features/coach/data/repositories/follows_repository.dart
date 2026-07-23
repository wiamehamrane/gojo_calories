import '../../../../core/config/env_config.dart';
import '../../../../core/network/api_client.dart';

class FollowUserCard {
  final String id;
  final String? name;
  final String? avatarUrl;
  final bool isCoach;

  const FollowUserCard({
    required this.id,
    this.name,
    this.avatarUrl,
    this.isCoach = false,
  });

  factory FollowUserCard.fromJson(Map<String, dynamic> json) {
    return FollowUserCard(
      id: json['id'] as String,
      name: json['name'] as String?,
      avatarUrl: EnvConfig.resolveMediaUrl(json['avatar_url'] as String?),
      isCoach: json['is_coach'] as bool? ?? false,
    );
  }
}

class FollowActionResult {
  final bool following;
  final int followersCount;
  final int followingCount;

  const FollowActionResult({
    required this.following,
    required this.followersCount,
    required this.followingCount,
  });

  factory FollowActionResult.fromJson(Map<String, dynamic> json) {
    return FollowActionResult(
      following: json['following'] as bool? ?? false,
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
    );
  }
}

class FollowsRepository {
  Future<FollowActionResult> follow(String userId) async {
    final res = await ApiClient.instance.post('follows/$userId');
    return FollowActionResult.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<FollowActionResult> unfollow(String userId) async {
    final res = await ApiClient.instance.delete('follows/$userId');
    return FollowActionResult.fromJson(Map<String, dynamic>.from(res.data as Map));
  }
}
