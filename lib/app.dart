/// Root [MaterialApp]: reactive theme switching, app title, home route.
library;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'screens/home/home_screen.dart';

class FluentTranslateApp extends ConsumerStatefulWidget {
  const FluentTranslateApp({super.key});

  @override
  ConsumerState<FluentTranslateApp> createState() => _FluentTranslateAppState();
}

class _FluentTranslateAppState extends ConsumerState<FluentTranslateApp> {
  @override
  void initState() {
    super.initState();
    // Load persisted settings once on startup.
    Future.microtask(() => ref.read(settingsProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(
      settingsProvider.select((s) => s.themeMode),
    );

    // MaterialApp animates between theme/darkTheme automatically when
    // themeMode changes (PRD: theme switch animation, 150-250ms).
    return MaterialApp(
      title: 'Fluent Translate',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const HomeScreen(),
    );
  }
}
