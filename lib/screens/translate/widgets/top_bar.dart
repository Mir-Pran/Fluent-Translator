/// Minimal top bar: compact logo mark, app name, theme toggle, settings.
library;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../providers/settings_provider.dart';

class TopBar extends ConsumerWidget {
  const TopBar({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.spaceSm),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? Colors.white : Colors.black,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
            child: Icon(Icons.translate_rounded,
                color: isDark ? Colors.black : Colors.white, size: 18),
          ),
          const SizedBox(width: AppDimens.spaceSm),
          Text('Fluent Translate',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              )),
          const Spacer(),
          _TopBarButton(
            icon: _themeIcon(settings.themeMode),
            tooltip: _themeLabel(settings.themeMode),
            onTap: () {
              HapticFeedback.selectionClick();
              final next = _nextThemeMode(settings.themeMode);
              ref.read(settingsProvider.notifier).setThemeMode(next);
            },
          ),
          const SizedBox(width: AppDimens.spaceXs),
          _TopBarButton(
            icon: Icons.settings_rounded,
            tooltip: 'Settings',
            onTap: () {
              HapticFeedback.selectionClick();
              onOpenSettings();
            },
          ),
        ],
      ),
    );
  }

  IconData _themeIcon(ThemeMode mode) => switch (mode) {
        ThemeMode.system => Icons.brightness_auto_rounded,
        ThemeMode.light => Icons.light_mode_rounded,
        ThemeMode.dark => Icons.dark_mode_rounded,
      };

  String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'System theme',
        ThemeMode.light => 'Light theme',
        ThemeMode.dark => 'Dark theme',
      };

  ThemeMode _nextThemeMode(ThemeMode mode) => switch (mode) {
        ThemeMode.light => ThemeMode.dark,
        ThemeMode.dark => ThemeMode.system,
        ThemeMode.system => ThemeMode.light,
      };
}

class _TopBarButton extends StatelessWidget {
  const _TopBarButton(
      {required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: Icon(icon),
    );
  }
}
