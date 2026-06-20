/// History tab: search, filter by language, delete single / delete all, with
/// copy/share/speak/save/repeat-translate actions per item.
library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_dimens.dart';
import '../../data/models/translation_record.dart';
import '../../providers/speech_provider.dart';
import '../../providers/translation_repository_provider.dart';
import '../../widgets/empty_state.dart';
import '../shared/translation_tile.dart';

final _historyFilterProvider =
    StateProvider<TranslationDirection?>((ref) => null);

final _historySearchProvider = StateProvider<String>((ref) => '');

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final all = ref.watch(historyProvider);
    final filter = ref.watch(_historyFilterProvider);
    final query = ref.watch(_historySearchProvider);

    final filtered = all.where((r) {
      if (filter != null && r.direction != filter) return false;
      if (query.isEmpty) return true;
      final q = query.toLowerCase();
      return r.sourceText.toLowerCase().contains(q) ||
          r.translatedText.toLowerCase().contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: AppDimens.spaceLg,
              bottom: AppDimens.spaceSm,
            ),
            child: Row(
              children: [
                Text('History', style: theme.textTheme.headlineMedium),
                const Spacer(),
                if (all.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear all',
                    icon: const Icon(Icons.delete_sweep_rounded),
                    onPressed: () => _confirmClearAll(context, ref),
                  ),
              ],
            ),
          ),
          if (all.isNotEmpty) ...[
            _SearchField(
              value: query,
              onChanged: (v) =>
                  ref.read(_historySearchProvider.notifier).state = v,
            ),
            const SizedBox(height: AppDimens.spaceSm),
            _FilterChips(
              selected: filter,
              onSelect: (d) => ref.read(_historyFilterProvider.notifier).state =
                  d == filter ? null : d,
            ),
            const SizedBox(height: AppDimens.spaceSm),
          ],
          Expanded(
            child: filtered.isEmpty
                ? EmptyState(
                    icon: Icons.history_rounded,
                    title: all.isEmpty ? 'No translations yet' : 'No matches',
                    subtitle: all.isEmpty
                        ? 'Your translations will show up here.'
                        : 'Try a different search or filter.',
                  )
                : ListView.separated(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.paddingOf(context).bottom +
                          AppDimens.bottomNavHeight +
                          AppDimens.spaceLg,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppDimens.spaceSm),
                    itemBuilder: (context, i) {
                      final r = filtered[i];
                      return TranslationTile(
                        record: r,
                        showFavorite: true,
                        onCopy: () {
                          Clipboard.setData(
                              ClipboardData(text: r.translatedText));
                          _snack(context, 'Copied');
                        },
                        onShare: () => Share.share(r.translatedText),
                        onSpeak: () => ref.read(speechServiceProvider).speak(
                              r.translatedText,
                              languageCode: r.targetLangCode,
                            ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text(
            'This permanently deletes all translations. Saved items are not affected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final repo = await ref.read(translationRepositoryProvider.future);
      repo.deleteHistory();
      if (!context.mounted) return;
      _snack(context, 'History cleared');
    }
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Search translations',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: value.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 18),
                onPressed: () => onChanged(''),
              )
            : null,
        filled: true,
        fillColor: theme.colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.radius),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimens.spaceMd, vertical: AppDimens.space),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelect});
  final TranslationDirection? selected;
  final ValueChanged<TranslationDirection> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppDimens.spaceSm,
      children: [
        for (final d in TranslationDirection.values)
          ChoiceChip(
            label: Text(d.label),
            selected: selected == d,
            onSelected: (_) => onSelect(d),
          ),
      ],
    );
  }
}
