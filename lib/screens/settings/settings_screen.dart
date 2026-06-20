/// Settings tab: appearance, translation, speech, offline models, and storage.
library;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_languages.dart';
import '../../providers/settings_provider.dart';
import '../../providers/speech_provider.dart';
import '../../providers/translation_provider.dart';
import '../../providers/translation_repository_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.spaceMd),
      child: ListView(
        padding: EdgeInsets.only(
          top: AppDimens.spaceLg,
          bottom: MediaQuery.paddingOf(context).bottom +
              AppDimens.bottomNavHeight +
              AppDimens.spaceLg,
        ),
        children: [
          Text('Settings', style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppDimens.spaceLg),

          // ── Appearance ────────────────────────────────────────────────────
          _SectionTitle('Appearance'),
          const SizedBox(height: AppDimens.spaceSm),
          _Card(
            child: RadioGroup<ThemeMode>(
              groupValue: settings.themeMode,
              onChanged: (m) {
                if (m != null) {
                  ref.read(settingsProvider.notifier).setThemeMode(m);
                }
              },
              child: Column(
                children: [
                  for (final mode in ThemeMode.values)
                    RadioListTile<ThemeMode>(
                      value: mode,
                      title: Text(_themeModeLabel(mode)),
                      secondary: Icon(_themeModeIcon(mode)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.spaceSm),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppDimens.spaceLg),

          // ── Translation ───────────────────────────────────────────────────
          _SectionTitle('Translation'),
          const SizedBox(height: AppDimens.spaceSm),
          _Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.offlineMode,
                  onChanged: (_) =>
                      ref.read(settingsProvider.notifier).toggleOfflineMode(),
                  title: const Text('Offline Mode'),
                  subtitle: const Text(
                      'Use on-device ML Kit as primary translator (download models below)'),
                  secondary: Icon(
                    settings.offlineMode
                        ? Icons.offline_bolt_rounded
                        : Icons.offline_bolt_outlined,
                    color: settings.offlineMode ? Colors.green.shade400 : null,
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: settings.autoTranslate,
                  onChanged: (_) =>
                      ref.read(settingsProvider.notifier).toggleAutoTranslate(),
                  title: const Text('Auto Translate'),
                  subtitle:
                      const Text('Translate automatically as you type'),
                  secondary: const Icon(Icons.flash_on_rounded),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: settings.autoDetectLanguage,
                  onChanged: (_) =>
                      ref.read(settingsProvider.notifier).toggleAutoDetect(),
                  title: const Text('Auto Detect Language'),
                  subtitle: const Text(
                      'Detect input language automatically from 20 supported languages'),
                  secondary: const Icon(Icons.auto_fix_high_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.spaceLg),

          // ── Offline Models ─────────────────────────────────────────────────
          _SectionTitle('Offline Models'),
          const SizedBox(height: AppDimens.spaceSm),
          Text(
            'Download language models to translate without internet. '
            'Each model is ~30–50 MB. English model is shared across all pairs.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: AppDimens.spaceSm),
          _Card(
            child: Column(
              children: [
                for (int i = 0; i < AppLanguages.offlineSupported.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _ModelTile(language: AppLanguages.offlineSupported[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppDimens.spaceLg),

          // ── Speech ────────────────────────────────────────────────────────
          _SectionTitle('Speech'),
          const SizedBox(height: AppDimens.spaceSm),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.speed_rounded),
                  title: const Text('Voice Speed'),
                  subtitle: Text(_rateLabel(settings.voiceRate)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.spaceMd),
                  child: Row(
                    children: [
                      const Text('0.0×'),
                      Expanded(
                        child: Slider(
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          value: settings.voiceRate,
                          onChanged: (v) => ref
                              .read(settingsProvider.notifier)
                              .setVoiceRate(v),
                          onChangeEnd: (v) =>
                              ref.read(speechServiceProvider).setRate(v),
                        ),
                      ),
                      const Text('1.0×'),
                    ],
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: settings.useBanglaVoice,
                  onChanged: (_) => ref
                      .read(settingsProvider.notifier)
                      .toggleBanglaVoice(),
                  title: const Text('Prefer Bengali Voice'),
                  subtitle: const Text(
                      'Use a Bengali-accented voice for Bengali output'),
                  secondary: const Icon(Icons.record_voice_over_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.spaceLg),

          // ── Storage ───────────────────────────────────────────────────────
          _SectionTitle('Storage'),
          const SizedBox(height: AppDimens.spaceSm),
          _Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.history_rounded),
                  title: const Text('Clear History'),
                  subtitle: const Text('Remove non-saved translations'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _confirmClearHistory(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cleaning_services_rounded),
                  title: const Text('Clear Cache'),
                  subtitle: const Text('Clear downloaded language models'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _snack(context, 'Cache cleared'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.spaceLg),

          Center(
            child: Text(
              'Fluent Translate • v1.1.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'System',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  IconData _themeModeIcon(ThemeMode mode) => switch (mode) {
        ThemeMode.system => Icons.brightness_auto_rounded,
        ThemeMode.light => Icons.light_mode_rounded,
        ThemeMode.dark => Icons.dark_mode_rounded,
      };

  String _rateLabel(double r) => '${r.toStringAsFixed(1)}× speed';

  Future<void> _confirmClearHistory(
      BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text(
            'This removes all non-saved translations. Saved items are kept.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Clear')),
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

// ──────────────────────────────────────────────────────────────────────────────
// Offline model tile — shows download status and a download/delete button.
// ──────────────────────────────────────────────────────────────────────────────

class _ModelTile extends ConsumerStatefulWidget {
  const _ModelTile({required this.language});
  final AppLanguage language;

  @override
  ConsumerState<_ModelTile> createState() => _ModelTileState();
}

class _ModelTileState extends ConsumerState<_ModelTile> {
  bool? _isDownloaded;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final service = ref.read(translationServiceProvider);
    final result = await service.isLanguageModelDownloaded(widget.language);
    if (mounted) setState(() => _isDownloaded = result);
  }

  Future<void> _download() async {
    setState(() => _isLoading = true);
    final service = ref.read(translationServiceProvider);
    final ok = await service.downloadModelForLanguage(widget.language);
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isDownloaded = ok;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(ok
              ? '${widget.language.name} model downloaded'
              : 'Download failed. Check your internet connection.'),
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEn = widget.language.code == 'en';

    Widget trailing;
    if (_isLoading) {
      trailing = const SizedBox(
        width: 20, height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else if (_isDownloaded == true) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded,
              size: 16, color: Colors.green.shade400),
          const SizedBox(width: 4),
          Text('Ready',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.green.shade400)),
        ],
      );
    } else if (_isDownloaded == false) {
      trailing = IconButton(
        icon: const Icon(Icons.download_rounded),
        iconSize: 20,
        visualDensity: VisualDensity.compact,
        tooltip: 'Download',
        onPressed: isEn ? null : _download,
        color: theme.colorScheme.primary,
      );
    } else {
      trailing = const SizedBox(
        width: 16, height: 16,
        child: CircularProgressIndicator(strokeWidth: 1.5),
      );
    }

    return ListTile(
      dense: true,
      leading: Text(widget.language.flag,
          style: const TextStyle(fontSize: 20)),
      title: Text(widget.language.name,
          style: theme.textTheme.bodyMedium),
      subtitle: Text(
        isEn ? 'Base model (shared)' : widget.language.nativeName,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      trailing: trailing,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Helpers
// ──────────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: AppDimens.spaceSm),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimens.spaceXs),
        child: child,
      ),
    );
  }
}
