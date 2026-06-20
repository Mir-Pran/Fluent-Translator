/// Supported translation languages.
///
/// Each [AppLanguage] carries the ISO 639-1 code used by the MyMemory API,
/// a human-readable English name, the native script name, an emoji flag,
/// the BCP-47 locale used for TTS, and the ML Kit language tag used for
/// on-device translation (null if the language is not supported by ML Kit).
library;

class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.ttsLocale,
    this.mlkitCode,
  });

  /// ISO 639-1 code used by the translation APIs (e.g. 'en', 'fr', 'zh-CN').
  final String code;

  /// English display name.
  final String name;

  /// Name in the language itself.
  final String nativeName;

  /// Emoji flag for the primary country that uses this language.
  final String flag;

  /// BCP-47 locale for flutter_tts (e.g. 'en-US', 'fr-FR').
  final String ttsLocale;

  /// ML Kit language tag (e.g. 'en', 'fr', 'zh'). Null = not supported offline.
  /// Used with TranslateLanguage.fromRawValue(mlkitCode!).
  final String? mlkitCode;

  /// Whether this language can be translated offline via ML Kit.
  bool get supportsOffline => mlkitCode != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AppLanguage && code == other.code);

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'AppLanguage($code, $name)';
}

/// All supported languages, ordered by global speaker count.
class AppLanguages {
  AppLanguages._();

  static const english = AppLanguage(
    code: 'en', name: 'English', nativeName: 'English',
    flag: '🇬🇧', ttsLocale: 'en-US', mlkitCode: 'en',
  );
  static const bengali = AppLanguage(
    code: 'bn', name: 'Bengali', nativeName: 'বাংলা',
    flag: '🇧🇩', ttsLocale: 'bn-BD', mlkitCode: 'bn',
  );
  static const mandarin = AppLanguage(
    code: 'zh-CN', name: 'Chinese', nativeName: '中文',
    flag: '🇨🇳', ttsLocale: 'zh-CN', mlkitCode: 'zh',
  );
  static const hindi = AppLanguage(
    code: 'hi', name: 'Hindi', nativeName: 'हिन्दी',
    flag: '🇮🇳', ttsLocale: 'hi-IN', mlkitCode: 'hi',
  );
  static const spanish = AppLanguage(
    code: 'es', name: 'Spanish', nativeName: 'Español',
    flag: '🇪🇸', ttsLocale: 'es-ES', mlkitCode: 'es',
  );
  static const french = AppLanguage(
    code: 'fr', name: 'French', nativeName: 'Français',
    flag: '🇫🇷', ttsLocale: 'fr-FR', mlkitCode: 'fr',
  );
  static const arabic = AppLanguage(
    code: 'ar', name: 'Arabic', nativeName: 'العربية',
    flag: '🇸🇦', ttsLocale: 'ar-SA', mlkitCode: 'ar',
  );
  static const russian = AppLanguage(
    code: 'ru', name: 'Russian', nativeName: 'Русский',
    flag: '🇷🇺', ttsLocale: 'ru-RU', mlkitCode: 'ru',
  );
  static const portuguese = AppLanguage(
    code: 'pt', name: 'Portuguese', nativeName: 'Português',
    flag: '🇧🇷', ttsLocale: 'pt-BR', mlkitCode: 'pt',
  );
  static const urdu = AppLanguage(
    code: 'ur', name: 'Urdu', nativeName: 'اردو',
    flag: '🇵🇰', ttsLocale: 'ur-PK', mlkitCode: 'ur',
  );
  static const indonesian = AppLanguage(
    code: 'id', name: 'Indonesian', nativeName: 'Bahasa Indonesia',
    flag: '🇮🇩', ttsLocale: 'id-ID', mlkitCode: 'id',
  );
  static const german = AppLanguage(
    code: 'de', name: 'German', nativeName: 'Deutsch',
    flag: '🇩🇪', ttsLocale: 'de-DE', mlkitCode: 'de',
  );
  static const japanese = AppLanguage(
    code: 'ja', name: 'Japanese', nativeName: '日本語',
    flag: '🇯🇵', ttsLocale: 'ja-JP', mlkitCode: 'ja',
  );
  static const turkish = AppLanguage(
    code: 'tr', name: 'Turkish', nativeName: 'Türkçe',
    flag: '🇹🇷', ttsLocale: 'tr-TR', mlkitCode: 'tr',
  );
  static const korean = AppLanguage(
    code: 'ko', name: 'Korean', nativeName: '한국어',
    flag: '🇰🇷', ttsLocale: 'ko-KR', mlkitCode: 'ko',
  );
  static const italian = AppLanguage(
    code: 'it', name: 'Italian', nativeName: 'Italiano',
    flag: '🇮🇹', ttsLocale: 'it-IT', mlkitCode: 'it',
  );
  static const thai = AppLanguage(
    code: 'th', name: 'Thai', nativeName: 'ภาษาไทย',
    flag: '🇹🇭', ttsLocale: 'th-TH', mlkitCode: 'th',
  );
  static const vietnamese = AppLanguage(
    code: 'vi', name: 'Vietnamese', nativeName: 'Tiếng Việt',
    flag: '🇻🇳', ttsLocale: 'vi-VN', mlkitCode: 'vi',
  );
  static const polish = AppLanguage(
    code: 'pl', name: 'Polish', nativeName: 'Polski',
    flag: '🇵🇱', ttsLocale: 'pl-PL', mlkitCode: 'pl',
  );
  static const dutch = AppLanguage(
    code: 'nl', name: 'Dutch', nativeName: 'Nederlands',
    flag: '🇳🇱', ttsLocale: 'nl-NL', mlkitCode: 'nl',
  );

  static const List<AppLanguage> all = [
    english, bengali, mandarin, hindi, spanish, french,
    arabic, russian, portuguese, urdu, indonesian, german,
    japanese, turkish, korean, italian, thai, vietnamese,
    polish, dutch,
  ];

  /// Languages supported for offline (ML Kit) translation.
  static List<AppLanguage> get offlineSupported =>
      all.where((l) => l.supportsOffline).toList();

  /// Returns the [AppLanguage] matching [code], or null if not found.
  static AppLanguage? findByCode(String code) {
    for (final lang in all) {
      if (lang.code == code) return lang;
    }
    return null;
  }

  /// Fuzzy match: tries exact code, then prefix (e.g. 'zh' matches 'zh-CN').
  static AppLanguage? findByCodeFuzzy(String code) {
    final exact = findByCode(code);
    if (exact != null) return exact;
    final lower = code.toLowerCase();
    for (final lang in all) {
      if (lang.code.toLowerCase().startsWith(lower) ||
          lower.startsWith(lang.code.toLowerCase())) {
        return lang;
      }
    }
    return null;
  }
}
