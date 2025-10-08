import 'package:flutter/material.dart';

/// Pallet warna aplikasi yang dirancang khusus untuk pengguna dengan gangguan kognitif.
/// Fokus pada warna yang menenangkan dan kontras yang baik untuk keterbacaan.
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

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
}
