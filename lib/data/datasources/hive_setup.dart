/// Hive initialization and box access.
///
/// Call [HiveSetup.init] once during app startup (before runApp). It opens the
/// translations box that the repository reads from. Box names live here so the
/// repository and init never disagree on the string.
library;
import 'package:hive_flutter/hive_flutter.dart';

import '../models/translation_record.dart';

class HiveSetup {
  HiveSetup._();

  static const String translationsBox = 'translations';

  /// Initialize Hive, register adapters and open the translations box.
  static Future<Box<TranslationRecord>> init() async {
    await Hive.initFlutter();

    // Guard against double-registration during hot restart.
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(translationRecordAdapter());
    }

    return Hive.openBox<TranslationRecord>(translationsBox);
  }
}
