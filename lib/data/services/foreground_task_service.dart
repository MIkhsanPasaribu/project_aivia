// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_aivia/data/services/location_background_handler.dart';

/// Service untuk mengelola foreground task dengan flutter_foreground_task
/// Fitur:
/// - Persistent notification saat tracking aktif
/// - Auto-restart setelah reboot
/// - Battery efficient dengan callback interval
/// - State persistence dengan SharedPreferences
class ForegroundTaskService {
  static const String _trackingStateKey = 'is_tracking_active';
  static const String _trackingModeKey = 'tracking_mode';
  static const String _patientIdKey = 'tracking_patient_id';

  /// Initialize foreground task configuration
  static Future<void> initialize() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'aivia_location_tracking',
        channelName: 'Pelacakan Lokasi AIVIA',
        channelDescription: 'Notifikasi pelacakan lokasi untuk keamanan pasien',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(
          60000,
        ), // 1 menit interval
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  /// Start foreground task dengan tracking mode yang dipilih
  static Future<bool> start({
    required String patientId,
    required String trackingMode,
  }) async {
    // Pastikan task belum berjalan
    if (await FlutterForegroundTask.isRunningService) {
      print('⚠️ Foreground task sudah berjalan');
      return false;
    }

    // Simpan state untuk auto-restart
    await _saveTrackingState(
      isActive: true,
      mode: trackingMode,
      patientId: patientId,
    );

    // Start foreground task
    await FlutterForegroundTask.startService(
      notificationTitle: 'AIVIA Pelacakan Aktif',
      notificationText: 'Melacak lokasi untuk keamanan Anda',
      notificationIcon: null, // Use default app icon
      callback: startLocationBackgroundHandler,
    );

    // Check if service actually started
    final isRunning = await FlutterForegroundTask.isRunningService;
    print('✅ Foreground task started: $isRunning');
    return isRunning;
  }

  /// Stop foreground task
  static Future<bool> stop() async {
    if (!await FlutterForegroundTask.isRunningService) {
      print('⚠️ Foreground task tidak berjalan');
      return false;
    }

    // Hapus state
    await _saveTrackingState(isActive: false, mode: '', patientId: '');

    // Stop service
    await FlutterForegroundTask.stopService();
    print('✅ Foreground task stopped');
    return true;
  }

  /// Update notification dengan stats terbaru
  static Future<void> updateNotification({
    required int locationCount,
    required String lastUpdateTime,
    required double batteryLevel,
  }) async {
    if (!await FlutterForegroundTask.isRunningService) {
      return;
    }

    await FlutterForegroundTask.updateService(
      notificationTitle: 'AIVIA Pelacakan Aktif',
      notificationText:
          'Lokasi: $locationCount | Update: $lastUpdateTime | Baterai: ${batteryLevel.toStringAsFixed(0)}%',
    );
  }

  /// Check apakah tracking sedang aktif
  static Future<bool> isTrackingActive() async {
    return await FlutterForegroundTask.isRunningService;
  }

  /// Restore tracking state setelah reboot
  static Future<bool> restoreTrackingState() async {
    final prefs = await SharedPreferences.getInstance();
    final isActive = prefs.getBool(_trackingStateKey) ?? false;

    if (!isActive) {
      print('ℹ️ Tracking tidak aktif sebelum reboot');
      return false;
    }

    final mode = prefs.getString(_trackingModeKey) ?? 'balanced';
    final patientId = prefs.getString(_patientIdKey);

    if (patientId == null || patientId.isEmpty) {
      print('⚠️ Patient ID tidak ditemukan untuk restore');
      return false;
    }

    print('🔄 Restoring tracking: mode=$mode, patientId=$patientId');

    // Restart tracking
    return await start(patientId: patientId, trackingMode: mode);
  }

  /// Simpan tracking state ke SharedPreferences
  static Future<void> _saveTrackingState({
    required bool isActive,
    required String mode,
    required String patientId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_trackingStateKey, isActive);
    await prefs.setString(_trackingModeKey, mode);
    await prefs.setString(_patientIdKey, patientId);
  }

  /// Get tracking state untuk debugging
  static Future<Map<String, dynamic>> getTrackingState() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'is_active': prefs.getBool(_trackingStateKey) ?? false,
      'mode': prefs.getString(_trackingModeKey) ?? 'unknown',
      'patient_id': prefs.getString(_patientIdKey) ?? 'unknown',
      'is_service_running': await FlutterForegroundTask.isRunningService,
    };
  }
}

/// Top-level callback function untuk foreground task
/// WAJIB di top-level (tidak bisa di dalam class)
@pragma('vm:entry-point')
void startLocationBackgroundHandler() {
  // This function is called when the foreground service starts
  // Setup the TaskHandler
  FlutterForegroundTask.setTaskHandler(LocationBackgroundHandler());
}
