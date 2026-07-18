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
    DateTime? photoDate,
  }) async {
    final fileName = imageFile.path.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imageFile.path, filename: fileName),
      if (note != null && note.isNotEmpty) 'note': note,
      if (photoDate != null)
        'photo_date':
            '${photoDate.year.toString().padLeft(4, '0')}-${photoDate.month.toString().padLeft(2, '0')}-${photoDate.day.toString().padLeft(2, '0')}',
    });
    final res = await _dio.post('progress-photos', data: formData);
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<void> deletePhoto(String id) async {
    await _dio.delete('progress-photos/$id');
  }
}
