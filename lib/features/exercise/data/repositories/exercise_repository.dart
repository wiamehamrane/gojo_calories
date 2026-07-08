import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';

class ExerciseRepository {
  final _dio = ApiClient.instance;

  Future<List<Map<String, dynamic>>> getExercises({
    String? date,
    int? tzOffset,
  }) async {
    final res = await _dio.get(
      'exercises/',
      queryParameters: {
        'date': ?date,
        'tz_offset': ?tzOffset,
      },
    );
    final data = res.data;
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>> analyzeDescription(String description) async {
    final res = await _dio.post(
      'exercises/analyze',
      data: {'description': description},
      options: Options(
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 90),
      ),
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> deleteExercise(String exerciseId) async {
    await _dio.delete('exercises/$exerciseId');
  }

  Future<void> logExercise({
    required String name,
    required int durationMinutes,
    required int caloriesBurned,
    String? localDate,
  }) async {
    await _dio.post(
      'exercises/',
      data: {
        'name': name,
        'duration_minutes': durationMinutes,
        'calories_burned': caloriesBurned,
        'local_date': ?localDate,
      },
    );
  }
}
