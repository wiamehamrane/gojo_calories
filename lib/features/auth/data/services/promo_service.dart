import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class PromoService {
  final Dio _dio = ApiClient.instance;

  Future<Map<String, dynamic>> resolve(String code) async {
    final res = await _dio.post(
      'payments/resolve-promo',
      data: {'code': code.trim()},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> redeem(String code) async {
    final res = await _dio.post(
      'payments/redeem-promo',
      data: {'code': code.trim()},
    );
    return Map<String, dynamic>.from(res.data as Map);
  }
}
