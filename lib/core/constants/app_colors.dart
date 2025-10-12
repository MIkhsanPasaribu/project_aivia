import 'package:flutter/material.dart';

/// Pallet warna aplikasi yang dirancang khusus untuk pengguna dengan gangguan kognitif.
/// Fokus pada warna yang menenangkan dan kontras yang baik untuk keterbacaan.
///
/// Mendukung Light Mode dan Dark Mode dengan prinsip aksesibilitas tinggi.
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // ========================================================================
  // LIGHT MODE COLORS
  // ========================================================================

  // Primary Colors - Sky Blue (Menenangkan)
  static const Color primary = Color(0xFFA8DADC);
  static const Color primaryLight = Color(0xFFD4F1F4);
  static const Color primaryDark = Color(0xFF7DBEC1);

  // Secondary Colors - Soft Green (Keseimbangan)
  static const Color secondary = Color(0xFFB7E4C7);
  static const Color secondaryLight = Color(0xFFDBF3E5);
  static const Color secondaryDark = Color(0xFF8FD4A5);

  // Accent Colors - Warm Sand (Hangat & Aman)
  static const Color accent = Color(0xFFF6E7CB);
  static const Color accentLight = Color(0xFFFFF5E1);
  static const Color accentDark = Color(0xFFE6D4A8);

  // Text Colors - Charcoal Gray (Kontras Tinggi)
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);

  // Background - Ivory White (Lembut)
  static const Color background = Color(0xFFFFFDF5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8F6ED);

  // Semantic Colors (Status & Feedback)
  static const Color success = Color(0xFF81C784); // Hijau lembut
  static const Color warning = Color(0xFFFFB74D); // Orange lembut
  static const Color error = Color(0xFFE57373); // Merah lembut
  static const Color info = Color(0xFF64B5F6); // Biru info lembut

  // Emergency - Lebih mencolok untuk perhatian
  static const Color emergency = Color(0xFFD32F2F);
  static const Color emergencyLight = Color(0xFFEF5350);

  // Utility
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1A000000);
  static const Color disabled = Color(0xFFBDBDBD);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondary, secondaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ========================================================================
  // DARK MODE COLORS
  // ========================================================================
  // Dirancang dengan prinsip:
  // - Kontras minimum 7:1 (WCAG AAA)
  // - Tidak menyilaukan (no pure black/white)
  // - Tetap menenangkan untuk pasien Alzheimer
  // - Konsisten dengan brand identity

  // Primary Colors - Soft Cyan (Tetap menenangkan di dark bg)
  static const Color primaryDarkDM = Color(0xFF7DD3E0);
  static const Color primaryLightDM = Color(0xFF5FC5D4);
  static const Color primaryDarkerDM = Color(0xFF9FE1E9);

  // Secondary Colors - Soft Mint (Keseimbangan di malam hari)
  static const Color secondaryDarkDM = Color(0xFF88D9A4);
  static const Color secondaryLightDM = Color(0xFF6DC98D);
  static const Color secondaryDarkerDM = Color(0xFFA3E3B8);

  // Accent Colors - Warm Gold (Hangat tapi tidak silau)
  static const Color accentDarkDM = Color(0xFFE8D08F);
  static const Color accentLightDM = Color(0xFFD9C078);
  static const Color accentDarkerDM = Color(0xFFF0DCA5);

  // Text Colors - Off-White & Grays (Tidak menyilaukan)
  static const Color textPrimaryDarkDM = Color(0xFFE8EAF0); // Off-white
  static const Color textSecondaryDarkDM = Color(0xFFB8BAC5); // Light gray
  static const Color textTertiaryDarkDM = Color(0xFF8A8C97); // Medium gray

  // Background - Dark Blue-Gray (Bukan hitam pekat)
  static const Color backgroundDarkDM = Color(0xFF121826); // Deep blue-gray
  static const Color surfaceDarkDM = Color(0xFF1E2838); // Slightly lighter
  static const Color surfaceVariantDarkDM = Color(0xFF2A3545); // More lighter

  // Semantic Colors - Dark Mode Variants (Lebih vibrant)
  static const Color successDarkDM = Color(0xFF66BB6A); // Hijau cerah
  static const Color warningDarkDM = Color(0xFFFFA726); // Orange cerah
  static const Color errorDarkDM = Color(0xFFEF5350); // Merah cerah
  static const Color infoDarkDM = Color(0xFF42A5F5); // Biru cerah

  // Emergency - Tetap mencolok di dark mode
  static const Color emergencyDarkDM = Color(0xFFFF5252);
  static const Color emergencyLightDarkDM = Color(0xFFFF6E6E);

  // Utility Dark Mode
  static const Color dividerDarkDM = Color(0xFF3A4556);
  static const Color shadowDarkDM = Color(0x40000000); // Lebih gelap
  static const Color disabledDarkDM = Color(0xFF5A5E6B);

  // Gradients Dark Mode
  static const LinearGradient primaryGradientDarkDM = LinearGradient(
    colors: [primaryDarkDM, primaryDarkerDM],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradientDarkDM = LinearGradient(
    colors: [secondaryDarkDM, secondaryDarkerDM],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Extension untuk mendapatkan warna berdasarkan brightness
extension AppColorsExtension on AppColors {
  /// Mendapatkan primary color berdasarkan brightness
  static Color getPrimary(Brightness brightness) {
    return brightness == Brightness.dark
        ? AppColors.primaryDarkDM
        : AppColors.primary;
  }

  /// Mendapatkan background color berdasarkan brightness
  static Color getBackground(Brightness brightness) {
    return brightness == Brightness.dark
        ? AppColors.backgroundDarkDM
        : AppColors.background;
  }

  /// Mendapatkan surface color berdasarkan brightness
  static Color getSurface(Brightness brightness) {
    return brightness == Brightness.dark
        ? AppColors.surfaceDarkDM
        : AppColors.surface;
  }

  /// Mendapatkan text primary color berdasarkan brightness
  static Color getTextPrimary(Brightness brightness) {
    return brightness == Brightness.dark
        ? AppColors.textPrimaryDarkDM
        : AppColors.textPrimary;
  }
}
