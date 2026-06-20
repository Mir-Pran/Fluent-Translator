/// Translation service using ML Kit on-device (primary offline) +
/// MyMemory API + Google Translate unofficial endpoint.
///
/// Offline mode: ML Kit is tried first; downloads models on first use.
/// Online mode (default): MyMemory → Google → ML Kit fallback.
///
/// All 20 languages in AppLanguages.all that have mlkitCode are fully
/// supported offline via Google ML Kit on-device translation.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/app_languages.dart';
import '../../data/models/translation_record.dart';

class TranslationService {
  TranslationService();

  final _languageId = LanguageIdentifier(confidenceThreshold: 0.4);
  final Map<String, OnDeviceTranslator> _translators = {};
  final Set<String> _readyPairs = {};
  final _httpClient = http.Client();

  // Cached model manager — re-use instead of constructing on every call.
  static final _modelManager = OnDeviceTranslatorModelManager();

  // ──────────────────────────────────────────────────────────────────────────
  // ML Kit language mapping — ISO code → TranslateLanguage
  // ──────────────────────────────────────────────────────────────────────────

  static final Map<String, TranslateLanguage> _mlkitMap = {
    'af': TranslateLanguage.afrikaans,
    'ar': TranslateLanguage.arabic,
    'be': TranslateLanguage.belarusian,
    'bg': TranslateLanguage.bulgarian,
    'bn': TranslateLanguage.bengali,
    'ca': TranslateLanguage.catalan,
    'cs': TranslateLanguage.czech,
    'cy': TranslateLanguage.welsh,
    'da': TranslateLanguage.danish,
    'de': TranslateLanguage.german,
    'el': TranslateLanguage.greek,
    'en': TranslateLanguage.english,
    'eo': TranslateLanguage.esperanto,
    'es': TranslateLanguage.spanish,
    'et': TranslateLanguage.estonian,
    'fa': TranslateLanguage.persian,
    'fi': TranslateLanguage.finnish,
    'fr': TranslateLanguage.french,
    'ga': TranslateLanguage.irish,
    'gl': TranslateLanguage.galician,
    'gu': TranslateLanguage.gujarati,
    'he': TranslateLanguage.hebrew,
    'hi': TranslateLanguage.hindi,
    'hr': TranslateLanguage.croatian,
    'ht': TranslateLanguage.haitian,
    'hu': TranslateLanguage.hungarian,
    'id': TranslateLanguage.indonesian,
    'is': TranslateLanguage.icelandic,
    'it': TranslateLanguage.italian,
    'ja': TranslateLanguage.japanese,
    'ka': TranslateLanguage.georgian,
    'kn': TranslateLanguage.kannada,
    'ko': TranslateLanguage.korean,
    'lt': TranslateLanguage.lithuanian,
    'lv': TranslateLanguage.latvian,
    'mk': TranslateLanguage.macedonian,
    'mr': TranslateLanguage.marathi,
    'ms': TranslateLanguage.malay,
    'mt': TranslateLanguage.maltese,
    'nl': TranslateLanguage.dutch,
    'no': TranslateLanguage.norwegian,
    'pl': TranslateLanguage.polish,
    'pt': TranslateLanguage.portuguese,
    'ro': TranslateLanguage.romanian,
    'ru': TranslateLanguage.russian,
    'sk': TranslateLanguage.slovak,
    'sl': TranslateLanguage.slovenian,
    'sq': TranslateLanguage.albanian,
    'sv': TranslateLanguage.swedish,
    'sw': TranslateLanguage.swahili,
    'ta': TranslateLanguage.tamil,
    'te': TranslateLanguage.telugu,
    'th': TranslateLanguage.thai,
    'tl': TranslateLanguage.tagalog,
    'tr': TranslateLanguage.turkish,
    'uk': TranslateLanguage.ukrainian,
    'ur': TranslateLanguage.urdu,
    'vi': TranslateLanguage.vietnamese,
    'zh': TranslateLanguage.chinese,
    'zh-CN': TranslateLanguage.chinese,
    'zh-TW': TranslateLanguage.chinese,
  };

  /// Look up TranslateLanguage for a given ISO code. Returns null if not
  /// supported by ML Kit.
  static TranslateLanguage? mlkitLanguage(String code) {
    return _mlkitMap[code] ?? _mlkitMap[code.split('-').first];
  }

  /// Whether both languages in [direction] are supported for offline use.
  static bool directionSupportsOffline(TranslationDirection direction) {
    return mlkitLanguage(direction.sourceLangCode) != null &&
        mlkitLanguage(direction.targetLangCode) != null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ensureModel: download models for the given direction.
  // In offlineFirst mode this awaits the download so translation can proceed.
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> ensureModel(
    TranslationDirection direction, {
    void Function(double progress)? onProgress,
    bool offlineFirst = false,
  }) async {
    if (!directionSupportsOffline(direction)) {
      onProgress?.call(1);
      return;
    }

    final pairKey = '${direction.sourceLangCode}|${direction.targetLangCode}';

    if (_readyPairs.contains(pairKey)) {
      onProgress?.call(1);
      return;
    }

    if (offlineFirst) {
      // Await the download so offline translation can work immediately.
      await _downloadModels(direction, onProgress: onProgress);
    } else {
      // Signal done immediately for online-first mode (download silently).
      onProgress?.call(1);
      unawaited(_downloadModels(direction));
    }
  }

  Future<void> _downloadModels(
    TranslationDirection direction, {
    void Function(double progress)? onProgress,
  }) async {
    final pairKey = '${direction.sourceLangCode}|${direction.targetLangCode}';
    if (_readyPairs.contains(pairKey)) {
      onProgress?.call(1);
      return;
    }

    final srcLang = mlkitLanguage(direction.sourceLangCode);
    final tgtLang = mlkitLanguage(direction.targetLangCode);
    if (srcLang == null || tgtLang == null) {
      onProgress?.call(1);
      return;
    }

    try {
      onProgress?.call(0.1);
      final srcModel = srcLang.bcpCode;
      final tgtModel = tgtLang.bcpCode;

      final srcOk = await _modelManager.downloadModel(srcModel, isWifiRequired: false);
      onProgress?.call(0.6);
      final tgtOk = await _modelManager.downloadModel(tgtModel, isWifiRequired: false);
      onProgress?.call(0.95);

      if (srcOk && tgtOk) {
        _readyPairs.add(pairKey);
        debugPrint('ML Kit models ready: $pairKey');
      } else {
        debugPrint('ML Kit model download partial: src=$srcOk tgt=$tgtOk');
      }
    } catch (e) {
      debugPrint('ML Kit model download error: $e');
    } finally {
      onProgress?.call(1);
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // isModelReady: check if a pair is already downloaded.
  // ──────────────────────────────────────────────────────────────────────────

  Future<bool> isModelReady(TranslationDirection direction) async {
    final pairKey = '${direction.sourceLangCode}|${direction.targetLangCode}';
    if (_readyPairs.contains(pairKey)) return true;

    final srcLang = mlkitLanguage(direction.sourceLangCode);
    final tgtLang = mlkitLanguage(direction.targetLangCode);
    if (srcLang == null || tgtLang == null) return false;

    try {
      final srcReady = await _modelManager.isModelDownloaded(srcLang.bcpCode);
      final tgtReady = await _modelManager.isModelDownloaded(tgtLang.bcpCode);
      if (srcReady && tgtReady) {
        _readyPairs.add(pairKey);
        return true;
      }
    } catch (_) {}
    return false;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // downloadModelForLanguage: public — called from settings screen.
  // ──────────────────────────────────────────────────────────────────────────

  Future<bool> downloadModelForLanguage(AppLanguage lang) async {
    final mlkit = mlkitLanguage(lang.code);
    if (mlkit == null) return false;
    try {
      return await _modelManager.downloadModel(mlkit.bcpCode, isWifiRequired: false);
    } catch (e) {
      debugPrint('downloadModelForLanguage error: $e');
      return false;
    }
  }

  Future<bool> isLanguageModelDownloaded(AppLanguage lang) async {
    final mlkit = mlkitLanguage(lang.code);
    if (mlkit == null) return false;
    try {
      return await _modelManager.isModelDownloaded(mlkit.bcpCode);
    } catch (_) {
      return false;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // translate: tries offline-first or online-first based on [offlineFirst].
  // ──────────────────────────────────────────────────────────────────────────

  Future<String> translate(
    String text,
    TranslationDirection direction, {
    bool offlineFirst = false,
  }) async {
    if (text.trim().isEmpty) return '';
    final from = direction.sourceLangCode;
    final to = direction.targetLangCode;

    if (offlineFirst) {
      // ── Offline-first order: ML Kit → MyMemory → Google ──
      final pairKey = '$from|$to';
      final ready = _readyPairs.contains(pairKey) || await isModelReady(direction);
      if (ready) {
        try {
          debugPrint('Offline-first: trying ML Kit...');
          final result = await _mlKitTranslate(text, direction);
          debugPrint('ML Kit success');
          return result;
        } catch (e) {
          debugPrint('ML Kit failed in offline mode: $e');
        }
      } else {
        debugPrint('Offline: models not ready, falling through to web APIs');
      }
      // Fallback to web APIs even in offline-first mode (user may have internet).
      try {
        return await _googleTranslate(text, from, to);
      } catch (_) {}
      try {
        return await _myMemory(text, from, to);
      } catch (_) {}
      throw Exception(
        'Offline translation not available. Please download the language model from Settings, or enable internet.',
      );
    }

    // ── Online-first: race Google + MyMemory in parallel, fastest wins ──
    // Both fire at once; we return the first that succeeds. Much faster than
    // sequential fallbacks, which had to fully wait for each source.
    final googleFuture = _googleTranslate(text, from, to).timeout(
      const Duration(seconds: 6),
      onTimeout: () => throw Exception('Google timeout'),
    );
    final myMemoryFuture = _myMemory(text, from, to).timeout(
      const Duration(seconds: 6),
      onTimeout: () => throw Exception('MyMemory timeout'),
    );

    bool gotResult = false;
    String? result;
    final errors = <Object>[];

    try {
      result = await Future.any([googleFuture, myMemoryFuture]);
      gotResult = true;
      debugPrint('Translation race: fastest source returned ${result?.length ?? 0} chars');
    } on Exception catch (e) {
      // Future.any throws when the first completes with an error. Continue to
      // await the other one.
      errors.add(e);
    }

    // If the race's first finisher errored, wait for the other.
    if (!gotResult) {
      for (final f in [googleFuture, myMemoryFuture]) {
        try {
          result = await f;
          gotResult = true;
          break;
        } catch (e) {
          errors.add(e);
        }
      }
    }

    if (gotResult && result != null && result.isNotEmpty) {
      return result;
    }

    // Last resort: ML Kit on-device (works if models were previously downloaded).
    final pairKey = '$from|$to';
    final ready = _readyPairs.contains(pairKey) || await isModelReady(direction);
    if (ready) {
      try {
        debugPrint('Falling back to ML Kit...');
        return await _mlKitTranslate(text, direction);
      } catch (e) {
        debugPrint('ML Kit fallback failed: $e');
      }
    }

    throw Exception(
      'Translation failed. Please check your internet connection or download the offline model from Settings.',
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // ML Kit translation helper — supports all mapped languages.
  // ──────────────────────────────────────────────────────────────────────────

  Future<String> _mlKitTranslate(String text, TranslationDirection direction) async {
    final srcLang = mlkitLanguage(direction.sourceLangCode);
    final tgtLang = mlkitLanguage(direction.targetLangCode);
    if (srcLang == null || tgtLang == null) {
      throw Exception('Language pair not supported offline: ${direction.sourceLangCode}→${direction.targetLangCode}');
    }
    final translator = _mlTranslator(srcLang, tgtLang, direction);
    return translator.translateText(text);
  }

  OnDeviceTranslator _mlTranslator(
    TranslateLanguage src,
    TranslateLanguage tgt,
    TranslationDirection direction,
  ) {
    final key = '${direction.sourceLangCode}|${direction.targetLangCode}';
    return _translators.putIfAbsent(
      key,
      () => OnDeviceTranslator(sourceLanguage: src, targetLanguage: tgt),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // MyMemory API — https://mymemory.translated.net
  // Free, no key, 1000 words/day per IP.
  // ──────────────────────────────────────────────────────────────────────────

  Future<String> _myMemory(String text, String from, String to) async {
    final uri = Uri.parse(
      'https://api.mymemory.translated.net/get'
      '?q=${Uri.encodeComponent(text)}'
      '&langpair=$from|$to',
    );

    final response = await _httpClient
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // responseStatus 200 means a real translation was found.
      final responseStatus = data['responseStatus'] as int? ?? 0;
      final translated =
          (data['responseData'] as Map<String, dynamic>?)?['translatedText']
              as String?;

      final isQuotaWarning = translated?.contains('MYMEMORY WARNING') ?? false;

      if (responseStatus == 200 &&
          translated != null &&
          translated.isNotEmpty &&
          !isQuotaWarning &&
          translated.toLowerCase() != text.toLowerCase()) {
        return translated;
      }

      // Fallback: try matches array (often available even when quota exceeded).
      // IMPORTANT: each match has a "segment" field = the source text it
      // translates. Crowd-sourced memory can contain totally unrelated entries
      // (e.g. song lyrics), so we must verify the segment matches our input —
      // otherwise we return garbage for short/common words like "hello".
      final matches = data['matches'] as List?;
      if (matches != null) {
        final normalizedInput = text.trim().toLowerCase();
        for (final m in matches) {
          final matchMap = m as Map?;
          final matchText = matchMap?['translation'] as String?;
          final segment = matchMap?['segment'] as String?;
          // quality ≥ 74 = human translation.
          final quality = int.tryParse(
              matchMap?['quality']?.toString() ?? '0') ?? 0;
          if (matchText != null &&
              matchText.isNotEmpty &&
              quality >= 74 &&
              segment != null &&
              segment.trim().toLowerCase() == normalizedInput &&
              matchText.toLowerCase() != text.toLowerCase()) {
            return matchText;
          }
        }
      }
    }
    throw Exception('MyMemory returned ${response.statusCode}');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Google Translate unofficial endpoint.
  // ──────────────────────────────────────────────────────────────────────────

  Future<String> _googleTranslate(String text, String from, String to) async {
    // Try two different client IDs — 'gtx' is the most reliable but 'dict'
    // occasionally works when 'gtx' is throttled.
    for (final client in ['gtx', 'dict']) {
      try {
        final result = await _googleTranslateWithClient(text, from, to, client);
        // Sanity-check: result must not be empty. We accept same-as-source
        // because loanwords (e.g. "hello" bn→en) and short phrases often
        // don't change across languages — rejecting them would fall through
        // to MyMemory garbage matches.
        if (result.isNotEmpty) {
          return result;
        }
      } catch (e) {
        debugPrint('Google Translate ($client) error: $e');
      }
    }
    throw Exception('Google Translate unavailable');
  }

  Future<String> _googleTranslateWithClient(
    String text, String from, String to, String client) async {
    final uri = Uri.https(
      'translate.googleapis.com',
      '/translate_a/single',
      {'client': client, 'sl': from, 'tl': to, 'dt': 't', 'q': text},
    );

    final response = await _httpClient.get(uri, headers: {
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List && decoded.isNotEmpty && decoded[0] is List) {
        final sb = StringBuffer();
        for (final item in decoded[0] as List) {
          if (item is List && item.isNotEmpty && item[0] is String) {
            sb.write(item[0]);
          }
        }
        final result = sb.toString().trim();
        if (result.isNotEmpty) return result;
      }
    }
    throw Exception('Google Translate returned ${response.statusCode}');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Language detection.
  // ──────────────────────────────────────────────────────────────────────────

  Future<String?> detectLanguage(String text) async {
    if (text.trim().isEmpty) return null;
    try {
      return await _languageId.identifyLanguage(text);
    } catch (_) {
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Dispose.
  // ──────────────────────────────────────────────────────────────────────────

  void dispose() {
    for (final t in _translators.values) { t.close(); }
    _translators.clear();
    _languageId.close();
    _httpClient.close();
  }
}
