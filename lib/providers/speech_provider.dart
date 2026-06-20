/// Single shared [SpeechService] for the whole app.
library;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/speech_service.dart';

final speechServiceProvider = Provider<SpeechService>((ref) {
  final service = SpeechService();
  ref.onDispose(service.dispose);
  return service;
});

/// Reactive indicator for whether STT is currently listening.
final isListeningProvider = StateProvider<bool>((ref) => false);
