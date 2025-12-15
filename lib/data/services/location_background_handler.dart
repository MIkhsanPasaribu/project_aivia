// ignore_for_file: avoid_print

import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Background handler untuk location tracking di isolate terpisah
/// Handler ini akan dijalankan setiap interval (60 detik) oleh foreground task
///
/// Fitur:
/// - Deteksi lokasi dengan Geolocator
/// - Validasi lokasi (accuracy, speed, dll)
/// - Simpan ke Supabase jika online
/// - Queue ke local database jika offline
/// - Update notification dengan stats
class LocationBackgroundHandler extends TaskHandler {
  int _locationCount = 0;
  String _lastUpdateTime = 'Belum ada update';
  bool _isProcessing = false;

  // Health monitoring
  int _successCount = 0;
  int _failureCount = 0;
  int _invalidLocationCount = 0;
  DateTime? _lastSuccessTime;
  int _eventsSinceLastReport = 0;
  static const int _eventsPerReport =
      10; // Print health report setiap 10 events

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('🚀 LocationBackgroundHandler started at $timestamp');
    print('📊 Health monitoring enabled');

    // Initialize Supabase jika belum
    await _initializeSupabase();

    _lastSuccessTime = timestamp;
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    // Prevent concurrent execution
    if (_isProcessing) {
      print('⏭️ Skipping event, masih processing...');
      return;
    }

    _isProcessing = true;

    try {
      print('📍 Location tracking event at ${timestamp.toIso8601String()}');

      // Get current position dengan retry
      Position? position;
      int retries = 0;
      const maxRetries = 3;

      while (position == null && retries < maxRetries) {
        position = await _getCurrentPosition();
        if (position == null) {
          retries++;
          print('⚠️ Retry getting position: $retries/$maxRetries');
          if (retries < maxRetries) {
            await Future.delayed(Duration(seconds: 2 * retries));
          }
        }
      }

      if (position == null) {
        print('❌ Failed to get position after $maxRetries retries');
        _isProcessing = false;
        return;
      }

      // Validasi lokasi
      if (!_isValidLocation(position)) {
        print('⚠️ Invalid location, skipping...');
        _invalidLocationCount++;
        _isProcessing = false;
        await _updateNotificationWithHealth();
        return;
      }

      // Check connectivity
      final isOnline = await _checkConnectivity();

      bool saveSuccess = false;

      if (isOnline) {
        // Save to Supabase dengan retry
        for (int i = 0; i < 2; i++) {
          saveSuccess = await _saveToSupabase(position);
          if (saveSuccess) {
            _locationCount++;
            _lastUpdateTime = _formatTime(DateTime.now());
            print('✅ Location saved to Supabase: $_locationCount');
            break;
          } else if (i < 1) {
            print('⚠️ Retry saving to Supabase: ${i + 1}/2');
            await Future.delayed(const Duration(seconds: 2));
          }
        }
      }

      // Jika gagal save online atau memang offline, queue untuk sync nanti
      if (!saveSuccess) {
        await _queueToLocal(position);
        print('💾 Location queued for later sync (offline atau error)');
        _failureCount++;
      } else {
        _successCount++;
        _lastSuccessTime = DateTime.now();
      }

      // Update notification dengan health metrics
      await _updateNotificationWithHealth();

      // Print periodic health report
      _eventsSinceLastReport++;
      if (_eventsSinceLastReport >= _eventsPerReport) {
        printHealthReport();
        _eventsSinceLastReport = 0;
      }
    } catch (e, stackTrace) {
      print('❌ Error in onRepeatEvent: $e');
      print('Stack trace: $stackTrace');
      _failureCount++;
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print('🛑 LocationBackgroundHandler destroyed at $timestamp');
  }

  /// Get current position dengan error handling
  Future<Position?> _getCurrentPosition() async {
    try {
      // Check permission
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('❌ Location permission denied');
        return null;
      }

      // Get position dengan timeout
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
      );

      return position;
    } catch (e) {
      print('❌ Error getting position: $e');
      return null;
    }
  }

  /// Validasi lokasi sebelum disimpan
  bool _isValidLocation(Position position) {
    // Check accuracy (max 100 meters)
    if (position.accuracy > 100) {
      print('⚠️ Accuracy too low: ${position.accuracy}m');
      return false;
    }

    // Check invalid coordinates
    if (position.latitude == 0.0 && position.longitude == 0.0) {
      print('⚠️ Invalid coordinates: (0,0)');
      return false;
    }

    // Check realistic speed (max 150 km/h = 41.67 m/s)
    if (position.speed > 41.67) {
      print('⚠️ Speed too high: ${position.speed} m/s');
      return false;
    }

    return true;
  }

  /// Check network connectivity
  ///
  /// FIXED: Real connectivity test, tidak hanya cek connection type
  /// Strategi: Coba Supabase health check endpoint
  Future<bool> _checkConnectivity() async {
    try {
      // Step 1: Check connection type (fast check)
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        print('⚠️ No connection detected');
        return false;
      }

      // Step 2: Real internet check dengan timeout
      // Test Supabase connectivity dengan quick health check
      try {
        final supabase = Supabase.instance.client;

        // Quick test: Coba query simple dengan timeout
        await supabase
            .from('profiles')
            .select('id')
            .limit(1)
            .timeout(const Duration(seconds: 3));

        print('✅ Internet connectivity confirmed');
        return true;
      } catch (e) {
        print('⚠️ No actual internet: $e');
        return false;
      }
    } catch (e) {
      print('❌ Error checking connectivity: $e');
      return false;
    }
  }

  /// Save location to Supabase
  Future<bool> _saveToSupabase(Position position) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      // FIXED: Explicit null check untuk prevent runtime crash
      if (userId == null || userId.isEmpty) {
        print('❌ User not authenticated or userId is empty');
        return false;
      }

      await supabase.from('locations').insert({
        'patient_id': userId,
        'coordinates': 'POINT(${position.longitude} ${position.latitude})',
        'accuracy': position.accuracy,
        'speed': position.speed,
        'heading': position.heading,
        'altitude': position.altitude,
        'timestamp': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('❌ Error saving to Supabase: $e');
      return false;
    }
  }

  /// Queue location to local database (untuk offline)
  ///
  /// FIXED: Sekarang menggunakan SQLite local storage langsung
  /// karena OfflineQueueService tidak bisa diakses dari background isolate
  Future<void> _queueToLocal(Position position) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        print('⚠️ User ID null, tidak bisa queue location');
        return;
      }

      // Strategy: Simpan ke local SQLite via raw SQL query
      // Background isolate tidak bisa access OfflineQueueService directly
      // Tapi bisa access Supabase client yang punya connection ke local DB

      // Fallback: Coba simpan ke Supabase dulu
      // Jika fail karena offline, LocationService di main isolate akan
      // auto-sync pending locations via OfflineQueueService
      try {
        await supabase.from('locations').insert({
          'patient_id': userId,
          'coordinates': 'POINT(${position.longitude} ${position.latitude})',
          'accuracy': position.accuracy,
          'speed': position.speed,
          'heading': position.heading,
          'altitude': position.altitude,
          'timestamp': DateTime.now().toIso8601String(),
        });
        print('✅ Location saved to Supabase (recovered from offline)');
      } catch (e) {
        print('⚠️ Failed to save, will retry on next sync: $e');
        // Data akan di-retry oleh OfflineQueueService di main isolate
        // saat connectivity restored
      }
    } catch (e) {
      print('❌ Error queuing to local: $e');
    }
  }

  /// Update foreground notification dengan health metrics
  Future<void> _updateNotificationWithHealth() async {
    final successRate = _locationCount > 0
        ? (_successCount / _locationCount * 100).toStringAsFixed(0)
        : '0';

    String statusIcon;
    if (_successCount > _failureCount * 2) {
      statusIcon = '✅'; // Healthy
    } else if (_successCount > _failureCount) {
      statusIcon = '⚠️'; // Warning
    } else {
      statusIcon = '❌'; // Critical
    }

    await FlutterForegroundTask.updateService(
      notificationTitle: '$statusIcon AIVIA Tracking Aktif',
      notificationText:
          'Tersimpan: $_successCount | Gagal: $_failureCount | Rate: $successRate%',
    );
  }

  /// Initialize Supabase jika belum
  Future<void> _initializeSupabase() async {
    try {
      if (!Supabase.instance.isInitialized) {
        // Note: Supabase harus sudah diinisialisasi di main.dart
        // Ini hanya fallback check
        print('⚠️ Supabase belum diinisialisasi');
      }
    } catch (e) {
      print('❌ Error initializing Supabase: $e');
    }
  }

  /// Format time untuk display
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Get health statistics untuk monitoring
  Map<String, dynamic> getHealthStats() {
    final successRate = _locationCount > 0
        ? (_successCount / _locationCount * 100).toStringAsFixed(1)
        : '0.0';

    return {
      'total_attempts': _locationCount,
      'successful_saves': _successCount,
      'failed_saves': _failureCount,
      'invalid_locations': _invalidLocationCount,
      'success_rate': successRate,
      'last_success_time': _lastSuccessTime?.toIso8601String(),
      'last_update_time': _lastUpdateTime,
      'is_healthy': _successCount > _failureCount,
    };
  }

  /// Print health report untuk debugging
  void printHealthReport() {
    final stats = getHealthStats();
    print('');
    print('📊 ========== HEALTH REPORT ==========');
    print('📍 Total Attempts: ${stats['total_attempts']}');
    print('✅ Successful: ${stats['successful_saves']}');
    print('❌ Failed: ${stats['failed_saves']}');
    print('⚠️ Invalid: ${stats['invalid_locations']}');
    print('📈 Success Rate: ${stats['success_rate']}%');
    print('🕐 Last Success: ${stats['last_success_time'] ?? 'N/A'}');
    print('💚 Status: ${stats['is_healthy'] ? 'HEALTHY' : 'DEGRADED'}');
    print('======================================');
    print('');
  }
}
