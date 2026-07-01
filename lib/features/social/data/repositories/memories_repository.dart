import 'dart:io';

import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class MemoriesRepository {
  final Dio _dio = ApiClient.instance;

  Future<List<dynamic>> getMemories() async {
    final res = await _dio.get('memories');
    return res.data as List<dynamic>;
  }

  Future<void> uploadMemory(
    File imageFile, {
    String? caption,
    bool isPrivate = true,
  }) async {
    final fileName = imageFile.path.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imageFile.path, filename: fileName),
      'caption': caption,
      'is_private': isPrivate,
    }..removeWhere((_, v) => v == null));

    await _dio.post('memories', data: formData);
  }

  Future<void> deleteMemory(String id) async {
    await _dio.delete('memories/$id');
  }
}
