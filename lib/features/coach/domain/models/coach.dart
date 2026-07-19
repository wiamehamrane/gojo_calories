import '../../../../core/config/env_config.dart';

class CoachWork {
  final String id;
  final String beforeUrl;
  final String afterUrl;
  final String? caption;
  final DateTime? createdAt;

  const CoachWork({
    required this.id,
    required this.beforeUrl,
    required this.afterUrl,
    this.caption,
    this.createdAt,
  });

  factory CoachWork.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value is! String || value.isEmpty) return null;
      return DateTime.tryParse(value);
    }

    return CoachWork(
      id: json['id'] as String,
      beforeUrl: EnvConfig.resolveMediaUrl(json['before_url'] as String?),
      afterUrl: EnvConfig.resolveMediaUrl(json['after_url'] as String?),
      caption: json['caption'] as String?,
      createdAt: parseDate(json['created_at']),
    );
  }
}

class Coach {
  final String id;
  final String userId;
  final String? name;
  final String? avatarUrl;
  final String? bio;
  final List<String> specialties;
  final String? gender;
  final int? experienceYears;
  final double? latitude;
  final double? longitude;
  final String? city;
  final List<String> languages;
  final String? coachingMode;
  final bool isActive;
  final double? distanceKm;
  final List<CoachWork> works;

  const Coach({
    required this.id,
    required this.userId,
    this.name,
    this.avatarUrl,
    this.bio,
    this.specialties = const [],
    this.gender,
    this.experienceYears,
    this.latitude,
    this.longitude,
    this.city,
    this.languages = const [],
    this.coachingMode,
    this.isActive = false,
    this.distanceKm,
    this.works = const [],
  });

  factory Coach.fromJson(Map<String, dynamic> json) {
    final rawWorks = json['works'] as List? ?? const [];
    return Coach(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      specialties: _stringList(json['specialties']),
      gender: json['gender'] as String?,
      experienceYears: json['experience_years'] as int?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      city: json['city'] as String?,
      languages: _stringList(json['languages']),
      coachingMode: json['coaching_mode'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      works: rawWorks
          .whereType<Map>()
          .map((e) => CoachWork.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }
}

class CoachSearchPage {
  final List<Coach> items;
  final int page;
  final int pageSize;
  final int total;
  final bool hasMore;

  const CoachSearchPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasMore,
  });

  factory CoachSearchPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? const [];
    return CoachSearchPage(
      items: rawItems
          .map((e) => Coach.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      page: json['page'] as int? ?? 1,
      pageSize: json['page_size'] as int? ?? 5,
      total: json['total'] as int? ?? 0,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }
}
