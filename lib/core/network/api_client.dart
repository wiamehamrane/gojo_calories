import 'package:dio/dio.dart';
import '../config/env_config.dart';
import '../storage/token_storage.dart';

class ApiClient {
  static final Dio _dio = _createDio();

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await TokenStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response != null) {
            final status = error.response!.statusCode;
            final path = error.requestOptions.path;
            final isProfileMe =
                path == 'auth/me' || path.endsWith('/auth/me');
            if (status == 401 || (status == 404 && isProfileMe)) {
              await TokenStorage.clearSession();
            }
          }
          handler.next(error);
        },
      ),
    );

    return dio;
  }

  static Dio get instance => _dio;
}
