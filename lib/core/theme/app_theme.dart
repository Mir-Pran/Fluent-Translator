/// App theme: builds light and dark [ThemeData] from a black/white palette.
///
/// Fonts (Inter + Noto Sans Bengali) are loaded via google_fonts and applied
/// globally as the default font; Bangla glyphs render through the fallback
/// list declared on each text style in [AppTextStyles].
library;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimens.dart';
import '../constants/app_text_styles.dart';

class AppTheme {
  AppTheme._();

  /// Ensure google_fonts has finished resolving before first paint.
  /// Safe to call multiple times.
  static Future<void> preloadFonts() async {
    await GoogleFonts.pendingFonts();
  }

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colors = isDark
        ? (
            background: DarkColors.background,
            card: DarkColors.card,
            primary: DarkColors.primary,
            accent: DarkColors.accent,
            text: DarkColors.text,
            textSecondary: DarkColors.textSecondary,
            border: DarkColors.border,
          )
        : (
            background: LightColors.background,
            card: LightColors.card,
            primary: LightColors.primary,
            accent: LightColors.accent,
            text: LightColors.text,
            textSecondary: LightColors.textSecondary,
            border: LightColors.border,
          );

    // In dark mode primary=white so onPrimary=black; light mode primary=black
    // so onPrimary=white.
    final onPrimary = isDark ? Colors.black : Colors.white;

    final scheme = ColorScheme(
      primary: colors.primary,
      secondary: colors.accent,
      surface: colors.card,
      onPrimary: onPrimary,
      onSecondary: onPrimary,
      onSurface: colors.text,
      brightness: brightness,
      error: const Color(0xFFEF4444),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      brightness: brightness,
      textTheme: GoogleFonts.interTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ).copyWith(
        displayLarge: AppTextStyles.display,
        headlineMedium: AppTextStyles.headline,
        titleLarge: AppTextStyles.title,
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.bodyMedium,
        labelLarge: AppTextStyles.label,
        bodySmall: AppTextStyles.caption,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: colors.text,
        titleTextStyle: AppTextStyles.title.copyWith(color: colors.text),
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        elevation: AppDimens.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radius),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        hintStyle: AppTextStyles.body.copyWith(color: colors.textSecondary),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colors.textSecondary,
          shape: const CircleBorder(),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colors.border,
        thickness: 1,
        space: 1,
      ),
      splashFactory: InkRipple.splashFactory,
      splashColor: colors.primary.withValues(alpha: 0.08),
      highlightColor: colors.primary.withValues(alpha: 0.04),
    );
  }
}
