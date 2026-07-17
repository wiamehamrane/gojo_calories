import 'dart:typed_data';

/// Data needed to render a shareable meal nutrition card.
class MealShareData {
  final String name;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final List<String> ingredients;
  final String? authorName;

  const MealShareData({
    required this.name,
    this.imageUrl,
    this.imageBytes,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.ingredients = const [],
    this.authorName,
  });

  MealShareData copyWith({Uint8List? imageBytes}) {
    return MealShareData(
      name: name,
      imageUrl: imageUrl,
      imageBytes: imageBytes ?? this.imageBytes,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      ingredients: ingredients,
      authorName: authorName,
    );
  }
}
