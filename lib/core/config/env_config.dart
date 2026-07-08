import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get apiBaseUrl {
    final raw =
        dotenv.env['API_URL'] ?? 'https://api.gojocalories.com/api/';
    final trimmed = raw.trim();
    if (trimmed.endsWith('/api/')) return trimmed;
    if (trimmed.endsWith('/api')) return '$trimmed/';
    final origin = trimmed.replaceAll(RegExp(r'/+$'), '');
    return '$origin/api/';
  }

  /// Origin without `/api/` suffix — used for relative image paths from the API.
  static String get apiOrigin =>
      apiBaseUrl.replaceAll(RegExp(r'/api/?$'), '');

  static String resolveMediaUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '$apiOrigin$url';
  }

  static const String _defaultGoogleWebClientId =
      '980076580409-rgqujk89m5lhvsr3nfg24hhodk08uoeh.apps.googleusercontent.com';

  static const String _defaultGoogleIosClientId =
      '980076580409-4d78u72lc8o7aqfuoinvd72dk2tr27co.apps.googleusercontent.com';

  static String get googleWebClientId =>
      dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? _defaultGoogleWebClientId;

  static String get googleIosClientId =>
      dotenv.env['GOOGLE_IOS_CLIENT_ID'] ?? _defaultGoogleIosClientId;

  /// Optional override. Android OAuth clients are usually resolved from
  /// package name + signing SHA-1 when omitted.
  static String? get googleAndroidClientId =>
      dotenv.env['GOOGLE_ANDROID_CLIENT_ID'];
}
