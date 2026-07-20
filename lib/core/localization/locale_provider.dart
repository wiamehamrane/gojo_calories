import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLocaleKey = 'app_locale';

class LocaleNotifier extends Notifier<String> {
  @override
  String build() => 'en';

  /// Load saved locale on startup. Call from main() before runApp.
  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLocaleKey);
    if (saved != null) state = saved;
  }

  Future<void> setLocale(String locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, locale);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, String>(
  LocaleNotifier.new,
);

/// A helper to get the Flutter Locale object from a locale code string.
Locale toFlutterLocale(String code) {
  switch (code) {
    case 'fr':
      return const Locale('fr');
    case 'ar':
      return const Locale('ar');
    case 'es':
      return const Locale('es');
    case 'nl':
      return const Locale('nl');
    case 'pt':
      return const Locale('pt');
    case 'zh':
      return const Locale('zh');
    case 'ru':
      return const Locale('ru');
    case 'de':
      return const Locale('de');
    case 'ja':
      return const Locale('ja');
    case 'ko':
      return const Locale('ko');
    default:
      return const Locale('en');
  }
}

/// Intl / DateFormat locale string for the app language code.
String toIntlLocale(String code) {
  switch (code) {
    case 'fr':
      return 'fr_FR';
    case 'ar':
      return 'ar';
    case 'es':
      return 'es_ES';
    case 'nl':
      return 'nl_NL';
    case 'pt':
      return 'pt_BR';
    case 'zh':
      return 'zh_CN';
    case 'ru':
      return 'ru_RU';
    case 'de':
      return 'de_DE';
    case 'ja':
      return 'ja_JP';
    case 'ko':
      return 'ko_KR';
    default:
      return 'en_US';
  }
}
