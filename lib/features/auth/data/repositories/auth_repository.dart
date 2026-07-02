import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/token_storage.dart';

class AuthRepository {
  final Dio _dio = ApiClient.instance;

  Future<Map<String, dynamic>> getMe() async {
    final res = await _dio.get('auth/me');
    return res.data as Map<String, dynamic>;
  }

  Future<String> login({required String email, required String password}) async {
    final res = await _dio.post(
      'auth/login',
      data: {'email': email, 'password': password},
    );
    return res.data['access_token'] as String;
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? name,
    String? referralCode,
  }) async {
    final res = await _dio.post(
      'auth/register',
      data: {
        'email': email,
        'password': password,
        'name': ?name,
        'referral_code': ?referralCode,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<String> googleLogin(String idToken) async {
    final res = await _dio.post('auth/google', data: {'id_token': idToken});
    return res.data['access_token'] as String;
  }

  Future<String> appleLogin({
    required String identityToken,
    String? givenName,
    String? familyName,
  }) async {
    final res = await _dio.post(
      'auth/apple',
      data: {
        'identity_token': identityToken,
        'given_name': ?givenName,
        'family_name': ?familyName,
      },
    );
    return res.data['access_token'] as String;
  }

  Future<String> verifyOtp({required String email, required String otp}) async {
    final res = await _dio.post(
      'auth/verify-otp',
      data: {'email': email, 'otp': otp},
    );
    return res.data['access_token'] as String;
  }

  Future<void> resendVerification({String? email}) async {
    await _dio.post(
      'auth/resend-verification',
      data: email != null ? {'email': email} : {},
    );
  }

  Future<Map<String, dynamic>> updateWeight(Map<String, dynamic> data) async {
    final res = await _dio.put('auth/me/weight', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteAccount() async {
    await _dio.delete('auth/me');
    await TokenStorage.clearSession();
  }

  Future<void> saveToken(String token) => TokenStorage.saveAccessToken(token);

  Future<void> clearSession() => TokenStorage.clearSession();

  Future<bool> hasStoredToken() async {
    final token = await TokenStorage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<bool> isOnboarded() => TokenStorage.isOnboarded();

  Future<void> setOnboarded(bool value) => TokenStorage.setOnboarded(value);
}
/*return here --*/