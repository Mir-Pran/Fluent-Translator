/// Text-to-speech + speech-to-text wrappers.
///
/// TTS: uses flutter_tts; supports English + Bangla and an adjustable rate.
/// STT: uses speech_to_text; requires the RECORD_AUDIO permission (granted in
/// AndroidManifest.xml). Locale ids are resolved per-language at start time.
library;
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum SpeechState { idle, listening, recognizing, done, error }

class SpeechService {
  SpeechService() {
    _initTts();
  }

  // ---- TTS ----
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;
  double _rate = 0.5; // default normal speed

  Future<void> _initTts() async {
    try {
      await _tts.setSpeechRate(_rate);
      _ttsReady = true;
    } catch (_) {
      _ttsReady = false;
    }
  }

  /// Speak [text] using [languageCode] ('en' or 'bn').
  Future<void> speak(String text, {String languageCode = 'en'}) async {
    if (!_ttsReady) await _initTts();
    await _tts.stop();
    await _tts.setLanguage(languageCode == 'bn' ? 'bn-BD' : 'en-US');
    await _tts.setSpeechRate(_rate);
    await _tts.speak(text);
  }

  Future<void> stopSpeak() => _tts.stop();

  Future<void> setRate(double rate) async {
    _rate = rate;
    await _tts.setSpeechRate(rate);
  }

  // ---- STT ----
  final SpeechToText _stt = SpeechToText();
  bool _sttAvailable = false;
  bool _listening = false;

  bool get isListening => _listening;

  /// Ensure STT has initialized + permissions granted. Returns whether it's
  /// usable on this device.
  Future<bool> ensureAvailable() async {
    if (!_sttAvailable) {
      _sttAvailable = await _stt.initialize(
        onError: (SpeechRecognitionError error) {
          debugPrint('STT error: ${error.errorMsg}');
        },
      );
    }
    return _sttAvailable;
  }

  /// Start listening with [languageCode] ('en' or 'bn'). [onResult] is called
  /// on every partial/final result; the last final string is what callers
  /// usually want.
  Future<void> startListening({
    required String languageCode,
    required ValueChanged<String> onResult,
    VoidCallback? onSoundLevel,
  }) async {
    final ok = await ensureAvailable();
    if (!ok) return;

    _listening = true;
    await _stt.listen(
      onResult: (result) => onResult(result.recognizedWords),
      listenOptions: SpeechListenOptions(
        localeId: await _localeFor(languageCode),
        listenMode: ListenMode.dictation,
        partialResults: true,
      ),
    );
  }

  Future<void> stopListening() async {
    await _stt.stop();
    _listening = false;
  }

  Future<String?> _localeFor(String languageCode) async {
    final locales = await _stt.locales();
    final target = languageCode == 'bn' ? 'bn' : 'en';
    final match = locales.firstWhere(
      (l) => l.localeId.toLowerCase().startsWith(target),
      orElse: () => locales.first,
    );
    return match.localeId;
  }

  /// Release native resources. Safe to call on app teardown.
  void dispose() {
    _tts.stop();
    _stt.stop();
    _stt.cancel();
  }
}
