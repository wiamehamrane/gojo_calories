// ignore_for_file: prefer_single_quotes
import 'locales/ar.dart' as ar_locale;
import 'locales/en.dart' as en_locale;
import 'locales/es.dart' as es_locale;
import 'locales/fr.dart' as fr_locale;
import 'locales/nl.dart' as nl_locale;
import 'locales/pt.dart' as pt_locale;

class Translations {
  static final Map<String, Map<String, String>> _t = {
    'en': en_locale.en,
    'fr': fr_locale.fr,
    'ar': ar_locale.ar,
    'es': es_locale.es,
    'nl': nl_locale.nl,
    'pt': pt_locale.pt,
  };

  /// Get a translated string. Falls back to English if key not found.
  static String t(String locale, String key) {
    final lang = (locale == 'Darija') ? 'ar' : locale;
    return _t[lang]?[key] ?? _t['en']?[key] ?? key;
  }

  static bool isRtl(String locale) => locale == 'ar' || locale == 'Darija';
}
