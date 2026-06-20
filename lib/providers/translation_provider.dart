/// Riverpod glue for translation: the service, current direction, the in-flight
/// translate() action, and the latest result shown on the Translate screen.
///
/// The Translate screen reads [translateProvider] (a Notifier) and calls
/// [TranslationController.translate]; the controller handles model download,
/// auto-detect, language swap, and persisting the result to history.
library;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/translation_service.dart';
import '../data/models/translation_record.dart';
import '../data/repositories/translation_repository.dart';
import 'translation_repository_provider.dart';

final translationServiceProvider = Provider<TranslationService>((ref) {
  final service = TranslationService();
  ref.onDispose(service.dispose);
  return service;
});

/// Current translation direction on the Translate screen.
final translateDirectionProvider =
    StateProvider<TranslationDirection>((ref) => TranslationDirection.enToBn);

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
    final dir = ref.read(translateDirectionProvider);
    ref.read(translateDirectionProvider.notifier).state =
        dir == TranslationDirection.enToBn
            ? TranslationDirection.bnToEn
            : TranslationDirection.enToBn;

    // If we have a previous result, seed the new source with it for a smooth
    // round-trip ("translate this back").
    final last = ref.read(lastResultProvider);
    if (last != null && last.translatedText.isNotEmpty) {
      ref.read(sourceTextProvider.notifier).state = last.translatedText;
    }
  }

  /// Run the translation pipeline for the current source + direction.
  Future<void> translate({
    bool autoDetect = false,
    bool persist = true,
  }) async {
    final source = ref.read(sourceTextProvider).trim();
    if (source.isEmpty) {
      state = state.copyWith(error: 'Please enter some text to translate.');
      return;
    }

    final service = ref.read(translationServiceProvider);
    var direction = ref.read(translateDirectionProvider);

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Auto-detect overrides the chosen source language if confident.
      if (autoDetect) {
        final detected = await service.detectLanguage(source);
        if (detected != null) {
          final detectedIsBn = detected.toLowerCase().startsWith('bn');
          direction = detectedIsBn
              ? TranslationDirection.bnToEn
              : TranslationDirection.enToBn;
          ref.read(translateDirectionProvider.notifier).state = direction;
          state = state.copyWith(detectedSourceLang: detected);
        }
      }

      // Make sure the offline model is present (downloads on first use).
      state = state.copyWith(downloadProgress: 0);
      await service.ensureModel(
        direction,
        onProgress: (p) => state = state.copyWith(downloadProgress: p),
      );
      state = state.copyWith(downloadProgress: 1);

      final result = await service.translate(source, direction);

      final record = TranslationRecord(
        id: '${DateTime.now().millisecondsSinceEpoch}-${DateTime.now().microsecond}',
        sourceText: source,
        translatedText: result,
        direction: direction,
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
    return 'Translation failed. Please check your internet connection.';
  }
}

// Riverpod needs to know about the class used above.
// ignore: unused_element
typedef _Repo = TranslationRepository;
