import 'dart:io';

import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class FeedRepository {
  final Dio _dio = ApiClient.instance;

  Future<List<dynamic>> getFeed() async {
    final res = await _dio.get('feed');
    return res.data as List<dynamic>;
  }

  Future<void> toggleLike(String postId) async {
    await _dio.post('feed/posts/$postId/like');
  }

  Future<Map<String, dynamic>> createPost({
    String? content,
    File? imageFile,
  }) async {
    final formData = FormData.fromMap({
      'content': content,
      if (imageFile != null)
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
    }..removeWhere((_, v) => v == null));

    final res = await _dio.post('feed/posts', data: formData);
    return res.data as Map<String, dynamic>;
  }
}
