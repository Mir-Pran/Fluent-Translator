import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent_translate/app.dart';
import 'package:fluent_translate/data/models/translation_record.dart';
import 'package:fluent_translate/screens/translate/widgets/translate_button.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    // Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // Initialize Hive in system temp directory for tests
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    Hive.registerAdapter(translationRecordAdapter());
  });

  testWidgets('App boots and shows Translate tab', (WidgetTester tester) async {
    // Build the app and wait for initial frame.
    await tester.pumpWidget(const ProviderScope(child: FluentTranslateApp()));
    await tester.pumpAndSettle();

    // The translate tab's input placeholder should be visible.
    expect(find.text('Type or paste text...'), findsOneWidget);

    // The translate button should exist.
    expect(find.byType(TranslateButton), findsOneWidget);

    // Bottom nav should show all 4 tab labels.
    expect(find.text('Translate'), findsWidgets);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Tapping the Settings tab should switch views.
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets); // tab label + heading

    // Switch back to Translate.
    await tester.tap(find.text('Translate').first);
    await tester.pumpAndSettle();
    expect(find.text('Type or paste text...'), findsOneWidget);
  });
}
