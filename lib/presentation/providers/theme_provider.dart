import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider untuk mengelola theme mode aplikasi
/// Mendukung Light Mode, Dark Mode, dan System (auto)
///
/// Theme preference disimpan secara persisten menggunakan SharedPreferences

// Key untuk SharedPreferences
const String _themeModeKey = 'theme_mode_preference';

/// State class untuk theme mode
class ThemeModeState {
  final ThemeMode themeMode;
  final bool isLoading;

  const ThemeModeState({required this.themeMode, this.isLoading = false});

  ThemeModeState copyWith({ThemeMode? themeMode, bool? isLoading}) {
    return ThemeModeState(
      themeMode: themeMode ?? this.themeMode,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier untuk theme mode
class ThemeModeNotifier extends StateNotifier<ThemeModeState> {
  ThemeModeNotifier()
    : super(const ThemeModeState(themeMode: ThemeMode.system)) {
    _loadThemeMode();
  }

  /// Load theme mode dari SharedPreferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeModeString = prefs.getString(_themeModeKey);

      if (themeModeString != null) {
        final themeMode = _parseThemeMode(themeModeString);
        state = state.copyWith(themeMode: themeMode);
      }
    } catch (e) {
      debugPrint('Error loading theme mode: $e');
      // Jika error, gunakan system default
      state = state.copyWith(themeMode: ThemeMode.system);
    }
  }

  /// Parse string ke ThemeMode enum
  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }

  /// Convert ThemeMode enum ke string
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Set theme mode dan simpan ke SharedPreferences
  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      state = state.copyWith(isLoading: true);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, _themeModeToString(mode));

      state = state.copyWith(themeMode: mode, isLoading: false);

      debugPrint('Theme mode changed to: ${_themeModeToString(mode)}');
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  /// Toggle antara light dan dark mode
  /// (System mode akan menjadi light)
  Future<void> toggleTheme() async {
    final newMode = state.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  /// Set ke light mode
  Future<void> setLightMode() async {
    await setThemeMode(ThemeMode.light);
  }

  /// Set ke dark mode
  Future<void> setDarkMode() async {
    await setThemeMode(ThemeMode.dark);
  }

  /// Set ke system mode (follow device setting)
  Future<void> setSystemMode() async {
    await setThemeMode(ThemeMode.system);
  }

  /// Check apakah sedang menggunakan dark mode
  /// (termasuk system mode yang sedang dark)
  bool isDarkMode(BuildContext context) {
    if (state.themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return state.themeMode == ThemeMode.dark;
  }
}

/// Provider untuk theme mode state
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeModeState>((ref) {
      return ThemeModeNotifier();
    });

/// Helper provider untuk mendapatkan ThemeMode langsung
final currentThemeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeModeProvider).themeMode;
});

/// Helper provider untuk check apakah dark mode aktif
final isDarkModeProvider = Provider.family<bool, BuildContext>((ref, context) {
  final themeModeNotifier = ref.watch(themeModeProvider.notifier);
  return themeModeNotifier.isDarkMode(context);
});
