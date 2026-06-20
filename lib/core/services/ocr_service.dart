import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  static final ImagePicker _picker = ImagePicker();

  /// Picks an image from camera or gallery and performs OCR.
  /// Returns the extracted text, or null if cancelled by user.
  /// Throws on actual errors (camera denied, OCR failure, etc.)
  static Future<String?> recognizeText({
    required ImageSource source,
    String? sourceLanguageCode,
  }) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1080,
    );
    if (image == null) return null; // user cancelled

    if (!await File(image.path).exists()) {
      throw Exception('Image file not found. Try again.');
    }

    try {
      final inputImage = InputImage.fromFilePath(image.path);
      final script = _getScriptForLanguage(sourceLanguageCode ?? 'en');

      final textRecognizer = TextRecognizer(script: script);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      final text = recognizedText.text.trim();
      if (text.isEmpty) {
        throw Exception('No text could be recognized from the image.');
      }
      return text;
    } catch (e) {
      debugPrint('OCR error: $e');
      rethrow;
    }
  }

  static TextRecognitionScript _getScriptForLanguage(String langCode) {
    switch (langCode.toLowerCase()) {
      case 'zh':
      case 'zh-cn':
      case 'zh-tw':
        return TextRecognitionScript.chinese;
      case 'hi':
      case 'mr':
        return TextRecognitionScript.devanagiri;
      case 'ja':
        return TextRecognitionScript.japanese;
      case 'ko':
        return TextRecognitionScript.korean;
      default:
        return TextRecognitionScript.latin;
    }
  }
}
