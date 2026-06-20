/// Typography styles built on Inter (Latin) + Noto Sans Bengali.
///
/// Both families are loaded via google_fonts in [AppTheme]. Bangla glyphs
/// fall back to Noto Sans Bengali automatically through the fontFamilyFallback
/// list on each style.
library;
import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  /// Latin font used everywhere.
  static const String latinFamily = 'Inter';

  /// Bengali font — included as a fallback so Bangla text renders crisply.
  static const String bengaliFamily = 'Noto Sans Bengali';

  static List<String> get fontFamilyFallback =>
      const [bengaliFamily];

  static const TextStyle display = TextStyle(
    fontFamily: latinFamily,
    fontFamilyFallback: [bengaliFamily],
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: latinFamily,
    fontFamilyFallback: [bengaliFamily],
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static const TextStyle title = TextStyle(
    fontFamily: latinFamily,
    fontFamilyFallback: [bengaliFamily],
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontFamily: latinFamily,
    fontFamilyFallback: [bengaliFamily],
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: latinFamily,
    fontFamilyFallback: [bengaliFamily],
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static const TextStyle translated = TextStyle(
    // Slightly larger for the output card — translations are the star.
    fontFamily: latinFamily,
    fontFamilyFallback: [bengaliFamily],
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static const TextStyle label = TextStyle(
    fontFamily: latinFamily,
    fontFamilyFallback: [bengaliFamily],
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: latinFamily,
    fontFamilyFallback: [bengaliFamily],
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
}
