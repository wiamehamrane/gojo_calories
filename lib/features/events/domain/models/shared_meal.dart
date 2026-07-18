class SharedMeal {
  final String id;
  final String userId;
  final String authorName;
  final String name;
  final String? imageUrl;
  final List<String> ingredients;
  final String? instructions;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final bool isStarred;
  final bool isLiked;
  final int likesCount;
  final int commentsCount;
  final bool commentsEnabled;
  final bool authorProfilePublic;
  final DateTime? createdAt;

  SharedMeal({
    required this.id,
    required this.userId,
    required this.authorName,
    required this.name,
    this.imageUrl,
    this.ingredients = const [],
    this.instructions,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.isStarred = false,
    this.isLiked = false,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.commentsEnabled = true,
    this.authorProfilePublic = true,
    this.createdAt,
  });

  factory SharedMeal.fromJson(Map<String, dynamic> json) {
    return SharedMeal(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      authorName: json['author_name'] as String? ?? 'Gojo member',
      name: json['name'] as String? ?? 'Meal',
      imageUrl: json['image_url'] as String?,
      ingredients: (json['ingredients'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      instructions: json['instructions'] as String?,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toInt() ?? 0,
      carbs: (json['carbs'] as num?)?.toInt() ?? 0,
      fat: (json['fat'] as num?)?.toInt() ?? 0,
      isStarred: json['is_starred'] as bool? ?? false,
      isLiked: json['is_liked'] as bool? ?? false,
      likesCount: _jsonInt(json['likes_count']),
      commentsCount: _jsonInt(json['comments_count']),
      commentsEnabled: json['comments_enabled'] as bool? ?? true,
      authorProfilePublic: json['author_profile_public'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  SharedMeal copyWith({
    bool? isStarred,
    bool? isLiked,
    int? likesCount,
    int? commentsCount,
    bool? commentsEnabled,
  }) {
    return SharedMeal(
      id: id,
      userId: userId,
      authorName: authorName,
      name: name,
      imageUrl: imageUrl,
      ingredients: ingredients,
      instructions: instructions,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      isStarred: isStarred ?? this.isStarred,
      isLiked: isLiked ?? this.isLiked,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      commentsEnabled: commentsEnabled ?? this.commentsEnabled,
      authorProfilePublic: authorProfilePublic,
      createdAt: createdAt,
    );
  }
}

class SharedMealComment {
  final String id;
  final String mealId;
  final String userId;
  final String authorName;
  final String? authorAvatarUrl;
  final String body;
  final int likesCount;
  final bool isLiked;
  final bool profilePublic;
  final DateTime? createdAt;

  SharedMealComment({
    required this.id,
    required this.mealId,
    required this.userId,
    required this.authorName,
    this.authorAvatarUrl,
    required this.body,
    this.likesCount = 0,
    this.isLiked = false,
    this.profilePublic = true,
    this.createdAt,
  });

  factory SharedMealComment.fromJson(Map<String, dynamic> json) {
    return SharedMealComment(
      id: json['id'] as String,
      mealId: json['meal_id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      authorName: json['author_name'] as String? ?? 'Gojo member',
      authorAvatarUrl: json['author_avatar_url'] as String?,
      body: json['body'] as String? ?? '',
      likesCount: _jsonInt(json['likes_count']),
      isLiked: json['is_liked'] as bool? ?? false,
      profilePublic: json['profile_public'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  SharedMealComment copyWith({bool? isLiked, int? likesCount}) {
    return SharedMealComment(
      id: id,
      mealId: mealId,
      userId: userId,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      body: body,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      profilePublic: profilePublic,
      createdAt: createdAt,
    );
  }
}

int _jsonInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}
