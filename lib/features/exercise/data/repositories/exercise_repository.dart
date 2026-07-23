import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';

class ExerciseRepository {
  final _dio = ApiClient.instance;

  static final _visionOptions = Options(
    sendTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 90),
  );

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
      options: _visionOptions,
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// Photo of gym machine + sets/reps → AI name, duration, calories.
  Future<Map<String, dynamic>> analyzeMachineWorkout({
    required File image,
    required List<Map<String, dynamic>> sets,
    String? nameHint,
  }) async {
    final payload = <String, dynamic>{
      'file': await MultipartFile.fromFile(
        image.path,
        filename: image.path.split('/').last,
      ),
      'sets_json': jsonEncode(
        sets
            .map(
              (s) => {
                'reps': s['reps'],
                'weight_kg': s['weight_kg'] ?? s['weight'] ?? 0,
              },
            )
            .toList(),
      ),
    };
    if (nameHint != null && nameHint.trim().isNotEmpty) {
      payload['name_hint'] = nameHint.trim();
    }

    final res = await _dio.post(
      'exercises/analyze/machine',
      data: FormData.fromMap(payload),
      options: _visionOptions,
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
    String? imageUrl,
    String? setsSummary,
  }) async {
    await _dio.post(
      'exercises/',
      data: {
        'name': name,
        'duration_minutes': durationMinutes,
        'calories_burned': caloriesBurned,
        'local_date': ?localDate,
        'image_url': ?imageUrl,
        'sets_summary': ?setsSummary,
      },
    );
  }
}
