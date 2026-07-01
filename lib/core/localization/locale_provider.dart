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
    default:
      return const Locale('en');
  }
}
