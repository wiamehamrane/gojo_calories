import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get apiBaseUrl =>
      dotenv.env['API_URL'] ?? 'https://api.gojocalories.com/api/';

  /// Origin without `/api/` suffix — used for relative image paths from the API.
  static String get apiOrigin =>
      apiBaseUrl.replaceAll(RegExp(r'/api/?$'), '');

  static String resolveMediaUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '$apiOrigin$url';
  }
}
