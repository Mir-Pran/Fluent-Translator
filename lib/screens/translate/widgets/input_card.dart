/// Input card: large text area + character count + clear/paste/voice buttons.
library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/ocr_service.dart';
import '../../../providers/speech_provider.dart';
import '../../../providers/translation_provider.dart';
import '../../../widgets/glass_card.dart';

class InputCard extends ConsumerStatefulWidget {
  const InputCard({super.key});

  @override
  ConsumerState<InputCard> createState() => _InputCardState();
}

class _InputCardState extends ConsumerState<InputCard> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(sourceTextProvider),
    );
    _controller.addListener(() {
      ref.read(sourceTextProvider.notifier).state = _controller.text;
    });
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _startVoiceInput() async {
    // Use the source language code from the new provider.
    final srcLang = ref.read(sourceLangProvider);
    final langCode = srcLang.ttsLocale; // BCP-47 for speech recognition

    final speech = ref.read(speechServiceProvider);
    final ok = await speech.ensureAvailable();
    if (!ok) {
      _toast('Voice input unavailable on this device');
      return;
    }

    ref.read(isListeningProvider.notifier).state = true;
    await speech.startListening(
      languageCode: langCode,
      onResult: (words) {
        if (words.isEmpty) return;
        _controller.text = words;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
      },
    );
  }

  Future<void> _stopVoiceInput() async {
    await ref.read(speechServiceProvider).stopListening();
    ref.read(isListeningProvider.notifier).state = false;
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.isNotEmpty) {
      _controller.text = data.text!;
      _toast('Pasted from clipboard');
    }
  }

  Future<void> _handleOcrInput() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (ctx) => const _OcrSourceBottomSheet(),
    );

    if (source == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 16),
            Text('Recognizing text from image...'),
          ],
        ),
        duration: Duration(days: 1),
      ),
    );

    try {
      final srcLang = ref.read(sourceLangProvider);
      final text = await OcrService.recognizeText(
        source: source,
        sourceLanguageCode: srcLang.code,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (text != null && text.isNotEmpty) {
        _controller.text = text;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
        _toast('Text recognized and loaded');
      } else {
        _toast('No text found in image');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _toast('OCR failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = ref.watch(sourceTextProvider);
    final listening = ref.watch(isListeningProvider);
    final srcLang = ref.watch(sourceLangProvider);

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(
        AppDimens.spaceMd,
        AppDimens.space,
        AppDimens.spaceSm,
        AppDimens.spaceSm,
      ),
      child: Column(
          children: [
            // Action row: clear, paste, camera, voice
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (text.isNotEmpty)
                  _MiniButton(
                    icon: Icons.close_rounded,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _controller.clear();
                    },
                  ),
                _MiniButton(icon: Icons.content_paste_rounded, onTap: _paste),
                _MiniButton(
                  icon: Icons.camera_alt_rounded,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _handleOcrInput();
                  },
                ),
                _VoiceButton(
                  listening: listening,
                  langFlag: srcLang.flag,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    listening ? _stopVoiceInput() : _startVoiceInput();
                  },
                ),
              ],
            ),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              minLines: 4,
              maxLines: 8,
              textInputAction: TextInputAction.newline,
              style: AppTextStyles.bodyMedium.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              maxLength: AppDimens.maxInputChars,
              decoration: InputDecoration(
                counterText: '',
                isDense: true,
                hintText: 'Type or paste text in ${srcLang.name}…',
                hintStyle: AppTextStyles.body.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.35),
                ),
              ),
            ),
            // Character count, right-aligned
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${text.length}/${AppDimens.maxInputChars}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      onPressed: onTap,
      iconSize: 18,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
      icon: Icon(icon),
    );
  }
}

class _VoiceButton extends StatelessWidget {
  const _VoiceButton({
    required this.listening,
    required this.langFlag,
    required this.onTap,
  });
  final bool listening;
  final String langFlag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      onPressed: onTap,
      iconSize: 18,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      icon: Icon(
        listening ? Icons.mic_rounded : Icons.mic_none_rounded,
        color: listening ? Colors.red : theme.colorScheme.primary,
      ),
    );
  }
}

class _OcrSourceBottomSheet extends StatelessWidget {
  const _OcrSourceBottomSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppDimens.spaceMd),
      child: GlassCard(
        padding: const EdgeInsets.all(AppDimens.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Capture or Import Document',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _OcrOptionCard(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                ),
                const SizedBox(width: AppDimens.spaceMd),
                Expanded(
                  child: _OcrOptionCard(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _OcrOptionCard extends StatelessWidget {
  const _OcrOptionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(AppDimens.radius),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
