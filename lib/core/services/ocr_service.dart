import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  static final ImagePicker _picker = ImagePicker();

  /// Picks an image from camera or gallery and performs OCR.
  /// Returns the extracted text, or null if cancelled/failed.
  static Future<String?> recognizeText({
    required ImageSource source,
    String? sourceLanguageCode,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (image == null) return null;

      final inputImage = InputImage.fromFilePath(image.path);
      final script = _getScriptForLanguage(sourceLanguageCode ?? 'en');
      
      final textRecognizer = TextRecognizer(script: script);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      return recognizedText.text.trim();
    } catch (e) {
      // Return null or handle the error
      return null;
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
