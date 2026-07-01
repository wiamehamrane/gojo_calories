import '../../../../core/network/api_client.dart';

class ReferralsRepository {
  final _dio = ApiClient.instance;

  Future<Map<String, dynamic>> getMyReferrals() async {
    final res = await _dio.get('referrals/me');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> requestWithdrawal({
    required double amount,
    required String method,
  }) async {
    final res = await _dio.post(
      'referrals/withdraw',
      data: {'amount': amount, 'method': method},
    );
    return res.data as Map<String, dynamic>;
  }
}
