import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider untuk notification settings dengan SharedPreferences persistence
///
/// Features:
/// - Get/set notification enabled status
/// - Persist across app restarts
/// - Reactive updates

const String _notificationEnabledKey = 'notification_enabled';

/// Provider untuk notification enabled status
final notificationEnabledProvider =
    StateNotifierProvider<NotificationSettingsNotifier, bool>((ref) {
      return NotificationSettingsNotifier();
    });

class NotificationSettingsNotifier extends StateNotifier<bool> {
  NotificationSettingsNotifier() : super(true) {
    _loadSettings();
  }

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_notificationEnabledKey) ?? true;
      state = enabled;
    } catch (e) {
      // If error, default to true
      state = true;
    }
  }

  /// Toggle notification enabled status
  Future<void> toggle() async {
    final newValue = !state;
    await setEnabled(newValue);
  }

  /// Set notification enabled status
  Future<void> setEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationEnabledKey, enabled);
      state = enabled;
    } catch (e) {
      // Ignore errors for now
    }
  }
}
