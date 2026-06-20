/// Language selector row: [ Source ▼ ]  ⇄  [ Target ▼ ]
///
/// Tapping a chip opens a searchable bottom sheet showing all 20 languages
/// with flags, native names, and an offline badge for ML Kit-supported ones.
/// The middle swap button rotates 180° on tap and swaps direction + text.
library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_languages.dart';
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
    final src = ref.watch(sourceLangProvider);
    final tgt = ref.watch(targetLangProvider);

    return Row(
      children: [
        Expanded(
          child: _LangChip(
            language: src,
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
            language: tgt,
            onTap: () => _showPicker(isSource: false),
          ),
        ),
      ],
    );
  }

  Future<void> _showPicker({required bool isSource}) async {
    final selected = await showModalBottomSheet<AppLanguage>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _LanguagePickerSheet(
        isSource: isSource,
        currentSource: ref.read(sourceLangProvider),
        currentTarget: ref.read(targetLangProvider),
      ),
    );

    if (selected == null) return;

    if (isSource) {
      ref.read(translateUiStateProvider.notifier).setSourceLanguage(selected);
    } else {
      ref.read(translateUiStateProvider.notifier).setTargetLanguage(selected);
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Language picker bottom sheet with search
// ──────────────────────────────────────────────────────────────────────────────

class _LanguagePickerSheet extends StatefulWidget {
  const _LanguagePickerSheet({
    required this.isSource,
    required this.currentSource,
    required this.currentTarget,
  });

  final bool isSource;
  final AppLanguage currentSource;
  final AppLanguage currentTarget;

  @override
  State<_LanguagePickerSheet> createState() => _LanguagePickerSheetState();
}

class _LanguagePickerSheetState extends State<_LanguagePickerSheet> {
  final _searchController = TextEditingController();
  List<AppLanguage> _filtered = AppLanguages.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      if (q.isEmpty) {
        _filtered = AppLanguages.all;
      } else {
        _filtered = AppLanguages.all.where((l) {
          return l.name.toLowerCase().contains(q) ||
              l.nativeName.toLowerCase().contains(q) ||
              l.code.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  AppLanguage get _currentSelected =>
      widget.isSource ? widget.currentSource : widget.currentTarget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);

    return Container(
      height: mq.size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusLg),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppDimens.spaceMd, AppDimens.spaceSm, AppDimens.spaceMd, 0),
            child: Row(
              children: [
                Text(
                  widget.isSource ? 'From Language' : 'To Language',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.spaceMd,
              vertical: AppDimens.spaceSm,
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search languages…',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radius),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.07),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: AppDimens.spaceMd,
                ),
                isDense: true,
              ),
            ),
          ),

          const Divider(height: 1),

          // Offline legend
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.spaceMd,
              vertical: 6,
            ),
            child: Row(
              children: [
                _OfflineBadge(available: true),
                const SizedBox(width: 6),
                Text(
                  'Offline available',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(width: AppDimens.spaceMd),
                _OfflineBadge(available: false),
                const SizedBox(width: 6),
                Text(
                  'Online only',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Language list
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      'No languages found',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(
                      bottom: mq.padding.bottom + AppDimens.spaceSm,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) {
                      final lang = _filtered[i];
                      final isSelected = lang == _currentSelected;
                      return _LanguageTile(
                        language: lang,
                        isSelected: isSelected,
                        onTap: () => Navigator.pop(context, lang),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.1),
      leading: Text(
        language.flag,
        style: const TextStyle(fontSize: 24),
      ),
      title: Text(
        language.name,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      subtitle: Text(
        language.nativeName,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _OfflineBadge(available: language.supportsOffline),
          if (isSelected) ...[
            const SizedBox(width: 8),
            Icon(Icons.check_rounded,
                size: 18, color: theme.colorScheme.primary),
          ],
        ],
      ),
    );
  }
}

class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge({required this.available});
  final bool available;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = available
        ? Colors.green.shade400
        : theme.colorScheme.onSurface.withValues(alpha: 0.25);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: available ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            available ? Icons.offline_bolt_rounded : Icons.wifi_rounded,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            available ? 'Offline' : 'Online',
            style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Language chip
// ──────────────────────────────────────────────────────────────────────────────

class _LangChip extends StatelessWidget {
  const _LangChip({required this.language, required this.onTap});
  final AppLanguage language;
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
            horizontal: AppDimens.spaceSm,
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(language.flag, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        language.name,
                        style: theme.textTheme.labelLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Swap button
// ──────────────────────────────────────────────────────────────────────────────

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
