import '../../../../core/network/api_client.dart';

class ProfileRepository {
  final _dio = ApiClient.instance;

  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('auth/me');
    return res.data as Map<String, dynamic>;
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
