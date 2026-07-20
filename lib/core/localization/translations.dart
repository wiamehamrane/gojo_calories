// ignore_for_file: prefer_single_quotes
import 'locales/ar.dart' as ar_locale;
import 'locales/de.dart' as de_locale;
import 'locales/en.dart' as en_locale;
import 'locales/es.dart' as es_locale;
import 'locales/fr.dart' as fr_locale;
import 'locales/ja.dart' as ja_locale;
import 'locales/ko.dart' as ko_locale;
import 'locales/nl.dart' as nl_locale;
import 'locales/pt.dart' as pt_locale;
import 'locales/ru.dart' as ru_locale;
import 'locales/zh.dart' as zh_locale;

class Translations {
  static final Map<String, Map<String, String>> _t = {
    'en': en_locale.en,
    'fr': fr_locale.fr,
    'ar': ar_locale.ar,
    'es': es_locale.es,
    'nl': nl_locale.nl,
    'pt': pt_locale.pt,
    'zh': zh_locale.zh,
    'ru': ru_locale.ru,
    'de': de_locale.de,
    'ja': ja_locale.ja,
    'ko': ko_locale.ko,
  };

  static const supportedCodes = [
    'en',
    'fr',
    'ar',
    'es',
    'nl',
    'pt',
    'zh',
    'ru',
    'de',
    'ja',
    'ko',
  ];

  /// Get a translated string. Falls back to English if key not found.
  static String t(String locale, String key) {
    final lang = (locale == 'Darija') ? 'ar' : locale;
    return _t[lang]?[key] ?? _t['en']?[key] ?? key;
  }

  static bool isRtl(String locale) => locale == 'ar' || locale == 'Darija';
}
