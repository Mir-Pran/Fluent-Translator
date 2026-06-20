/// App entry point.
///
/// Boots Hive, loads persisted settings, then runs the app inside a
/// ProviderScope.
library;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/hive_setup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveSetup.init();
  await AppTheme.preloadFonts();

  runApp(const ProviderScope(child: FluentTranslateApp()));
}
