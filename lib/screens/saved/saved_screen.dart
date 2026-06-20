/// Saved tab: favorite translations grouped by folder, with search, export
/// (TXT/CSV/PDF) and per-item folder assignment.
library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/app_dimens.dart';
import '../../core/utils/export_service.dart';
import '../../data/models/translation_record.dart';
import '../../providers/speech_provider.dart';
import '../../providers/translation_repository_provider.dart';
import '../../widgets/empty_state.dart';
import '../shared/translation_tile.dart';

final _savedSearchProvider = StateProvider<String>((ref) => '');
final _activeFolderProvider = StateProvider<String?>((ref) => null);

class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final favorites = ref.watch(favoritesProvider);
    final folders = ref.watch(foldersProvider);
    final query = ref.watch(_savedSearchProvider);
    final activeFolder = ref.watch(_activeFolderProvider);

    final visible = favorites.where((r) {
      if (activeFolder != null && r.folder != activeFolder) return false;
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
                Text('Saved', style: theme.textTheme.headlineMedium),
                const Spacer(),
                if (favorites.isNotEmpty)
                  PopupMenuButton<_ExportChoice>(
                    icon: const Icon(Icons.ios_share_rounded),
                    tooltip: 'Export',
                    onSelected: (c) => _export(context, c, favorites),
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: _ExportChoice.txt,
                        child: ListTile(
                            leading: Icon(Icons.text_snippet_outlined),
                            title: Text('Export as TXT')),
                      ),
                      PopupMenuItem(
                        value: _ExportChoice.csv,
                        child: ListTile(
                            leading: Icon(Icons.table_chart_outlined),
                            title: Text('Export as CSV')),
                      ),
                      PopupMenuItem(
                        value: _ExportChoice.pdf,
                        child: ListTile(
                            leading: Icon(Icons.picture_as_pdf_outlined),
                            title: Text('Export as PDF')),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (favorites.isNotEmpty) ...[
            _SearchField(
              value: query,
              onChanged: (v) =>
                  ref.read(_savedSearchProvider.notifier).state = v,
            ),
            const SizedBox(height: AppDimens.spaceSm),
            if (folders.isNotEmpty) ...[
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FolderChip(
                      label: 'All',
                      selected: activeFolder == null,
                      onTap: () => ref
                          .read(_activeFolderProvider.notifier)
                          .state = null,
                    ),
                    const SizedBox(width: AppDimens.spaceSm),
                    for (final f in folders) ...[
                      _FolderChip(
                        label: f,
                        selected: activeFolder == f,
                        onTap: () => ref
                            .read(_activeFolderProvider.notifier)
                            .state = f,
                      ),
                      const SizedBox(width: AppDimens.spaceSm),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.spaceSm),
            ],
          ],
          Expanded(
            child: visible.isEmpty
                ? const EmptyState(
                    icon: Icons.bookmark_border_rounded,
                    title: 'Save important translations here',
                    subtitle:
                        'Tap the bookmark on any translation to keep it here.',
                  )
                : ListView.separated(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.paddingOf(context).bottom +
                          AppDimens.bottomNavHeight +
                          AppDimens.spaceLg,
                    ),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppDimens.spaceSm),
                    itemBuilder: (context, i) {
                      final r = visible[i];
                      return TranslationTile(
                        record: r,
                        showFavorite: true,
                        showFolder: true,
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
                        onRepeat: () => _assignFolder(context, ref, r),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _assignFolder(
    BuildContext context,
    WidgetRef ref,
    TranslationRecord r,
  ) async {
    final controller = TextEditingController(text: r.folder ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Move to folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Folder name (e.g. Travel, Study)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null) {
      final repo = await ref.read(translationRepositoryProvider.future);
      repo.setFolder(r.id, name.isEmpty ? null : name);
    }
  }

  Future<void> _export(
    BuildContext context,
    _ExportChoice choice,
    List<TranslationRecord> records,
  ) async {
    try {
      switch (choice) {
        case _ExportChoice.txt:
          await ExportService.shareAsText(records);
        case _ExportChoice.csv:
          await ExportService.shareAsCsv(records);
        case _ExportChoice.pdf:
          await ExportService.shareAsPdf(records);
      }
    } catch (_) {
      if (!context.mounted) return;
      _snack(context, 'Export failed. Please try again.');
    }
  }

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }
}

enum _ExportChoice { txt, csv, pdf }

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
        hintText: 'Search saved',
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

class _FolderChip extends StatelessWidget {
  const _FolderChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primary
          : theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.spaceMd, vertical: AppDimens.spaceSm),
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: selected
                  ? Colors.white
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
