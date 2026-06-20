/// Translation service using MyMemory API (primary) + Google Translate (secondary)
/// + ML Kit on-device (offline fallback).
///
/// MyMemory is a free public API that requires no API key and works reliably
/// on Android without any special configuration.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:http/http.dart' as http;

import '../../data/models/translation_record.dart';

class TranslationService {
  TranslationService();

  final _languageId = LanguageIdentifier(confidenceThreshold: 0.5);
  final Map<String, OnDeviceTranslator> _translators = {};
  final Set<String> _readyPairs = {};
  final _httpClient = http.Client();

  // ──────────────────────────────────────────────────────────────────────────
  // ensureModel: just download in the background silently, never blocks UI.
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> ensureModel(
    TranslationDirection direction, {
    void Function(double progress)? onProgress,
  }) async {
    // Signal done immediately — web API works without models.
    onProgress?.call(1);
    // Download models silently in background for future offline use.
    unawaited(_silentDownload(direction));
  }

  Future<void> _silentDownload(TranslationDirection direction) async {
    final pairKey = '${direction.sourceLangCode}|${direction.targetLangCode}';
    if (_readyPairs.contains(pairKey)) return;
    try {
      final manager = OnDeviceTranslatorModelManager();
      final srcOk = await manager.downloadModel(
        direction.sourceLangCode, isWifiRequired: false,
      );
      final tgtOk = await manager.downloadModel(
        direction.targetLangCode, isWifiRequired: false,
      );
      if (srcOk && tgtOk) _readyPairs.add(pairKey);
    } catch (_) {}
  }

  // ──────────────────────────────────────────────────────────────────────────
  // translate: tries 3 APIs in order.
  // ──────────────────────────────────────────────────────────────────────────

  Future<String> translate(
    String text,
    TranslationDirection direction,
  ) async {
    if (text.trim().isEmpty) return '';
    final from = direction.sourceLangCode;
    final to = direction.targetLangCode;

    // 1️⃣ MyMemory — free, no key, very reliable.
    try {
      debugPrint('Trying MyMemory API...');
      final result = await _myMemory(text, from, to);
      debugPrint('MyMemory success: $result');
      return result;
    } catch (e) {
      debugPrint('MyMemory failed: $e');
    }

    // 2️⃣ Google Translate unofficial endpoint.
    try {
      debugPrint('Trying Google Translate API...');
      final result = await _googleTranslate(text, from, to);
      debugPrint('Google Translate success: $result');
      return result;
    } catch (e) {
      debugPrint('Google Translate failed: $e');
    }

    // 3️⃣ ML Kit on-device (works if model was previously downloaded).
    final pairKey = '$from|$to';
    if (_readyPairs.contains(pairKey)) {
      try {
        debugPrint('Trying ML Kit...');
        final translator = _mlTranslator(direction);
        return await translator.translateText(text);
      } catch (e) {
        debugPrint('ML Kit failed: $e');
      }
    }

    throw Exception(
      'Translation failed. Please check your internet connection.',
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
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final translated =
          (data['responseData'] as Map<String, dynamic>?)?['translatedText']
              as String?;
      if (translated != null &&
          translated.isNotEmpty &&
          translated != 'MYMEMORY WARNING: YOU USED ALL AVAILABLE FREE TRANSLATIONS FOR TODAY.') {
        return translated;
      }
      // Quota exceeded — try matches array
      final matches = data['matches'] as List?;
      if (matches != null && matches.isNotEmpty) {
        final firstMatch = matches[0] as Map?;
        final first = firstMatch?['translation'] as String?;
        if (first != null && first.isNotEmpty) return first;
      }
    }
    throw Exception('MyMemory returned ${response.statusCode}');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Google Translate unofficial endpoint.
  // ──────────────────────────────────────────────────────────────────────────

  Future<String> _googleTranslate(String text, String from, String to) async {
    final uri = Uri.https(
      'translate.googleapis.com',
      '/translate_a/single',
      {'client': 'gtx', 'sl': from, 'tl': to, 'dt': 't', 'q': text},
    );

    final response = await _httpClient.get(uri, headers: {
      'User-Agent': 'Mozilla/5.0',
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 10));

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
  // ML Kit helpers.
  // ──────────────────────────────────────────────────────────────────────────

  OnDeviceTranslator _mlTranslator(TranslationDirection direction) {
    final key = '${direction.sourceLangCode}|${direction.targetLangCode}';
    return _translators.putIfAbsent(
      key,
      () => OnDeviceTranslator(
        sourceLanguage: direction.sourceIsEnglish
            ? TranslateLanguage.english
            : TranslateLanguage.bengali,
        targetLanguage: direction.sourceIsEnglish
            ? TranslateLanguage.bengali
            : TranslateLanguage.english,
      ),
    );
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
