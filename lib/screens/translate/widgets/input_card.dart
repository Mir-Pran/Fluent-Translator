/// Input card: large text area + character count + clear/paste/voice buttons.
library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/speech_provider.dart';
import '../../../providers/translation_provider.dart';

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
    final direction = ref.read(translateDirectionProvider);
    final langCode = direction.sourceLangCode;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = ref.watch(sourceTextProvider);
    final listening = ref.watch(isListeningProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.spaceMd,
          AppDimens.space,
          AppDimens.spaceSm,
          AppDimens.spaceSm,
        ),
        child: Column(
          children: [
            // Action row: clear, paste, voice
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
                _VoiceButton(
                  listening: listening,
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
                hintText: 'Type or paste text...',
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
  const _VoiceButton({required this.listening, required this.onTap});
  final bool listening;
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
