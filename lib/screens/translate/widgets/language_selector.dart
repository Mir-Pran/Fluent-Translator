/// Language selector row: [ Source ▼ ]  ⇄  [ Target ▼ ]
///
/// Tapping a chip opens a small bottom sheet to choose the language. The
/// middle swap button rotates 180° on tap and swaps direction + text.
library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../data/models/translation_record.dart';
import '../../../providers/translation_provider.dart';

class LanguageSelector extends ConsumerStatefulWidget {
  const LanguageSelector({super.key});

  @override
  ConsumerState<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends ConsumerState<LanguageSelector>
    with SingleTickerProviderStateMixin {
  late final AnimationController _swapController;

  @override
  void initState() {
    super.initState();
    _swapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _swapController.dispose();
    super.dispose();
  }

  Future<void> _onSwap() async {
    HapticFeedback.mediumImpact();
    await _swapController.forward(from: 0);
    ref.read(translateUiStateProvider.notifier).swapLanguages();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final direction = ref.watch(translateDirectionProvider);

    final sourceLabel = direction.sourceIsEnglish ? 'English' : 'বাংলা';
    final targetLabel = direction.sourceIsEnglish ? 'বাংলা' : 'English';

    return Row(
      children: [
        Expanded(
          child: _LangChip(
            label: sourceLabel,
            onTap: () => _showPicker(isSource: true),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppDimens.spaceSm),
          child: _SwapButton(
            animation: _swapController,
            onTap: _onSwap,
            isDark: theme.brightness == Brightness.dark,
          ),
        ),
        Expanded(
          child: _LangChip(
            label: targetLabel,
            onTap: () => _showPicker(isSource: false),
          ),
        ),
      ],
    );
  }

  // For MVP we only support en<->bn, so choosing a language is effectively a
  // swap. The sheet documents the option and Phase 2 will add more languages.
  Future<void> _showPicker({required bool isSource}) async {
    final direction = ref.read(translateDirectionProvider);
    final currentLabel = (isSource == direction.sourceIsEnglish)
        ? (direction.sourceIsEnglish ? 'English' : 'বাংলা')
        : (direction.sourceIsEnglish ? 'বাংলা' : 'English');

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppDimens.spaceMd),
              child: Text('Select language',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            for (final entry in const [('English', 'en'), ('বাংলা', 'bn')])
              ListTile(
                leading: Icon(
                  entry.$2 == 'en'
                      ? Icons.language_rounded
                      : Icons.translate_rounded,
                ),
                title: Text(entry.$1),
                trailing: Text(
                  entry.$2,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () {
                  // Selecting the opposite language swaps direction.
                  final wantEnglish = entry.$2 == 'en';
                  final newDir = wantEnglish
                      ? (isSource
                          ? TranslationDirection.enToBn
                          : TranslationDirection.bnToEn)
                      : (isSource
                          ? TranslationDirection.bnToEn
                          : TranslationDirection.enToBn);
                  if (newDir != direction) {
                    ref.read(translateDirectionProvider.notifier).state =
                        newDir;
                  }
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: AppDimens.spaceSm),
            Padding(
              padding: EdgeInsets.only(bottom: AppDimens.spaceMd),
              child: Text(
                'Currently: $currentLabel',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppDimens.radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.spaceMd,
            vertical: AppDimens.spaceSm + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radius),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color:
                      theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwapButton extends StatelessWidget {
  const _SwapButton({
    required this.animation,
    required this.onTap,
    required this.isDark,
  });

  final Animation<double> animation;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final color = isDark ? Colors.white : Colors.black;
    return RotationTransition(
      turns: Tween(begin: 0.0, end: 1.0).animate(animation),
      child: Material(
        color: color.withValues(alpha: 0.1),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppDimens.spaceSm + 2),
            child: Icon(Icons.swap_horiz_rounded, color: color, size: 22),
          ),
        ),
      ),
    );
  }
}
