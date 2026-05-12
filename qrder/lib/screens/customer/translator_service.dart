import 'dart:convert';

import 'package:http/http.dart' as http;

class TranslatorService {
  static const String _baseUrl = 'https://api.mymemory.translated.net/get';

  static const Map<String, String> supportedLanguages = {
    'original': 'Original',
    'de': 'Deutsch',
    'en': 'English',
    'ar': 'العربية',
    'tr': 'Türkçe',
    'fr': 'Français',
    'es': 'Español',
    'it': 'Italiano',
    'ru': 'Русский',
  };

  static Future<String> translate({
    required String text,
    required String targetLang,
    String sourceLang = 'de',
  }) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty || targetLang == 'original') {
      return text;
    }

    if (sourceLang == targetLang) {
      return text;
    }

    final safeSourceLang = _normalizeLang(sourceLang);
    final safeTargetLang = _normalizeLang(targetLang);

    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'q': cleanText,
        'langpair': '$safeSourceLang|$safeTargetLang',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Translation failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final responseStatus = data['responseStatus'];
    if (responseStatus != null && responseStatus != 200) {
      throw Exception(data['responseDetails']?.toString() ?? 'Translation failed');
    }

    final translatedText =
    data['responseData']?['translatedText']?.toString();

    if (translatedText == null || translatedText.trim().isEmpty) {
      return text;
    }

    return translatedText;
  }

  static String _normalizeLang(String lang) {
    final clean = lang.trim().toLowerCase();

    if (clean == 'original') return 'de';
    if (clean == 'auto') return 'de';

    return clean;
  }

  static bool isRtl(String langCode) {
    return langCode == 'ar';
  }
}