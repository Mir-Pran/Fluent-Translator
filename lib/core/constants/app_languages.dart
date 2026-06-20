/// Supported translation languages.
///
/// Each [AppLanguage] carries the ISO 639-1 code used by the MyMemory API,
/// a human-readable English name, the native script name, an emoji flag, and
/// the BCP-47 locale used for TTS.
library;

class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
    required this.ttsLocale,
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AppLanguage && code == other.code);

  @override
  int get hashCode => code.hashCode;
}

/// All supported languages, ordered by global speaker count.
class AppLanguages {
  AppLanguages._();

  static const english = AppLanguage(
    code: 'en', name: 'English', nativeName: 'English',
    flag: '🇬🇧', ttsLocale: 'en-US',
  );
  static const bengali = AppLanguage(
    code: 'bn', name: 'Bengali', nativeName: 'বাংলা',
    flag: '🇧🇩', ttsLocale: 'bn-BD',
  );
  static const mandarin = AppLanguage(
    code: 'zh-CN', name: 'Chinese', nativeName: '中文',
    flag: '🇨🇳', ttsLocale: 'zh-CN',
  );
  static const hindi = AppLanguage(
    code: 'hi', name: 'Hindi', nativeName: 'हिन्दी',
    flag: '🇮🇳', ttsLocale: 'hi-IN',
  );
  static const spanish = AppLanguage(
    code: 'es', name: 'Spanish', nativeName: 'Español',
    flag: '🇪🇸', ttsLocale: 'es-ES',
  );
  static const french = AppLanguage(
    code: 'fr', name: 'French', nativeName: 'Français',
    flag: '🇫🇷', ttsLocale: 'fr-FR',
  );
  static const arabic = AppLanguage(
    code: 'ar', name: 'Arabic', nativeName: 'العربية',
    flag: '🇸🇦', ttsLocale: 'ar-SA',
  );
  static const russian = AppLanguage(
    code: 'ru', name: 'Russian', nativeName: 'Русский',
    flag: '🇷🇺', ttsLocale: 'ru-RU',
  );
  static const portuguese = AppLanguage(
    code: 'pt', name: 'Portuguese', nativeName: 'Português',
    flag: '🇧🇷', ttsLocale: 'pt-BR',
  );
  static const urdu = AppLanguage(
    code: 'ur', name: 'Urdu', nativeName: 'اردو',
    flag: '🇵🇰', ttsLocale: 'ur-PK',
  );
  static const indonesian = AppLanguage(
    code: 'id', name: 'Indonesian', nativeName: 'Bahasa Indonesia',
    flag: '🇮🇩', ttsLocale: 'id-ID',
  );
  static const german = AppLanguage(
    code: 'de', name: 'German', nativeName: 'Deutsch',
    flag: '🇩🇪', ttsLocale: 'de-DE',
  );
  static const japanese = AppLanguage(
    code: 'ja', name: 'Japanese', nativeName: '日本語',
    flag: '🇯🇵', ttsLocale: 'ja-JP',
  );
  static const turkish = AppLanguage(
    code: 'tr', name: 'Turkish', nativeName: 'Türkçe',
    flag: '🇹🇷', ttsLocale: 'tr-TR',
  );
  static const korean = AppLanguage(
    code: 'ko', name: 'Korean', nativeName: '한국어',
    flag: '🇰🇷', ttsLocale: 'ko-KR',
  );
  static const italian = AppLanguage(
    code: 'it', name: 'Italian', nativeName: 'Italiano',
    flag: '🇮🇹', ttsLocale: 'it-IT',
  );

  static const List<AppLanguage> all = [
    english, bengali, mandarin, hindi, spanish, french,
    arabic, russian, portuguese, urdu, indonesian, german,
    japanese, turkish, korean, italian,
  ];

  /// Returns the [AppLanguage] matching [code], or null if not found.
  static AppLanguage? findByCode(String code) {
    for (final lang in all) {
      if (lang.code == code) return lang;
    }
    return null;
  }
}
