/// A single persisted translation entry (history + favorites share this model).
///
/// Stored in Hive. The [TypeAdapter] is written by hand (see
/// [translationRecordAdapter]) to avoid a dependency on hive_generator +
/// build_runner, which is brittle on recent Dart toolchains.
///
/// If you add a field: append it at the END with the next @HiveField index and
/// read it defensively (nullable / ?? default) so older boxes still deserialize.
library;
import 'package:hive/hive.dart';

import '../../core/constants/app_languages.dart';

/// Legacy enum kept for backward-compat with old Hive records.
enum TranslationDirection {
  enToBn,
  bnToEn;

  String get label => switch (this) {
        enToBn => 'English → বাংলা',
        bnToEn => 'বাংলা → English',
      };

  bool get sourceIsEnglish => this == enToBn;
  String get sourceLangCode => sourceIsEnglish ? 'en' : 'bn';
  String get targetLangCode => sourceIsEnglish ? 'bn' : 'en';
}

@HiveType(typeId: 0)
class TranslationRecord extends HiveObject {
  TranslationRecord({
    required this.id,
    required this.sourceText,
    required this.translatedText,
    TranslationDirection? direction,
    this.sourceLang,
    this.targetLang,
    required this.createdAt,
    this.isFavorite = false,
    this.folder,
  }) : directionIndex = direction?.index ?? 0;

  @HiveField(0)
  String id;

  @HiveField(1)
  String sourceText;

  @HiveField(2)
  String translatedText;

  /// Legacy direction index kept for old records.
  @HiveField(3)
  int directionIndex;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  bool isFavorite;

  @HiveField(6)
  String? folder;

  /// Source language code (e.g. 'en', 'fr'). Null for legacy records.
  @HiveField(7)
  String? sourceLang;

  /// Target language code (e.g. 'bn', 'ja'). Null for legacy records.
  @HiveField(8)
  String? targetLang;

  // ── Computed ──────────────────────────────────────────────────────────────

  /// Effective source language code, falling back to legacy directionIndex.
  String get effectiveSourceLang =>
      sourceLang ?? TranslationDirection.values[directionIndex].sourceLangCode;

  /// Effective target language code, falling back to legacy directionIndex.
  String get effectiveTargetLang =>
      targetLang ?? TranslationDirection.values[directionIndex].targetLangCode;

  /// Human-readable label: "English → French".
  String get directionLabel {
    final src = AppLanguages.findByCode(effectiveSourceLang)?.name ??
        effectiveSourceLang.toUpperCase();
    final tgt = AppLanguages.findByCode(effectiveTargetLang)?.name ??
        effectiveTargetLang.toUpperCase();
    return '$src → $tgt';
  }

  /// Legacy getter — used by old code still referencing direction.
  TranslationDirection get direction =>
      TranslationDirection.values[directionIndex.clamp(0, 1)];
  set direction(TranslationDirection d) => directionIndex = d.index;

  String get sourceLangCode => effectiveSourceLang;
  String get targetLangCode => effectiveTargetLang;

  TranslationRecord copyWith({
    String? sourceText,
    String? translatedText,
    TranslationDirection? direction,
    String? sourceLang,
    String? targetLang,
    DateTime? createdAt,
    bool? isFavorite,
    String? folder,
  }) {
    return TranslationRecord(
      id: id,
      sourceText: sourceText ?? this.sourceText,
      translatedText: translatedText ?? this.translatedText,
      direction: direction,
      sourceLang: sourceLang ?? this.sourceLang,
      targetLang: targetLang ?? this.targetLang,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      folder: folder ?? this.folder,
    )..directionIndex = direction?.index ?? directionIndex;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranslationRecord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Hand-written Hive TypeAdapter for [TranslationRecord].
TypeAdapter<TranslationRecord> translationRecordAdapter() =>
    _TranslationRecordAdapter();

class _TranslationRecordAdapter extends TypeAdapter<TranslationRecord> {
  @override
  final int typeId = 0;

  @override
  TranslationRecord read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };

    final dirIdx = (fields[3] as int?) ?? 0;
    final direction =
        TranslationDirection.values[dirIdx.clamp(0, TranslationDirection.values.length - 1)];

    return TranslationRecord(
      id: fields[0] as String,
      sourceText: fields[1] as String,
      translatedText: fields[2] as String,
      direction: direction,
      createdAt: _decodeTimestamp(fields[4]),
      isFavorite: (fields[5] as bool?) ?? false,
      folder: fields[6] as String?,
      sourceLang: fields[7] as String?,
      targetLang: fields[8] as String?,
    );
  }

  DateTime _decodeTimestamp(dynamic raw) {
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is DateTime) return raw;
    return DateTime.now();
  }

  @override
  void write(BinaryWriter writer, TranslationRecord obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sourceText)
      ..writeByte(2)
      ..write(obj.translatedText)
      ..writeByte(3)
      ..write(obj.directionIndex)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.isFavorite)
      ..writeByte(6)
      ..write(obj.folder)
      ..writeByte(7)
      ..write(obj.sourceLang)
      ..writeByte(8)
      ..write(obj.targetLang);
  }
}
