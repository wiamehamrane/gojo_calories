import 'dart:io';

import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class SharedMealsRepository {
  final Dio _dio = ApiClient.instance;

  Future<List<dynamic>> getSharedMeals() async {
    final res = await _dio.get('meals');
    return res.data as List<dynamic>;
  }

  Future<List<dynamic>> getStarredMeals() async {
    final res = await _dio.get('meals/starred');
    return res.data as List<dynamic>;
  }

  Future<bool> toggleStar(String mealId) async {
    final res = await _dio.post('meals/$mealId/star');
    final data = res.data as Map<String, dynamic>;
    return data['is_starred'] as bool? ?? false;
  }

  Future<Map<String, dynamic>> toggleLike(String mealId) async {
    final res = await _dio.post('meals/$mealId/like');
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getComments(String mealId) async {
    final res = await _dio.get('meals/$mealId/comments');
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> addComment(String mealId, String body) async {
    final res = await _dio.post(
      'meals/$mealId/comments',
      data: {'body': body},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> toggleCommentLike(
    String mealId,
    String commentId,
  ) async {
    final res = await _dio.post('meals/$mealId/comments/$commentId/like');
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteComment(String mealId, String commentId) async {
    await _dio.delete('meals/$mealId/comments/$commentId');
  }

  Future<bool> setCommentsEnabled(String mealId, bool enabled) async {
    final res = await _dio.patch(
      'meals/$mealId/comments-enabled',
      data: {'comments_enabled': enabled},
    );
    final data = res.data as Map<String, dynamic>;
    return data['comments_enabled'] as bool? ?? enabled;
  }

  Future<Map<String, dynamic>> getPublicProfile(String userId) async {
    final res = await _dio.get('users/$userId/profile');
    return res.data as Map<String, dynamic>;
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
