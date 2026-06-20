/// Centralized color palette for Fluent Translate.
///
/// Pure black/white minimal — no colored accents. Dark mode uses pure black
/// background with white text; light mode is the inverse.
library;
import 'package:flutter/material.dart';

/// Light theme palette.
class LightColors {
  LightColors._();

  static const Color background = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFF5F5F5);
  static const Color primary = Color(0xFF111111);
  static const Color accent = Color(0xFF111111);
  static const Color text = Color(0xFF111111);
  static const Color textSecondary = Color(0xFF888888);
  static const Color border = Color(0xFFE0E0E0);
}

/// Dark theme palette — pure black & white.
class DarkColors {
  DarkColors._();

  static const Color background = Color(0xFF000000);
  static const Color card = Color(0xFF111111);
  static const Color primary = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFFFFFFFF);
  static const Color text = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF888888);
  static const Color border = Color(0xFF222222);
}
