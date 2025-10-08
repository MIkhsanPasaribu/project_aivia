import 'package:project_aivia/core/constants/app_strings.dart';

/// Validator untuk form input
class Validators {
  Validators._(); // Private constructor

  /// Validasi email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.emailRequired;
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return AppStrings.emailInvalid;
    }

    return null;
  }

  /// Validasi password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.passwordRequired;
    }

    if (value.length < 8) {
      return AppStrings.passwordTooShort;
    }

    return null;
  }

  /// Validasi konfirmasi password
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return AppStrings.passwordRequired;
    }

    if (value != password) {
      return AppStrings.passwordNotMatch;
    }

    return null;
  }

  /// Validasi nama
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.nameRequired;
    }

    if (value.trim().length < 2) {
      return 'Nama minimal 2 karakter';
    }

    return null;
  }

  /// Validasi required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName harus diisi';
    }
    return null;
  }

  /// Validasi nama aktivitas
  static String? validateActivityName(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.activityNameRequired;
    }

    if (value.trim().isEmpty) {
      return AppStrings.activityNameRequired;
    }

    return null;
  }
}
