import 'dart:io';

import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class FoodRepository {
  final Dio _dio = ApiClient.instance;

  Future<Map<String, dynamic>> analyzeImage(
    File image, {
    required String localDate,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        image.path,
        filename: image.path.split('/').last,
      ),
    });
    final res = await _dio.post(
      'food/analyze',
      data: formData,
      queryParameters: {'local_date': localDate},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getBarcodeNutrition(String barcode) async {
    final res = await _dio.get('food/barcode/$barcode');
    return res.data as Map<String, dynamic>;
  }

  Future<void> logBarcodeItem(
    Map<String, dynamic> data, {
    required String localDate,
  }) async {
    await _dio.post(
      'food/analyze/log',
      data: data,
      queryParameters: {'local_date': localDate},
    );
  }

  Future<List<dynamic>> searchFood(String query) async {
    final res = await _dio.get('food/search', queryParameters: {'query': query});
    final data = res.data;
    if (data is Map && data['results'] is List) {
      return data['results'] as List<dynamic>;
    }
    if (data is List) return data;
    return [];
  }

  Future<List<dynamic>> getHistory({
    required String date,
    required int tzOffset,
  }) async {
    final res = await _dio.get(
      'stats/history',
      queryParameters: {'date': date, 'tz_offset': tzOffset},
    );
    return res.data as List<dynamic>? ?? [];
  }

  Future<void> logFoodItem(Map<String, dynamic> data) async {
    await _dio.post('food/log', data: data);
  }

  Future<void> logAnalyzedFood(
    Map<String, dynamic> data, {
    required String localDate,
  }) async {
    await _dio.post(
      'food/analyze/log',
      data: data,
      queryParameters: {'local_date': localDate},
    );
  }

  Future<Map<String, dynamic>> fixFoodLog({
    required String logId,
    required String prompt,
  }) async {
    final res = await _dio.post(
      'food/analyze/fix',
      data: {'log_id': logId, 'prompt': prompt},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getIngredients(String name) async {
    final encoded = Uri.encodeComponent(name);
    final res = await _dio.get('food/ingredients/$encoded');
    final data = res.data;
    if (data is Map && data['ingredients'] is List) {
      return data['ingredients'] as List<dynamic>;
    }
    return res.data as List<dynamic>? ?? [];
  }

  Future<void> saveFood(Map<String, dynamic> data) async {
    await _dio.post('food/saved', data: data);
  }

  Future<List<dynamic>> getSavedFoods() async {
    final res = await _dio.get('food/saved');
    return res.data as List<dynamic>? ?? [];
  }

  Future<void> deleteSavedFood(String foodId) async {
    await _dio.delete('food/saved/$foodId');
  }
}
