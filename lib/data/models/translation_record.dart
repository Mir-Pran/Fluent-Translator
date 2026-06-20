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

/// Represents a translation direction between any two language codes.
///
/// The [enToBn] / [bnToEn] named constructors are kept for legacy Hive
/// record compatibility (directionIndex 0 and 1). New code should use
/// [TranslationDirection.fromCodes].
class TranslationDirection {
  const TranslationDirection._(this.sourceLangCode, this.targetLangCode);

  /// English → Bengali (legacy index 0).
  static const enToBn = TranslationDirection._('en', 'bn');

  /// Bengali → English (legacy index 1).
  static const bnToEn = TranslationDirection._('bn', 'en');

  /// Legacy index list — used only for backward-compat Hive deserialization.
  static const List<TranslationDirection> values = [enToBn, bnToEn];

  /// Create a direction from arbitrary ISO codes.
  factory TranslationDirection.fromCodes(String source, String target) {
    if (source == 'en' && target == 'bn') return enToBn;
    if (source == 'bn' && target == 'en') return bnToEn;
    return TranslationDirection._(source, target);
  }

  final String sourceLangCode;
  final String targetLangCode;

  bool get sourceIsEnglish => sourceLangCode == 'en';

  /// Legacy index: 0 = enToBn, 1 = bnToEn, -1 = other (non-legacy pair).
  int get index {
    if (sourceLangCode == 'en' && targetLangCode == 'bn') return 0;
    if (sourceLangCode == 'bn' && targetLangCode == 'en') return 1;
    return 0; // Safe default for Hive writing — actual pair stored in fields 7&8
  }

  AppLanguage? get sourceLang => AppLanguages.findByCode(sourceLangCode);
  AppLanguage? get targetLang => AppLanguages.findByCode(targetLangCode);

  String get label {
    final src = sourceLang?.name ?? sourceLangCode.toUpperCase();
    final tgt = targetLang?.name ?? targetLangCode.toUpperCase();
    return '$src → $tgt';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranslationDirection &&
          sourceLangCode == other.sourceLangCode &&
          targetLangCode == other.targetLangCode;

  @override
  int get hashCode => Object.hash(sourceLangCode, targetLangCode);

  @override
  String toString() => 'TranslationDirection($sourceLangCode→$targetLangCode)';
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
  }) : directionIndex = direction?.index ?? 0 {
    // Ensure explicit lang codes are always stored even for legacy pairs.
    if (sourceLang == null && direction != null) {
      sourceLang = direction.sourceLangCode;
    }
    if (targetLang == null && direction != null) {
      targetLang = direction.targetLangCode;
    }
  }

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
      sourceLang ?? TranslationDirection.values[directionIndex.clamp(0, 1)].sourceLangCode;

  /// Effective target language code, falling back to legacy directionIndex.
  String get effectiveTargetLang =>
      targetLang ?? TranslationDirection.values[directionIndex.clamp(0, 1)].targetLangCode;

  /// Effective direction (works for any language pair).
  TranslationDirection get effectiveDirection =>
      TranslationDirection.fromCodes(effectiveSourceLang, effectiveTargetLang);

  /// Human-readable label: "English → French".
  String get directionLabel {
    final src = AppLanguages.findByCode(effectiveSourceLang)?.name ??
        effectiveSourceLang.toUpperCase();
    final tgt = AppLanguages.findByCode(effectiveTargetLang)?.name ??
        effectiveTargetLang.toUpperCase();
    return '$src → $tgt';
  }

  /// Legacy getter — used by old code still referencing direction.
  TranslationDirection get direction => effectiveDirection;
  set direction(TranslationDirection d) {
    directionIndex = d.index;
    sourceLang = d.sourceLangCode;
    targetLang = d.targetLangCode;
  }

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
      sourceLang: sourceLang ?? (direction?.sourceLangCode ?? this.sourceLang),
      targetLang: targetLang ?? (direction?.targetLangCode ?? this.targetLang),
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
    final srcLang = fields[7] as String?;
    final tgtLang = fields[8] as String?;

    // Build direction: prefer explicit lang codes, fall back to legacy index.
    final direction = (srcLang != null && tgtLang != null)
        ? TranslationDirection.fromCodes(srcLang, tgtLang)
        : TranslationDirection.values[dirIdx.clamp(0, 1)];

    return TranslationRecord(
      id: fields[0] as String,
      sourceText: fields[1] as String,
      translatedText: fields[2] as String,
      direction: direction,
      createdAt: _decodeTimestamp(fields[4]),
      isFavorite: (fields[5] as bool?) ?? false,
      folder: fields[6] as String?,
      sourceLang: srcLang,
      targetLang: tgtLang,
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
      ..write(obj.sourceLang ?? obj.effectiveSourceLang)
      ..writeByte(8)
      ..write(obj.targetLang ?? obj.effectiveTargetLang);
  }
}
