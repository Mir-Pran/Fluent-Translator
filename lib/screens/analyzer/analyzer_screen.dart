/// Document analyzer screen: handles PDF/TXT uploading, text extraction,
/// extractive summarization, translation, and key statistics/analytics.
library;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_languages.dart';
import '../../core/services/ocr_service.dart';
import '../../data/models/translation_record.dart';
import '../../providers/speech_provider.dart';
import '../../providers/translation_provider.dart';
import '../../widgets/glass_card.dart';

class AnalyzerScreen extends ConsumerStatefulWidget {
  const AnalyzerScreen({super.key});

  @override
  ConsumerState<AnalyzerScreen> createState() => _AnalyzerScreenState();
}

class _AnalyzerScreenState extends ConsumerState<AnalyzerScreen> {
  bool _loading = false;
  String? _fileName;
  String? _fileSize;
  String? _rawText;
  String? _summary;
  String? _translatedSummary;
  AppLanguage _targetLang = AppLanguages.bengali;
  bool _translating = false;

  // Analytics stats
  int _wordCount = 0;
  int _charCount = 0;
  int _readingTime = 0;
  List<MapEntry<String, int>> _topKeywords = [];

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      setState(() {
        _loading = true;
        _fileName = result.files.first.name;
        _fileSize = _formatBytes(result.files.first.size);
        _rawText = null;
        _summary = null;
        _translatedSummary = null;
      });

      final bytes = result.files.first.bytes;
      if (bytes == null) {
        throw Exception('Could not read file bytes');
      }

      String extractedText = '';
      if (result.files.first.extension?.toLowerCase() == 'pdf') {
        extractedText = await _extractPdfText(bytes);
      } else {
        extractedText = utf8.decode(bytes);
      }

      if (extractedText.trim().isEmpty) {
        throw Exception('The document appears to be empty or contains unscannable text.');
      }

      _computeStats(extractedText);
      _generateSummary(extractedText);

      setState(() {
        _rawText = extractedText;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _fileName = null;
      });
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> _handleOcrInput() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (ctx) => const _OcrSourceBottomSheet(),
    );

    if (source == null) return;

    setState(() {
      _loading = true;
      _fileName = source == ImageSource.camera ? 'Camera Scan.jpg' : 'Gallery Image.jpg';
      _fileSize = 'Processing...';
      _rawText = null;
      _summary = null;
      _translatedSummary = null;
    });

    try {
      final text = await OcrService.recognizeText(
        source: source,
        sourceLanguageCode: 'en',
      );

      if (text == null || text.trim().isEmpty) {
        throw Exception('No text could be recognized from the image.');
      }

      _computeStats(text);
      _generateSummary(text);

      setState(() {
        _rawText = text;
        _fileSize = _formatBytes(utf8.encode(text).length);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _fileName = null;
      });
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<String> _extractPdfText(Uint8List bytes) async {
    // Run Syncfusion PDF extraction
    final document = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(document);
    final text = extractor.extractText();
    document.dispose();
    return text;
  }

  void _computeStats(String text) {
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((w) => w.trim().isNotEmpty)
        .toList();

    _wordCount = words.length;
    _charCount = text.length;
    _readingTime = (_wordCount / 200).ceil(); // average reading speed 200 wpm

    // Compute top keywords (filter short & common stopwords)
    final stopwords = {
      'the', 'and', 'a', 'to', 'of', 'in', 'i', 'is', 'that', 'it', 'on', 'you',
      'this', 'for', 'but', 'with', 'as', 'are', 'was', 'were', 'or', 'at', 'an',
      'be', 'by', 'from', 'have', 'has', 'had', 'not', 'what', 'we', 'they'
    };

    final freqMap = <String, int>{};
    for (final word in words) {
      if (word.length > 3 && !stopwords.contains(word)) {
        freqMap[word] = (freqMap[word] ?? 0) + 1;
      }
    }

    final sorted = freqMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    _topKeywords = sorted.take(5).toList();
  }

  // Smart extractive summary (offline, TF-IDF inspired sentence ranking)
  void _generateSummary(String text) {
    // Split sentences
    final sentenceReg = RegExp(r'(?<=[.!?])\s+');
    final sentences = text.split(sentenceReg).where((s) => s.trim().length > 10).toList();

    if (sentences.isEmpty) {
      _summary = text;
      return;
    }

    // Rank sentences by counting frequencies of unique words in them
    final wordFreqs = <String, int>{};
    for (final s in sentences) {
      final words = s.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').split(RegExp(r'\s+'));
      for (final w in words) {
        if (w.length > 3) {
          wordFreqs[w] = (wordFreqs[w] ?? 0) + 1;
        }
      }
    }

    final sentenceScores = <int, double>{};
    for (int i = 0; i < sentences.length; i++) {
      final s = sentences[i];
      final words = s.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').split(RegExp(r'\s+'));
      double score = 0;
      for (final w in words) {
        score += wordFreqs[w] ?? 0;
      }
      // Normalize score by sentence word count to avoid bias toward extremely long sentences
      sentenceScores[i] = words.isEmpty ? 0 : (score / words.length);
    }

    final sortedIndexes = sentenceScores.keys.toList()
      ..sort((a, b) => sentenceScores[b]!.compareTo(sentenceScores[a]!));

    // Take top 3-5 sentences based on size
    final summaryCount = (sentences.length * 0.15).clamp(3, 5).toInt();
    final topIndexes = sortedIndexes.take(summaryCount).toList()..sort();

    final summaryBuffer = StringBuffer();
    for (final idx in topIndexes) {
      summaryBuffer.write('${sentences[idx].trim()} ');
    }

    _summary = summaryBuffer.toString().trim();
  }

  Future<void> _translateSummary() async {
    if (_summary == null) return;
    setState(() => _translating = true);

    try {
      final service = ref.read(translationServiceProvider);
      // We will perform translation from english (usually) or auto-detect to target.
      final result = await service.translate(
        _summary!,
        TranslationDirection.fromCodes('en', _targetLang.code),
      );
      setState(() {
        _translatedSummary = result;
        _translating = false;
      });
    } catch (e) {
      setState(() => _translating = false);
      _showError('Translation failed. Please check your internet connection.');
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimens.spaceMd),
      child: ListView(
        padding: EdgeInsets.only(
          top: AppDimens.spaceLg,
          bottom: MediaQuery.paddingOf(context).bottom +
              AppDimens.bottomNavHeight +
              AppDimens.spaceLg,
        ),
        children: [
          Row(
            children: [
              Text('Analyzer', style: theme.textTheme.headlineMedium),
              const Spacer(),
              if (_fileName != null)
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Upload another',
                  onPressed: _pickFile,
                ),
            ],
          ),
          const SizedBox(height: AppDimens.spaceLg),

          // ── Upload / Scan Options ──
          if (_fileName == null)
            Column(
              children: [
                GestureDetector(
                  onTap: _loading ? null : _pickFile,
                  child: GlassCard(
                    padding: const EdgeInsets.all(AppDimens.spaceLg),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Upload Document',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select a PDF or TXT file to extract text, summarize, and analyze key stats.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.spaceMd),
                GestureDetector(
                  onTap: _loading ? null : _handleOcrInput,
                  child: GlassCard(
                    padding: const EdgeInsets.all(AppDimens.spaceLg),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Scan Document / Photo',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Take a picture or choose a photo of a document to extract, summarize, and analyze.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            )
          else ...[
            // File metadata
            GlassCard(
              padding: const EdgeInsets.all(AppDimens.spaceMd),
              child: Row(
                children: [
                  Icon(
                    _fileName!.endsWith('.pdf')
                        ? Icons.picture_as_pdf_rounded
                        : (_fileName!.endsWith('.jpg')
                            ? Icons.image_rounded
                            : Icons.description_rounded),
                    color: _fileName!.endsWith('.pdf')
                        ? Colors.red.shade400
                        : (_fileName!.endsWith('.jpg')
                            ? theme.colorScheme.primary
                            : Colors.blue.shade400),
                    size: 28,
                  ),
                  const SizedBox(width: AppDimens.spaceSm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fileName!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _fileSize!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      setState(() {
                        _fileName = null;
                        _rawText = null;
                        _summary = null;
                        _translatedSummary = null;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimens.spaceMd),
          ],

          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Extracting and analyzing document…'),
                  ],
                ),
              ),
            ),

          if (!_loading && _rawText != null) ...[
            // ── Key Statistics / Analytics ──
            _SectionTitle('Analytics'),
            const SizedBox(height: AppDimens.spaceSm),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Words',
                    value: _wordCount.toString(),
                    icon: Icons.notes_rounded,
                  ),
                ),
                const SizedBox(width: AppDimens.spaceSm),
                Expanded(
                  child: _StatCard(
                    title: 'Characters',
                    value: _charCount.toString(),
                    icon: Icons.text_fields_rounded,
                  ),
                ),
                const SizedBox(width: AppDimens.spaceSm),
                Expanded(
                  child: _StatCard(
                    title: 'Reading Time',
                    value: '$_readingTime min',
                    icon: Icons.timer_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimens.spaceSm),
            if (_topKeywords.isNotEmpty)
              GlassCard(
                padding: const EdgeInsets.all(AppDimens.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOP KEYWORDS',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final kw in _topKeywords)
                          Chip(
                            label: Text('${kw.key} (${kw.value})'),
                            visualDensity: VisualDensity.compact,
                            side: BorderSide.none,
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppDimens.spaceLg),

            // ── AI Summary ──
            if (_summary != null) ...[
              Row(
                children: [
                  _SectionTitle('Extracted Summary'),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _summary!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Summary copied')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded, size: 18),
                    onPressed: () => Share.share(_summary!),
                  ),
                ],
              ),
              const SizedBox(height: AppDimens.spaceSm),
              GlassCard(
                padding: const EdgeInsets.all(AppDimens.spaceMd),
                child: Text(
                  _summary!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.spaceLg),

              // ── Translate Summary ──
              _SectionTitle('Translate Summary'),
              const SizedBox(height: AppDimens.spaceSm),
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.spaceMd,
                  vertical: AppDimens.spaceSm,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('Translate summary to: '),
                        const Spacer(),
                        DropdownButton<AppLanguage>(
                          value: _targetLang,
                          underline: const SizedBox.shrink(),
                          items: [
                            for (final lang in AppLanguages.all)
                              DropdownMenuItem(
                                value: lang,
                                child: Text('${lang.flag} ${lang.name}'),
                              )
                          ],
                          onChanged: (lang) {
                            if (lang != null) {
                              setState(() {
                                _targetLang = lang;
                                _translatedSummary = null;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    if (_translating)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator(),
                      )
                    else if (_translatedSummary != null) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SelectableText(
                          _translatedSummary!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _translatedSummary!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Translation copied')),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.volume_up_rounded, size: 16),
                            onPressed: () {
                              ref.read(speechServiceProvider).speak(
                                    _translatedSummary!,
                                    languageCode: _targetLang.code,
                                  );
                            },
                          ),
                        ],
                      ),
                    ] else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _translateSummary,
                          icon: const Icon(Icons.g_translate_rounded),
                          label: const Text('Translate'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppDimens.radius),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimens.spaceLg),
            ],
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OcrSourceBottomSheet extends StatelessWidget {
  const _OcrSourceBottomSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppDimens.spaceMd),
      child: GlassCard(
        padding: const EdgeInsets.all(AppDimens.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Capture or Import Document',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _OcrOptionCard(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () => Navigator.pop(context, ImageSource.camera),
                  ),
                ),
                const SizedBox(width: AppDimens.spaceMd),
                Expanded(
                  child: _OcrOptionCard(
                    icon: Icons.photo_library_rounded,
                    label: 'Gallery',
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _OcrOptionCard extends StatelessWidget {
  const _OcrOptionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(AppDimens.radius),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
