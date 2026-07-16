import 'dart:io';

import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class SharedMealsRepository {
  final Dio _dio = ApiClient.instance;

  Future<List<dynamic>> getSharedMeals() async {
    final res = await _dio.get('meals');
    return res.data as List<dynamic>;
  }

  /// Provide either [imageFile] (new photo) or [sourceImageUrl] (reuse an
  /// existing food-log photo).
  Future<Map<String, dynamic>> shareMeal({
    required String name,
    required List<String> ingredients,
    required String instructions,
    required int calories,
    required int protein,
    required int carbs,
    required int fat,
    File? imageFile,
    String? sourceImageUrl,
  }) async {
    final formData = FormData.fromMap({
      'name': name,
      'ingredients': ingredients.join('\n'),
      'instructions': instructions,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      if (sourceImageUrl != null && sourceImageUrl.isNotEmpty)
        'source_image_url': sourceImageUrl,
      if (imageFile != null)
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'meal.jpg',
        ),
    });
    final res = await _dio.post('meals', data: formData);
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteMeal(String mealId) async {
    await _dio.delete('meals/$mealId');
  }
}
