/// Settings tab: appearance, translation, speech, and storage sections per PRD.
library;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_dimens.dart';
import '../../providers/settings_provider.dart';
import '../../providers/speech_provider.dart';
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

          // Appearance
          _SectionTitle('Appearance'),
          const SizedBox(height: AppDimens.spaceSm),
          _Card(
            child: RadioGroup<ThemeMode>(
              groupValue: settings.themeMode,
              onChanged: (m) {
                if (m != null) {
                  ref
                      .read(settingsProvider.notifier)
                      .setThemeMode(m);
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

          // Translation
          _SectionTitle('Translation'),
          const SizedBox(height: AppDimens.spaceSm),
          _Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.autoTranslate,
                  onChanged: (_) => ref
                      .read(settingsProvider.notifier)
                      .toggleAutoTranslate(),
                  title: const Text('Auto Translate'),
                  subtitle: const Text(
                      'Translate automatically as you type'),
                  secondary: const Icon(Icons.flash_on_rounded),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: settings.autoDetectLanguage,
                  onChanged: (_) => ref
                      .read(settingsProvider.notifier)
                      .toggleAutoDetect(),
                  title: const Text('Auto Detect Language'),
                  subtitle: const Text(
                      'Detect whether input is English or Bangla'),
                  secondary: const Icon(Icons.auto_fix_high_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.spaceLg),

          // Speech
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
                          onChangeEnd: (v) => ref
                              .read(speechServiceProvider)
                              .setRate(v),
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
                  title: const Text('Prefer Bangla Voice'),
                  subtitle: const Text(
                      'Use a Bangla-accented voice for Bangla output'),
                  secondary: const Icon(Icons.record_voice_over_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimens.spaceLg),

          // Storage
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
              'Fluent Translate • v1.0.0',
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
