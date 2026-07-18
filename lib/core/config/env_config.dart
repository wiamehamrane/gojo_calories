import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Resolves API base URL from `.env`.
///
/// Only change [APP_ENV]:
/// - `prod` → [API_URL_PROD]
/// - `dev`  → simulator / emulator / device URL (auto or [DEV_API_TARGET])
class EnvConfig {
  static const _defaultProd = 'https://api.gojocalories.com/api/';
  static const _defaultDevSimulator = 'http://127.0.0.1:8000/api/';
  static const _defaultDevEmulator = 'http://10.0.2.2:8000/api/';
  static const _defaultDevDevice = 'http://127.0.0.1:8000/api/';

  /// `simulator` | `emulator` | `device` | `unknown`
  static String _runtimeTarget = 'unknown';

  static String get appEnv {
    final raw = (dotenv.env['APP_ENV'] ?? 'prod').trim().toLowerCase();
    if (raw == 'dev' || raw == 'development' || raw == 'local') return 'dev';
    return 'prod';
  }

  static bool get isDev => appEnv == 'dev';
  static bool get isProd => !isDev;

  static String get runtimeTarget => _runtimeTarget;

  static String get apiBaseUrl => _normalize(_resolveRawApiUrl());

  static String get apiOrigin =>
      apiBaseUrl.replaceAll(RegExp(r'/api/?$'), '');

  /// Call once after dotenv.load so auto-detect is reliable on simulators.
  static Future<void> prepare() async {
    if (kIsWeb) {
      _runtimeTarget = 'unknown';
      return;
    }
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        _runtimeTarget = info.isPhysicalDevice ? 'device' : 'simulator';
        return;
      }
      if (Platform.isAndroid) {
        final info = await plugin.androidInfo;
        _runtimeTarget = info.isPhysicalDevice ? 'device' : 'emulator';
        return;
      }
    } catch (_) {
      // Fall through to platform heuristics below.
    }
    if (Platform.isIOS) {
      _runtimeTarget = 'simulator';
    } else if (Platform.isAndroid) {
      _runtimeTarget = 'emulator';
    } else {
      _runtimeTarget = 'simulator';
    }
  }

  static String resolveMediaUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return '$apiOrigin$url';
  }

  static String _resolveRawApiUrl() {
    if (isProd) {
      return _read('API_URL_PROD') ?? _defaultProd;
    }

    final forced =
        (dotenv.env['DEV_API_TARGET'] ?? 'auto').trim().toLowerCase();
    switch (forced) {
      case 'simulator':
      case 'sim':
        return _devSimulator();
      case 'emulator':
      case 'emu':
        return _devEmulator();
      case 'device':
      case 'phone':
        return _devDevice();
      default:
        return _autoDevUrl();
    }
  }

  static String _autoDevUrl() {
    switch (_runtimeTarget) {
      case 'simulator':
        return _devSimulator();
      case 'emulator':
        return _devEmulator();
      case 'device':
        return _devDevice();
      default:
        // Safe local default for Flutter desktop / unknown.
        if (Platform.isAndroid) return _devEmulator();
        return _devSimulator();
    }
  }

  static String _devSimulator() =>
      _read('API_URL_DEV_SIMULATOR') ?? _defaultDevSimulator;

  static String _devEmulator() =>
      _read('API_URL_DEV_EMULATOR') ?? _defaultDevEmulator;

  static String _devDevice() =>
      _read('API_URL_DEV_DEVICE') ?? _defaultDevDevice;

  static String? _read(String key) {
    final value = dotenv.env[key]?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  static String _normalize(String raw) {
    final trimmed = raw.trim();
    if (trimmed.endsWith('/api/')) return trimmed;
    if (trimmed.endsWith('/api')) return '$trimmed/';
    final origin = trimmed.replaceAll(RegExp(r'/+$'), '');
    return '$origin/api/';
  }

  static const String _defaultGoogleWebClientId =
      '980076580409-rgqujk89m5lhvsr3nfg24hhodk08uoeh.apps.googleusercontent.com';

  static const String _defaultGoogleIosClientId =
      '980076580409-4d78u72lc8o7aqfuoinvd72dk2tr27co.apps.googleusercontent.com';

  static String get googleWebClientId =>
      dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? _defaultGoogleWebClientId;

  static String get googleIosClientId =>
      dotenv.env['GOOGLE_IOS_CLIENT_ID'] ?? _defaultGoogleIosClientId;

  static String? get googleAndroidClientId =>
      dotenv.env['GOOGLE_ANDROID_CLIENT_ID'];
}
