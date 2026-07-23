import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/models/coach.dart';
import '../../domain/models/coach_post.dart';

class CoachesRepository {
  Future<CoachSearchPage> search({
    required double lat,
    required double lng,
    String? specialty,
    String? gender,
    int page = 1,
    int pageSize = 5,
  }) async {
    final res = await ApiClient.instance.get(
      'coaches/search',
      queryParameters: {
        'lat': lat,
        'lng': lng,
        'page': page,
        'page_size': pageSize,
        if (specialty != null && specialty.isNotEmpty) 'specialty': specialty,
        if (gender != null && gender.isNotEmpty) 'gender': gender,
      },
    );
    return CoachSearchPage.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<Coach> getPublic(String coachId) async {
    final res = await ApiClient.instance.get('coaches/$coachId');
    return Coach.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<CoachContact> contact(String coachId) async {
    final res = await ApiClient.instance.post('coaches/$coachId/contact');
    return CoachContact.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<MyCoachResponse> getMe() async {
    final res = await ApiClient.instance.get('coaches/me');
    return MyCoachResponse.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<CoachOwnerProfile> upsertMe(Map<String, dynamic> body) async {
    final res = await ApiClient.instance.put('coaches/me', data: body);
    return CoachOwnerProfile.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<CoachOwnerProfile> activate() async {
    final res = await ApiClient.instance.post('coaches/activate');
    return CoachOwnerProfile.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<CoachOwnerProfile> deactivate() async {
    final res = await ApiClient.instance.post('coaches/deactivate');
    return CoachOwnerProfile.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<CoachSocialProfile> getSocial(String coachId) async {
    final res = await ApiClient.instance.get('coaches/$coachId/social');
    return CoachSocialProfile.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<bool> toggleStar(String coachId) async {
    final res = await ApiClient.instance.post('coaches/$coachId/star');
    final data = Map<String, dynamic>.from(res.data as Map);
    return data['is_starred'] as bool? ?? false;
  }

  Future<List<Coach>> listStarred() async {
    final res = await ApiClient.instance.get('coaches/me/starred');
    final data = Map<String, dynamic>.from(res.data as Map);
    final raw = data['items'] as List? ?? const [];
    return raw
        .whereType<Map>()
        .map((e) => Coach.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<CoachPostPage> listPosts({
    required String coachId,
    String tab = 'all',
    int page = 1,
    int pageSize = 18,
  }) async {
    final res = await ApiClient.instance.get(
      'coaches/$coachId/posts',
      queryParameters: {
        'tab': tab,
        'page': page,
        'page_size': pageSize,
      },
    );
    return CoachPostPage.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<CoachPostPage> listMyPosts({
    String tab = 'all',
    int page = 1,
    int pageSize = 18,
  }) async {
    final res = await ApiClient.instance.get(
      'coaches/me/posts',
      queryParameters: {
        'tab': tab,
        'page': page,
        'page_size': pageSize,
      },
    );
    return CoachPostPage.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<CoachPost> createPost({
    required String postType,
    required File media,
    File? after,
    File? thumbnail,
    String? caption,
  }) async {
    final map = <String, dynamic>{
      'post_type': postType,
      if (caption != null && caption.trim().isNotEmpty) 'caption': caption.trim(),
    };

    if (postType == 'before_after') {
      if (after == null) {
        throw ArgumentError('after image is required for before_after posts');
      }
      map['before'] = await MultipartFile.fromFile(
        media.path,
        filename: media.path.split('/').last,
      );
      map['after'] = await MultipartFile.fromFile(
        after.path,
        filename: after.path.split('/').last,
      );
    } else {
      map['media'] = await MultipartFile.fromFile(
        media.path,
        filename: media.path.split('/').last,
      );
      if (thumbnail != null) {
        map['thumbnail'] = await MultipartFile.fromFile(
          thumbnail.path,
          filename: thumbnail.path.split('/').last,
        );
      }
    }

    final res = await ApiClient.instance.post(
      'coaches/me/posts',
      data: FormData.fromMap(map),
    );
    return CoachPost.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<void> deletePost(String postId) async {
    await ApiClient.instance.delete('coaches/me/posts/$postId');
  }

  Future<CoachPost> updatePostCaption(String postId, String? caption) async {
    final res = await ApiClient.instance.patch(
      'coaches/me/posts/$postId',
      data: {'caption': caption},
    );
    return CoachPost.fromJson(Map<String, dynamic>.from(res.data as Map));
  }
}

class MyCoachResponse {
  final CoachOwnerProfile? profile;
  final bool userIsCoach;
  final bool userHasPaid;

  const MyCoachResponse({
    this.profile,
    required this.userIsCoach,
    required this.userHasPaid,
  });

  factory MyCoachResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['profile'];
    return MyCoachResponse(
      profile: raw is Map
          ? CoachOwnerProfile.fromJson(Map<String, dynamic>.from(raw))
          : null,
      userIsCoach: json['user_is_coach'] as bool? ?? false,
      userHasPaid: json['user_has_paid'] as bool? ?? false,
    );
  }
}

class CoachOwnerProfile {
  final String id;
  final String userId;
  final String? name;
  final String? bio;
  final List<String> specialties;
  final String? gender;
  final int? experienceYears;
  final String? photoUrl;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final String? city;
  final List<String> languages;
  final String? coachingMode;
  final bool isActive;
  final bool userIsCoach;
  final bool userHasPaid;

  const CoachOwnerProfile({
    required this.id,
    required this.userId,
    this.name,
    this.bio,
    this.specialties = const [],
    this.gender,
    this.experienceYears,
    this.photoUrl,
    this.phone,
    this.latitude,
    this.longitude,
    this.city,
    this.languages = const [],
    this.coachingMode,
    this.isActive = false,
    this.userIsCoach = false,
    this.userHasPaid = false,
  });

  factory CoachOwnerProfile.fromJson(Map<String, dynamic> json) {
    List<String> asList(dynamic value) {
      if (value is! List) return const [];
      return value
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return CoachOwnerProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String?,
      bio: json['bio'] as String?,
      specialties: asList(json['specialties']),
      gender: json['gender'] as String?,
      experienceYears: json['experience_years'] as int?,
      photoUrl: json['photo_url'] as String? ?? json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      city: json['city'] as String?,
      languages: asList(json['languages']),
      coachingMode: json['coaching_mode'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      userIsCoach: json['user_is_coach'] as bool? ?? false,
      userHasPaid: json['user_has_paid'] as bool? ?? false,
    );
  }
}

class CoachContact {
  final String coachId;
  final String? phone;
  final String? callUri;
  final String? whatsappUrl;

  const CoachContact({
    required this.coachId,
    this.phone,
    this.callUri,
    this.whatsappUrl,
  });

  factory CoachContact.fromJson(Map<String, dynamic> json) {
    return CoachContact(
      coachId: json['coach_id'] as String,
      phone: json['phone'] as String?,
      callUri: json['call_uri'] as String?,
      whatsappUrl: json['whatsapp_url'] as String?,
    );
  }
}
