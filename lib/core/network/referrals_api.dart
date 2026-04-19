import 'package:dio/dio.dart';
import 'api_client.dart';

class ReferralsApi {
  static final Dio _dio = ApiClient.instance;

  /// GET /api/referrals/me
  static Future<Map<String, dynamic>> getMyReferrals() async {
    final response = await _dio.get('referrals/me');
    return response.data as Map<String, dynamic>;
  }

  /// POST /api/referrals/withdraw
  static Future<Map<String, dynamic>> requestWithdrawal({
    required double amount,
    required String method,
  }) async {
    final response = await _dio.post(
      'referrals/withdraw',
      data: {'amount': amount, 'method': method},
    );
    return response.data as Map<String, dynamic>;
  }
}
