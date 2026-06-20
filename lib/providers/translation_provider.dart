/// Riverpod glue for translation: the service, current source/target languages,
/// the in-flight translate() action, and the latest result shown on the
/// Translate screen.
///
/// The Translate screen reads [translateUiStateProvider] (a Notifier) and calls
/// [TranslateUiNotifier.translate]; the controller handles model download,
/// auto-detect, language swap, and persisting the result to history.
library;
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_languages.dart';
import '../core/services/translation_service.dart';
import '../data/models/translation_record.dart';
import '../data/repositories/translation_repository.dart';
import 'translation_repository_provider.dart';

final translationServiceProvider = Provider<TranslationService>((ref) {
  final service = TranslationService();
  ref.onDispose(service.dispose);
  return service;
});

/// Current source language on the Translate screen.
final sourceLangProvider = StateProvider<AppLanguage>(
  (ref) => AppLanguages.english,
);

/// Current target language on the Translate screen.
final targetLangProvider = StateProvider<AppLanguage>(
  (ref) => AppLanguages.bengali,
);

/// Convenience getter: current translation direction derived from the two lang
/// providers. Used anywhere a [TranslationDirection] is needed.
TranslationDirection currentDirection(Ref ref) {
  final src = ref.read(sourceLangProvider);
  final tgt = ref.read(targetLangProvider);
  return TranslationDirection.fromCodes(src.code, tgt.code);
}

/// Backward-compatible alias — widgets that still call translateDirectionProvider
/// can watch this computed provider instead of migrating immediately.
final translateDirectionProvider = Provider<TranslationDirection>((ref) {
  final src = ref.watch(sourceLangProvider);
  final tgt = ref.watch(targetLangProvider);
  return TranslationDirection.fromCodes(src.code, tgt.code);
});

/// Source text typed by the user (kept in provider state so it survives tab
/// switches when using IndexedStack).
final sourceTextProvider = StateProvider<String>((ref) => '');

/// Latest translation result shown in the output card.
final lastResultProvider = StateProvider<TranslationRecord?>((ref) => null);

/// UI-facing state for the translate action.
class TranslateUiState {
  const TranslateUiState({
    this.isLoading = false,
    this.downloadProgress,
    this.error,
    this.detectedSourceLang,
  });

  final bool isLoading;
  /// null when not downloading, 0..1 during download.
  final double? downloadProgress;
  final String? error;
  final String? detectedSourceLang;

  bool get isDownloading {
    final p = downloadProgress;
    return p != null && p < 1;
  }

  TranslateUiState copyWith({
    bool? isLoading,
    double? downloadProgress,
    String? error,
    String? detectedSourceLang,
    bool clearError = false,
    bool clearProgress = false,
  }) {
    return TranslateUiState(
      isLoading: isLoading ?? this.isLoading,
      downloadProgress:
          clearProgress ? null : downloadProgress ?? this.downloadProgress,
      error: clearError ? null : error ?? this.error,
      detectedSourceLang: detectedSourceLang ?? this.detectedSourceLang,
    );
  }
}

final translateUiStateProvider =
    NotifierProvider<TranslateUiNotifier, TranslateUiState>(
        TranslateUiNotifier.new);

class TranslateUiNotifier extends Notifier<TranslateUiState> {
  @override
  TranslateUiState build() => const TranslateUiState();

  /// Swap source/target languages. Also swaps the current source text with the
  /// last result so the user can immediately translate back.
  void swapLanguages() {
    final src = ref.read(sourceLangProvider);
    final tgt = ref.read(targetLangProvider);
    ref.read(sourceLangProvider.notifier).state = tgt;
    ref.read(targetLangProvider.notifier).state = src;

    // If we have a previous result, seed the new source with it for a smooth
    // round-trip ("translate this back").
    final last = ref.read(lastResultProvider);
    if (last != null && last.translatedText.isNotEmpty) {
      ref.read(sourceTextProvider.notifier).state = last.translatedText;
    }
  }

  /// Set a new source language, ensuring it doesn't equal the target.
  void setSourceLanguage(AppLanguage lang) {
    final tgt = ref.read(targetLangProvider);
    if (lang == tgt) {
      // Swap the current source into the target slot.
      ref.read(targetLangProvider.notifier).state = ref.read(sourceLangProvider);
    }
    ref.read(sourceLangProvider.notifier).state = lang;
  }

  /// Set a new target language, ensuring it doesn't equal the source.
  void setTargetLanguage(AppLanguage lang) {
    final src = ref.read(sourceLangProvider);
    if (lang == src) {
      // Swap the current target into the source slot.
      ref.read(sourceLangProvider.notifier).state = ref.read(targetLangProvider);
    }
    ref.read(targetLangProvider.notifier).state = lang;
  }

  /// Run the translation pipeline for the current source + direction.
  Future<void> translate({
    bool autoDetect = false,
    bool offlineFirst = false,
    bool persist = true,
  }) async {
    final source = ref.read(sourceTextProvider).trim();
    if (source.isEmpty) {
      state = state.copyWith(error: 'Please enter some text to translate.');
      return;
    }

    final service = ref.read(translationServiceProvider);
    var srcLang = ref.read(sourceLangProvider);
    var tgtLang = ref.read(targetLangProvider);

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Auto-detect overrides the chosen source language if confident.
      if (autoDetect) {
        final detected = await service.detectLanguage(source);
        if (detected != null) {
          final detectedLang = AppLanguages.findByCodeFuzzy(detected);
          if (detectedLang != null && detectedLang != tgtLang) {
            srcLang = detectedLang;
            ref.read(sourceLangProvider.notifier).state = srcLang;
            state = state.copyWith(detectedSourceLang: detected);
          }
        }
      }

      final direction = TranslationDirection.fromCodes(srcLang.code, tgtLang.code);

      // Download model if needed (awaits in offline-first mode).
      if (offlineFirst &&
          TranslationService.directionSupportsOffline(direction)) {
        state = state.copyWith(downloadProgress: 0);
        await service.ensureModel(
          direction,
          offlineFirst: true,
          onProgress: (p) => state = state.copyWith(downloadProgress: p),
        );
        state = state.copyWith(clearProgress: true);
      } else {
        // Non-blocking background download for future offline use.
        unawaited(service.ensureModel(direction));
      }

      final result = await service.translate(
        source,
        direction,
        offlineFirst: offlineFirst,
      );

      final record = TranslationRecord(
        id: '${DateTime.now().millisecondsSinceEpoch}-${DateTime.now().microsecond}',
        sourceText: source,
        translatedText: result,
        direction: direction,
        sourceLang: srcLang.code,
        targetLang: tgtLang.code,
        createdAt: DateTime.now(),
      );

      if (persist) {
        final repo = await _repo();
        repo?.save(record);
      }

      ref.read(lastResultProvider.notifier).state = record;

      state = const TranslateUiState();
    } catch (e) {
      debugPrint('translate failed: $e');
      state = TranslateUiState(
        error: _friendlyError(e),
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  Future<TranslationRepository?> _repo() {
    return ref.read(translationRepositoryProvider.future);
  }

  /// Convert a raw exception into a user-friendly message.
  static String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.startsWith('Exception: ')) {
      return msg.substring(11);
    }
    return 'Translation failed. Please check your internet connection or download the offline model from Settings.';
  }
}

// Riverpod needs to know about the class used above.
// ignore: unused_element
typedef _Repo = TranslationRepository;
