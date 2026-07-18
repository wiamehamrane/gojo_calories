import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';

class ProfileRepository {
  final _dio = ApiClient.instance;

  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('auth/me');
    return res.data as Map<String, dynamic>;
  }

  Future<String?> uploadAvatar(File imageFile) async {
    final fileName = imageFile.path.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imageFile.path, filename: fileName),
    });
    final res = await _dio.post('auth/me/avatar', data: formData);
    final data = res.data as Map<String, dynamic>?;
    return data?['avatar_url'] as String?;
  }

  Future<void> deleteAvatar() async {
    await _dio.delete('auth/me/avatar');
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _dio.put('auth/me/profile', data: data);
  }

  Future<void> updatePersonalDetails(Map<String, dynamic> data) async {
    await _dio.put('auth/me/profile', data: data);
  }

  Future<void> updateWeight(Map<String, dynamic> data) async {
    await _dio.put('auth/me/weight', data: data);
  }

  Future<void> updateNutritionGoals(Map<String, dynamic> data) async {
    await _dio.put('auth/me/profile', data: data);
  }

  Future<void> resendVerification({String? email}) async {
    await _dio.post(
      'auth/resend-verification',
      data: email != null ? {'email': email} : {},
    );
  }

  Future<void> deleteAccount() async {
    await _dio.delete('auth/me');
  }
}
