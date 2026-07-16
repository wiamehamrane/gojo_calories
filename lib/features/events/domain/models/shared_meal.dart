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
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}
