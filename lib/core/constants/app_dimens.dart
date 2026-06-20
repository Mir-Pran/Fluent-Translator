/// Spacing, radii, and sizing constants used across the app.
///
/// Keeping these in one place makes the UI consistent and easy to tweak
/// without hunting through widget files.
class AppDimens {
  AppDimens._();

  // Spacing
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double space = 12;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;

  // Radii
  static const double radiusSm = 8;
  static const double radius = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 28;

  // Cards / inputs
  static const double cardElevation = 0;
  static const double inputMinHeight = 140;
  static const double outputMinHeight = 120;
  static const double translateButtonHeight = 56;

  // Top bar
  static const double topBarHeight = 60;

  // Bottom navigation
  static const double bottomNavHeight = 72;
  static const double bottomNavBlur = 20;

  // Animations (PRD: 150-250ms)
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration duration = Duration(milliseconds: 200);
  static const Duration durationSlow = Duration(milliseconds: 250);

  // Translate
  static const int maxInputChars = 5000;

  // Glassmorphism
  static const double glassOpacityLight = 0.85;
  static const double glassOpacityDark = 0.60;
}
