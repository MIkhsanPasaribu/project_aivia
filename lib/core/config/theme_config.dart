import 'package:flutter/material.dart';
import 'package:project_aivia/core/constants/app_colors.dart';
import 'package:project_aivia/core/constants/app_dimensions.dart';

/// Konfigurasi tema aplikasi
/// Mendukung Light Mode dan Dark Mode dengan aksesibilitas tinggi
class ThemeConfig {
  ThemeConfig._(); // Private constructor

  /// Light theme - tema utama aplikasi
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // Color Scheme
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textPrimary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textPrimary,
        secondaryContainer: AppColors.secondaryLight,
        tertiary: AppColors.accent,
        error: AppColors.error,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceVariant,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.background,

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontXL,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontHeadline,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontTitle,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontXXL,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontXL,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontL,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontM,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontL,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontM,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontS,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontM,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: AppDimensions.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        ),
        margin: const EdgeInsets.all(AppDimensions.paddingM),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(
            AppDimensions.buttonMinWidth,
            AppDimensions.buttonHeightM,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingL,
            vertical: AppDimensions.paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: AppDimensions.fontM,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: AppDimensions.fontM,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontM,
          color: AppColors.textSecondary,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontM,
          color: AppColors.textTertiary,
        ),
        errorStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontS,
          color: AppColors.error,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.emergency,
        foregroundColor: Colors.white,
        elevation: AppDimensions.elevationM,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontS,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontS,
          fontWeight: FontWeight.normal,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: AppDimensions.elevationM,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: AppDimensions.paddingM,
      ),
    );
  }

  /// Dark theme - tema untuk mode gelap
  /// Dirancang khusus untuk:
  /// - Mengurangi kelelahan mata di malam hari
  /// - Tetap menenangkan untuk pasien Alzheimer
  /// - Kontras minimum 7:1 (WCAG AAA compliance)
  /// - Tidak menggunakan pure black (lebih lembut)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color Scheme - Dark Mode
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryDarkDM,
        onPrimary: AppColors.textPrimaryDarkDM,
        primaryContainer: AppColors.primaryDarkerDM,
        secondary: AppColors.secondaryDarkDM,
        onSecondary: AppColors.textPrimaryDarkDM,
        secondaryContainer: AppColors.secondaryDarkerDM,
        tertiary: AppColors.accentDarkDM,
        error: AppColors.errorDarkDM,
        onError: AppColors.textPrimaryDarkDM,
        surface: AppColors.surfaceDarkDM,
        onSurface: AppColors.textPrimaryDarkDM,
        surfaceContainerHighest: AppColors.surfaceVariantDarkDM,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColors.backgroundDarkDM,

      // App Bar Theme
      appBarTheme: AppBarThemeData(
        backgroundColor: AppColors.surfaceDarkDM,
        foregroundColor: AppColors.textPrimaryDarkDM,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontXL,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDarkDM,
        ),
      ),

      // Text Theme - Dark Mode
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontHeadline,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryDarkDM,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontTitle,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryDarkDM,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontXXL,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDarkDM,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontXL,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDarkDM,
        ),
        titleLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontL,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDarkDM,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontM,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryDarkDM,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontL,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimaryDarkDM,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontM,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimaryDarkDM,
        ),
        bodySmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontS,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondaryDarkDM,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontM,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryDarkDM,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surfaceDarkDM,
        elevation: AppDimensions.cardElevation,
        shadowColor: AppColors.shadowDarkDM,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        ),
        margin: const EdgeInsets.all(AppDimensions.paddingM),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDarkDM,
          foregroundColor: AppColors.textPrimaryDarkDM,
          minimumSize: const Size(
            AppDimensions.buttonMinWidth,
            AppDimensions.buttonHeightM,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingL,
            vertical: AppDimensions.paddingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: AppDimensions.fontM,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDarkDM,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: AppDimensions.fontM,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariantDarkDM,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingM,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: const BorderSide(color: AppColors.dividerDarkDM),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: const BorderSide(color: AppColors.dividerDarkDM),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: const BorderSide(
            color: AppColors.primaryDarkDM,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: const BorderSide(color: AppColors.errorDarkDM),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          borderSide: const BorderSide(color: AppColors.errorDarkDM, width: 2),
        ),
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontM,
          color: AppColors.textSecondaryDarkDM,
        ),
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontM,
          color: AppColors.textTertiaryDarkDM,
        ),
        errorStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontS,
          color: AppColors.errorDarkDM,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.emergencyDarkDM,
        foregroundColor: AppColors.textPrimaryDarkDM,
        elevation: AppDimensions.elevationM,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDarkDM,
        selectedItemColor: AppColors.primaryDarkDM,
        unselectedItemColor: AppColors.textTertiaryDarkDM,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontS,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontS,
          fontWeight: FontWeight.normal,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: AppDimensions.elevationM,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDarkDM,
        thickness: 1,
        space: AppDimensions.paddingM,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDarkDM,
        elevation: AppDimensions.elevationL,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceVariantDarkDM,
        contentTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontM,
          color: AppColors.textPrimaryDarkDM,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariantDarkDM,
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppDimensions.fontS,
          color: AppColors.textPrimaryDarkDM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
      ),
    );
  }
}
