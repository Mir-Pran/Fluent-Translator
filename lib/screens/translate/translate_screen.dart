/// Translate screen — the main tab.
///
/// Layout: top bar → language selector → input card → output card → translate
/// button pinned to the bottom. A banner surfaces errors / model-download
/// progress.
library;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_dimens.dart';
import '../../providers/settings_provider.dart';
import '../../providers/translation_provider.dart';
import 'widgets/input_card.dart';
import 'widgets/language_selector.dart';
import 'widgets/output_card.dart';
import 'widgets/top_bar.dart';
import 'widgets/translate_button.dart';

class TranslateScreen extends ConsumerWidget {
  const TranslateScreen({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  Future<void> _doTranslate(WidgetRef ref) async {
    final settings = ref.read(settingsProvider);
    await ref.read(translateUiStateProvider.notifier).translate(
          autoDetect: settings.autoDetectLanguage,
          offlineFirst: settings.offlineMode,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(translateUiStateProvider);
    final source = ref.watch(sourceTextProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.spaceMd),
      child: Column(
        children: [
          TopBar(onOpenSettings: onOpenSettings),
          const SizedBox(height: AppDimens.spaceSm),
          const LanguageSelector(),
          const SizedBox(height: AppDimens.spaceSm),
          // Auto-translate: fire on each meaningful edit when enabled.
          if (ref.watch(settingsProvider.select((s) => s.autoTranslate)))
            _AutoTranslateEffect(source: source, onFire: () => _doTranslate(ref)),
          if (uiState.error != null)
            _Banner(
              text: uiState.error!,
              icon: Icons.error_outline_rounded,
              color: Colors.red,
              onClose: () =>
                  ref.read(translateUiStateProvider.notifier).clearError(),
            ),
          if (uiState.isDownloading)
            _Banner(
              text: 'Downloading language model for first use…',
              icon: Icons.cloud_download_rounded,
              color: Theme.of(context).colorScheme.primary,
              progress: uiState.downloadProgress,
            ),
          const SizedBox(height: AppDimens.spaceSm),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const InputCard(),
                  const SizedBox(height: AppDimens.spaceSm),
                  const OutputCard(),
                  const SizedBox(height: AppDimens.spaceLg),
                  TranslateButton(
                    isLoading: uiState.isLoading,
                    onTap: () => _doTranslate(ref),
                  ),
                  SizedBox(
                    height: MediaQuery.paddingOf(context).bottom +
                        AppDimens.bottomNavHeight +
                        AppDimens.spaceLg,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight listener that triggers an auto-translate after the user pauses
/// typing (debounced). Mounted only when auto-translate is enabled.
class _AutoTranslateEffect extends ConsumerStatefulWidget {
  const _AutoTranslateEffect({required this.source, required this.onFire});

  final String source;
  final VoidCallback onFire;

  @override
  ConsumerState<_AutoTranslateEffect> createState() =>
      _AutoTranslateEffectState();
}

class _AutoTranslateEffectState extends ConsumerState<_AutoTranslateEffect> {
  String? _lastFired;
  bool _scheduled = false;

  void _schedule() {
    if (_scheduled) return;
    _scheduled = true;
    Future.delayed(const Duration(milliseconds: 700), () {
      _scheduled = false;
      if (!mounted) return;
      if (widget.source != _lastFired && widget.source.trim().isNotEmpty) {
        _lastFired = widget.source;
        widget.onFire();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.source != _lastFired) {
      if (widget.source.trim().isEmpty) {
        _lastFired = widget.source;
      } else {
        _schedule();
      }
    }
    return const SizedBox.shrink();
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.text,
    required this.icon,
    required this.color,
    this.progress,
    this.onClose,
  });

  final String text;
  final IconData icon;
  final Color color;
  final double? progress;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.spaceSm),
      child: Material(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimens.radius),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.spaceMd,
            vertical: AppDimens.spaceSm + 2,
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: AppDimens.spaceSm),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (onClose != null)
                GestureDetector(
                  onTap: onClose,
                  child: Icon(Icons.close_rounded,
                      size: 16, color: color.withValues(alpha: 0.8)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
