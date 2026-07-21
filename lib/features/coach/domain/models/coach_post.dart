import '../../../../core/config/env_config.dart';

class CoachPostMedia {
  final String id;
  final String mediaType; // image | video
  final String url;
  final String? thumbnailUrl; // preview frame for videos
  final String? role; // single | before | after
  final int sortOrder;

  const CoachPostMedia({
    required this.id,
    required this.mediaType,
    required this.url,
    this.thumbnailUrl,
    this.role,
    this.sortOrder = 0,
  });

  bool get isVideo => mediaType == 'video';
  bool get isImage => mediaType == 'image';

  factory CoachPostMedia.fromJson(Map<String, dynamic> json) {
    final rawThumb = json['thumbnail_url'] as String?;
    return CoachPostMedia(
      id: json['id'] as String,
      mediaType: json['media_type'] as String? ?? 'image',
      url: EnvConfig.resolveMediaUrl(json['url'] as String?),
      thumbnailUrl: (rawThumb == null || rawThumb.isEmpty)
          ? null
          : EnvConfig.resolveMediaUrl(rawThumb),
      role: json['role'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}

class CoachPost {
  final String id;
  final String coachId;
  final String postType; // image | video | before_after
  final String? caption;
  final DateTime? createdAt;
  final List<CoachPostMedia> media;

  const CoachPost({
    required this.id,
    required this.coachId,
    required this.postType,
    this.caption,
    this.createdAt,
    this.media = const [],
  });

  bool get isVideo => postType == 'video';
  bool get isBeforeAfter => postType == 'before_after';
  bool get isImage => postType == 'image';

  CoachPostMedia? get coverMedia {
    if (media.isEmpty) return null;
    final sorted = [...media]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return sorted.first;
  }

  factory CoachPost.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media'] as List? ?? const [];
    return CoachPost(
      id: json['id'] as String,
      coachId: json['coach_id'] as String,
      postType: json['post_type'] as String? ?? 'image',
      caption: json['caption'] as String?,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      media: rawMedia
          .whereType<Map>()
          .map((e) => CoachPostMedia.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
    );
  }
}

class CoachPostPage {
  final List<CoachPost> items;
  final int page;
  final int pageSize;
  final int total;
  final bool hasMore;

  const CoachPostPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasMore,
  });

  factory CoachPostPage.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] as List? ?? const [];
    return CoachPostPage(
      items: raw
          .whereType<Map>()
          .map((e) => CoachPost.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 18,
      total: json['total'] as int? ?? 0,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }
}

class CoachSocialProfile {
  final String id;
  final String userId;
  final String? name;
  final String? avatarUrl;
  final String? bio;
  final List<String> specialties;
  final String? city;
  final bool isActive;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;
  final bool isOwner;

  const CoachSocialProfile({
    required this.id,
    required this.userId,
    this.name,
    this.avatarUrl,
    this.bio,
    this.specialties = const [],
    this.city,
    this.isActive = false,
    this.postsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowing = false,
    this.isOwner = false,
  });

  CoachSocialProfile copyWith({
    int? postsCount,
    int? followersCount,
    int? followingCount,
    bool? isFollowing,
  }) {
    return CoachSocialProfile(
      id: id,
      userId: userId,
      name: name,
      avatarUrl: avatarUrl,
      bio: bio,
      specialties: specialties,
      city: city,
      isActive: isActive,
      postsCount: postsCount ?? this.postsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowing: isFollowing ?? this.isFollowing,
      isOwner: isOwner,
    );
  }

  factory CoachSocialProfile.fromJson(Map<String, dynamic> json) {
    List<String> asList(dynamic value) {
      if (value is! List) return const [];
      return value
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return CoachSocialProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      specialties: asList(json['specialties']),
      city: json['city'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      postsCount: json['posts_count'] as int? ?? 0,
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      isFollowing: json['is_following'] as bool? ?? false,
      isOwner: json['is_owner'] as bool? ?? false,
    );
  }
}
