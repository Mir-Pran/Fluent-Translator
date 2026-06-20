/// Shared card that renders a single translation record.
///
/// Used by both the History and Saved tabs. Shows source + translation, the
/// direction label, timestamp, and an action row. A swipe-to-delete gesture is
/// wired via the consuming screen.
library;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_dimens.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/translation_record.dart';
import '../../providers/translation_repository_provider.dart';

class TranslationTile extends ConsumerWidget {
  const TranslationTile({
    super.key,
    required this.record,
    this.showFavorite = true,
    this.showFolder = false,
    this.onCopy,
    this.onShare,
    this.onSpeak,
    this.onRepeat,
  });

  final TranslationRecord record;
  final bool showFavorite;
  final bool showFolder;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onSpeak;
  final VoidCallback? onRepeat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return Dismissible(
      key: ValueKey(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimens.spaceLg),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
      ),
      confirmDismiss: (_) async {
        return await _confirmDelete(context);
      },
      onDismissed: (_) async {
        final repo = await ref.read(translationRepositoryProvider.future);
        repo.delete(record.id);
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.spaceSm + 2,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    ),
                    child: Text(
                      record.direction.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.spaceSm),
                  if (showFolder && (record.folder?.isNotEmpty ?? false))
                    Flexible(
                      child: Text(
                        record.folder!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: secondary, fontSize: 11),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const Spacer(),
                  Text(
                    AppDateFormatter.relative(record.createdAt),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: secondary, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.spaceSm),
              Text(
                record.sourceText,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: secondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDimens.spaceXs),
              Text(
                record.translatedText,
                style: theme.textTheme.titleLarge?.copyWith(fontSize: 16),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDimens.spaceSm),
              Row(
                children: [
                  if (showFavorite)
                    _Action(
                      icon: record.isFavorite
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      label: record.isFavorite ? 'Saved' : 'Save',
                      active: record.isFavorite,
                      onTap: () async {
                        final repo = await ref
                            .read(translationRepositoryProvider.future);
                        repo.toggleFavorite(record.id);
                      },
                    ),
                  if (onCopy != null)
                    _Action(
                      icon: Icons.copy_rounded,
                      onTap: onCopy,
                    ),
                  if (onShare != null)
                    _Action(icon: Icons.share_rounded, onTap: onShare),
                  if (onSpeak != null)
                    _Action(icon: Icons.volume_up_rounded, onTap: onSpeak),
                  if (onRepeat != null)
                    _Action(icon: Icons.replay_rounded, onTap: onRepeat),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete translation?'),
            content: const Text('This translation will be removed permanently.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    this.label,
    this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String? label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = active
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.6);
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: label != null
          ? Text(label!,
              style: theme.textTheme.bodySmall?.copyWith(color: color))
          : const SizedBox.shrink(),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: AppDimens.spaceSm),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
