import 'dart:io';

import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class ProgressPhotosRepository {
  final Dio _dio = ApiClient.instance;

  Future<List<dynamic>> getPhotos() async {
    final res = await _dio.get('progress-photos');
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> uploadPhoto(
    File imageFile, {
    String? note,
    String? pose,
    DateTime? photoDate,
  }) async {
    if (!await imageFile.exists()) {
      throw StateError('Photo file is missing — please retake.');
    }
    final bytes = await imageFile.length();
    if (bytes <= 0) {
      throw StateError('Photo file is empty — please retake.');
    }

    final date = photoDate ?? DateTime.now();
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        imageFile.path,
        filename:
            'progress_${pose ?? 'shot'}_${date.millisecondsSinceEpoch}.jpg',
      ),
      if (note != null && note.isNotEmpty) 'note': note,
      if (pose != null && pose.isNotEmpty) 'pose': pose,
      'photo_date':
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    });

    final res = await _dio.post(
      'progress-photos',
      data: formData,
      options: Options(
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> deletePhoto(String id) async {
    await _dio.delete('progress-photos/$id');
  }
}
