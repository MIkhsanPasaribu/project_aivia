/// Konstanta untuk dimensi dan spacing aplikasi
class AppDimensions {
  AppDimensions._(); // Private constructor

  // Padding & Margin
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;

  // Border Radius
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusXXL = 24.0;
  static const double radiusCircle = 999.0;

  // Icon Sizes
  static const double iconXS = 16.0;
  static const double iconS = 20.0;
  static const double iconM = 24.0;
  static const double iconL = 32.0;
  static const double iconXL = 48.0;
  static const double iconXXL = 64.0;

  // Button Sizes
  static const double buttonHeightS = 40.0;
  static const double buttonHeightM = 48.0;
  static const double buttonHeightL = 56.0;
  static const double buttonMinWidth = 88.0;

  // Touch Target (Minimum untuk aksesibilitas)
  static const double touchTargetMin = 48.0;

  // Font Sizes
  static const double fontXS = 12.0;
  static const double fontS = 14.0;
  static const double fontM = 16.0;
  static const double fontL = 18.0;
  static const double fontXL = 20.0;
  static const double fontXXL = 24.0;
  static const double fontTitle = 28.0;
  static const double fontHeadline = 32.0;

  // Elevation
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;
  static const double elevationXL = 12.0;

  // Card
  static const double cardElevation = 2.0;
  static const double cardRadius = 12.0;

  // Bottom Navigation
  static const double bottomNavHeight = 64.0;

  // App Bar
  static const double appBarHeight = 56.0;

  // Aliases untuk backward compatibility
  static const double paddingSmall = paddingS;
  static const double paddingMedium = paddingM;
  static const double paddingLarge = paddingL;
  static const double borderRadiusSmall = radiusS;
  static const double borderRadiusMedium = radiusM;
  static const double borderRadiusLarge = radiusL;
}
