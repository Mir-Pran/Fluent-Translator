/// Repository over the Hive translations box.
///
/// All history + favorites go through here so the UI never touches Hive
/// directly. Records are keyed by their [TranslationRecord.id]; newest entries
/// are kept first via sorting on read, since Hive boxes are insertion-ordered.
library;
import 'dart:ui';

import 'package:hive/hive.dart';

import '../datasources/hive_setup.dart';
import '../models/translation_record.dart';

class TranslationRepository {
  TranslationRepository(this._box);

  final Box<TranslationRecord> _box;

  static const String _boxName = HiveSetup.translationsBox;

  /// Invoked after any mutation so the Riverpod layer can invalidate live lists.
  /// Wired up by [translationRepositoryProvider] (see providers).
  VoidCallback? onChange;

  void _notify() => onChange?.call();

  /// Open a fresh repository bound to the app's translations box.
  static Future<TranslationRepository> create() async {
    final box = Hive.isBoxOpen(_boxName)
        ? Hive.box<TranslationRecord>(_boxName)
        : await Hive.openBox<TranslationRecord>(_boxName);
    return TranslationRepository(box);
  }

  /// All records, newest first.
  List<TranslationRecord> all() {
    final list = _box.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// History subset (everything, including favorited) — kept as an alias for
  /// clarity at the call site. Newest first.
  List<TranslationRecord> history() => all();

  /// Favorites only, newest first.
  List<TranslationRecord> favorites() {
    final list = _box.values.where((r) => r.isFavorite).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  /// Distinct folder names that have at least one favorite.
  List<String> folders() {
    final set = <String>{};
    for (final r in _box.values) {
      if (r.isFavorite && (r.folder?.isNotEmpty ?? false)) {
        set.add(r.folder!);
      }
    }
    return set.toList()..sort();
  }

  /// Save (or overwrite if id collides) a record. Returns the stored record.
  TranslationRecord save(TranslationRecord record) {
    _box.put(record.id, record);
    _notify();
    return record;
  }

  /// Toggle favorite. Returns the new favorite state.
  bool toggleFavorite(String id) {
    final record = _box.get(id);
    if (record == null) return false;
    record.isFavorite = !record.isFavorite;
    record.save();
    _notify();
    return record.isFavorite;
  }

  /// Assign a folder to a record (used from Saved tab).
  void setFolder(String id, String? folder) {
    final record = _box.get(id);
    if (record == null) return;
    record.folder = (folder == null || folder.isEmpty) ? null : folder;
    record.save();
    _notify();
  }

  void delete(String id) {
    _box.delete(id);
    _notify();
  }

  /// Delete every record that is NOT favorized (history clear).
  void deleteHistory() {
    for (final r in _box.values.where((e) => !e.isFavorite).toList()) {
      _box.delete(r.id);
    }
    _notify();
  }

  Future<void> deleteAll() async {
    await _box.clear();
    _notify();
  }

  Future<void> close() => _box.close();
}
