/// WhatsApp group invite link validation for events.
class EventWhatsAppLink {
  EventWhatsAppLink._();

  static final _groupLinkPattern = RegExp(
    r'^https?://chat\.whatsapp\.com/[A-Za-z0-9_-]+(\?[^\s#]*)?$',
    caseSensitive: false,
  );

  /// Cleans pasted links (trim, strip bidi marks, ensure https).
  static String normalize(String link) {
    var value = link.trim();
    value = value.replaceAll(
      RegExp(r'[\u200E\u200F\u202A-\u202E\u2066-\u2069\uFEFF]'),
      '',
    );
    if (value.isEmpty) return value;
    if (!value.toLowerCase().startsWith('http')) {
      value = 'https://$value';
    }
    return value;
  }

  static bool isValid(String link) {
    final normalized = normalize(link);
    if (normalized.isEmpty) return false;
    return _groupLinkPattern.hasMatch(normalized);
  }

  static const String hint = 'https://chat.whatsapp.com/…';

  static const String errorMessage =
      'Use a WhatsApp group invite link (chat.whatsapp.com)';
}
