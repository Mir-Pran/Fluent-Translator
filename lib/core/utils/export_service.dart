/// Export translations to TXT, CSV, or PDF and share them.
///
/// - TXT/CSV: written to a temp file via [path_provider], shared via
///   [share_plus] XFile.
/// - PDF: built with the `pdf` package, then shared or saved with `printing`.
///
/// The UI calls a single method per format; this service owns the file
/// lifecycle so callers don't need to think about paths.
library;
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/translation_record.dart';

class ExportService {
  ExportService._();

  // ---------------- TXT ----------------

  static Future<void> shareAsText(
    List<TranslationRecord> records, {
    String fileName = 'fluent_translations',
  }) async {
    final buffer = StringBuffer()
      ..writeln('Fluent Translate — Export')
      ..writeln('Generated: ${DateTime.now()}')
      ..writeln('Count: ${records.length}')
      ..writeln('──────────────────────────────');

    for (final r in records) {
      buffer
        ..writeln('[${r.direction.label}]')
        ..writeln(r.sourceText)
        ..writeln('→')
        ..writeln(r.translatedText)
        ..writeln('──────────────────────────────');
    }

    final file = await _writeTemp('$fileName.txt', buffer.toString());
    await Share.shareXFiles([XFile(file.path)],
        text: 'Fluent Translate export');
  }

  // ---------------- CSV ----------------

  static Future<void> shareAsCsv(
    List<TranslationRecord> records, {
    String fileName = 'fluent_translations',
  }) async {
    final buffer = StringBuffer()
      ..writeln('direction,source,translation,created_at,favorite,folder');

    for (final r in records) {
      buffer.writeln([
        _csvEscape(r.direction.label),
        _csvEscape(r.sourceText),
        _csvEscape(r.translatedText),
        r.createdAt.toIso8601String(),
        r.isFavorite ? 'true' : 'false',
        _csvEscape(r.folder ?? ''),
      ].join(','));
    }

    final file = await _writeTemp('$fileName.csv', buffer.toString());
    await Share.shareXFiles([XFile(file.path)],
        text: 'Fluent Translate CSV export');
  }

  static String _csvEscape(String value) {
    final needsQuote =
        value.contains(',') || value.contains('"') || value.contains('\n');
    var escaped = value.replaceAll('"', '""');
    return needsQuote ? '"$escaped"' : escaped;
  }

  // ---------------- PDF ----------------

  /// Builds a PDF and shares/saves it via the native share sheet.
  static Future<void> shareAsPdf(
    List<TranslationRecord> records, {
    String fileName = 'fluent_translations',
  }) async {
    final doc = _buildPdf(records);
    final bytes = await doc.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: '$fileName.pdf',
    );
  }

  static pw.Document _buildPdf(List<TranslationRecord> records) {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Fluent Translate',
                style: pw.TextStyle(
                    fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Text(
              'Export • ${records.length} entries • ${DateTime.now()}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
            ),
            pw.Divider(),
          ],
        ),
        build: (context) => [
          for (final r in records) ...[
            pw.Text(r.direction.label,
                style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.indigo,
                    fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 2),
            pw.Text(r.sourceText, style: const pw.TextStyle(fontSize: 11)),
            pw.Text('→', style: const pw.TextStyle(fontSize: 11)),
            pw.Text(r.translatedText,
                style: pw.TextStyle(
                    fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 8),
              child: pw.Divider(height: 1, color: PdfColors.grey300),
            ),
          ],
        ],
      ),
    );

    return pdf;
  }

  // ---------------- helpers ----------------

  static Future<File> _writeTemp(String name, String content) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsString(content);
    return file;
  }
}
