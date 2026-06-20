/// Output card: shows the latest translation with copy / share / speak / save.
/// Only renders when there is a result; empty space otherwise.
library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/speech_provider.dart';
import '../../../providers/translation_provider.dart';
import '../../../providers/translation_repository_provider.dart';

class OutputCard extends ConsumerWidget {
  const OutputCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(lastResultProvider);

    if (record == null) {
      // Show a placeholder card so the output area is always visible.
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.spaceMd,
            vertical: AppDimens.spaceLg,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.translate_rounded,
                size: 20,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.2),
              ),
              const SizedBox(width: AppDimens.spaceSm),
              Text(
                'Translation will appear here',
                style: AppTextStyles.body.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ),
      );
    }


    return AnimatedOpacity(
      opacity: 1,
      duration: AppDimens.duration,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimens.spaceMd,
            AppDimens.space,
            AppDimens.spaceSm,
            AppDimens.spaceSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                record.translatedText,
                style: AppTextStyles.translated.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppDimens.spaceSm),
              // Action row
              Row(
                children: [
                  const Spacer(),
                  _ActionButton(
                    icon: Icons.copy_rounded,
                    tooltip: 'Copy',
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: record.translatedText));
                      HapticFeedback.selectionClick();
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                            const SnackBar(content: Text('Copied')));
                    },
                  ),
                  _ActionButton(
                    icon: Icons.share_rounded,
                    tooltip: 'Share',
                    onTap: () => Share.share(record.translatedText,
                        subject: 'Fluent Translate'),
                  ),
                  _ActionButton(
                    icon: Icons.volume_up_rounded,
                    tooltip: 'Speak',
                    onTap: () {
                      ref.read(speechServiceProvider).speak(
                            record.translatedText,
                            languageCode: record.targetLangCode,
                          );
                    },
                  ),
                  _ActionButton(
                    icon: record.isFavorite
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    tooltip: record.isFavorite ? 'Unsave' : 'Save',
                    tint: record.isFavorite
                        ? Theme.of(context).colorScheme.onSurface
                        : null,
                    onTap: () async {
                      HapticFeedback.selectionClick();
                      final repo =
                          await ref.read(translationRepositoryProvider.future);
                      final nowFav = repo.toggleFavorite(record.id);
                      if (!context.mounted) return;
                      ref.read(lastResultProvider.notifier).state =
                          record.copyWith(isFavorite: nowFav);
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(
                            content: Text(
                                nowFav ? 'Saved' : 'Removed from Saved')));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.tint,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      iconSize: 18,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      color: tint ?? theme.colorScheme.onSurface.withValues(alpha: 0.5),
      icon: Icon(icon),
    );
  }
}
