# Rancangan Implementasi: Perbaikan Fitur Tracking Patient

**Tanggal**: 15 Desember 2025  
**Proyek**: AIVIA - Aplikasi Asisten Alzheimer  
**Sprint**: Background Tracking Fix  
**Durasi Estimasi**: 3-5 hari kerja  
**Teknologi**: Flutter + Geolocator + Flutter Foreground Task (100% GRATIS)

---

## 📋 TODO List Lengkap

### Phase 1: Critical Fixes (Hari 1-2) 🔴 PRIORITY

#### Sprint 1.1: Foreground Task Service Implementation

- [ ] **Task 1.1.1**: Setup flutter_foreground_task configuration

  - [ ] Create `lib/data/services/foreground_task_service.dart`
  - [ ] Initialize FlutterForegroundTask dengan proper configuration
  - [ ] Configure Android notification options (channel, importance, icon)
  - [ ] Configure iOS notification options (jika diperlukan)
  - [ ] Set foreground task options (interval, autoRunOnBoot, wakeLock)
  - [ ] Test: flutter analyze bersih

- [ ] **Task 1.1.2**: Implement ForegroundTaskService class

  - [ ] Create method `initialize()` untuk setup service
  - [ ] Create method `start()` dengan parameter patientId dan mode
  - [ ] Create method `stop()` untuk cleanup
  - [ ] Implement state management (SharedPreferences untuk persist tracking state)
  - [ ] Implement notification update dengan dynamic content
  - [ ] Add logging dan error handling
  - [ ] Test: flutter analyze bersih

- [ ] **Task 1.1.3**: Implement LocationBackgroundHandler

  - [ ] Create `lib/data/services/location_background_handler.dart`
  - [ ] Extend TaskHandler dari flutter_foreground_task
  - [ ] Implement `onStart()` - initialize services
  - [ ] Implement `onRepeatEvent()` - periodic location update
  - [ ] Implement `onDestroy()` - cleanup resources
  - [ ] Integrate dengan existing LocationService logic
  - [ ] Test: flutter analyze bersih

- [ ] **Task 1.1.4**: Background callback function

  - [ ] Create top-level callback function dengan @pragma('vm:entry-point')
  - [ ] Setup TaskHandler registration
  - [ ] Test isolate communication (SendPort)
  - [ ] Test: flutter analyze bersih

- [ ] **Task 1.1.5**: Integrate dengan LocationService

  - [ ] Modify `LocationService.startTracking()` untuk use foreground service
  - [ ] Modify `LocationService.stopTracking()` untuk stop foreground service
  - [ ] Update tracking state management
  - [ ] Maintain backward compatibility
  - [ ] Test: flutter analyze bersih

- [ ] **Task 1.1.6**: Update AndroidManifest.xml

  - [ ] Register ForegroundService dengan proper foregroundServiceType
  - [ ] Register BootReceiver untuk auto-start
  - [ ] Verify semua permissions ada
  - [ ] Test: Build berhasil

- [ ] **Task 1.1.7**: Update PatientHomeScreen

  - [ ] Update initialization logic untuk use new service
  - [ ] Add notification permission request (Android 13+)
  - [ ] Update UI feedback messages
  - [ ] Test: flutter analyze bersih

- [ ] **Task 1.1.8**: Testing Sprint 1.1
  - [ ] Test: Tracking starts successfully
  - [ ] Test: Notification appears dan persisten
  - [ ] Test: Minimize app → tracking continues
  - [ ] Test: Terminate app → tracking continues
  - [ ] Test: Location data masih masuk ke database
  - [ ] Test: Stop tracking → notification hilang
  - [ ] Test: Battery consumption measurement
  - [ ] Fix bugs yang ditemukan

---

#### Sprint 1.2: Battery Optimization Handling

- [ ] **Task 1.2.1**: Implement BatteryOptimizationHelper

  - [ ] Create `lib/core/utils/battery_optimization_helper.dart`
  - [ ] Add method untuk check battery optimization status
  - [ ] Add method untuk request exemption
  - [ ] Add method untuk open battery settings
  - [ ] Test: flutter analyze bersih

- [ ] **Task 1.2.2**: Create educational dialog

  - [ ] Design dialog UI dengan illustration
  - [ ] Add clear explanation tentang battery optimization
  - [ ] Add benefits list (bullet points)
  - [ ] Add action buttons (Skip, Settings)
  - [ ] Test: flutter analyze bersih

- [ ] **Task 1.2.3**: Integrate dengan PatientHomeScreen

  - [ ] Add battery optimization check saat initialization
  - [ ] Show dialog jika belum exempted
  - [ ] Track user decision (SharedPreferences)
  - [ ] Add reminder setelah 3 hari jika skip
  - [ ] Test: flutter analyze bersih

- [ ] **Task 1.2.4**: Handle different Android versions

  - [ ] Android 6-10: REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
  - [ ] Android 11+: Different behavior
  - [ ] Fallback untuk older versions
  - [ ] Test di multiple Android versions

- [ ] **Task 1.2.5**: Testing Sprint 1.2
  - [ ] Test: Dialog muncul saat first launch
  - [ ] Test: Request battery exemption berhasil
  - [ ] Test: Settings deeplink bekerja
  - [ ] Test: Reminder muncul setelah skip
  - [ ] Fix bugs yang ditemukan

---

### Phase 2: Improvements (Hari 3-4) 🟡

#### Sprint 2.1: Auto-Restart After Reboot

- [ ] **Task 2.1.1**: Verify BootReceiver registration

  - [ ] Check AndroidManifest.xml untuk boot receiver
  - [ ] Verify intent-filter untuk BOOT_COMPLETED
  - [ ] Verify intent-filter untuk QUICKBOOT_POWERON
  - [ ] Test: Build berhasil

- [ ] **Task 2.1.2**: Implement tracking state persistence

  - [ ] Create `lib/core/utils/tracking_state_manager.dart`
  - [ ] Save tracking state ke SharedPreferences
  - [ ] Save patientId, mode, dan timestamp
  - [ ] Load tracking state dari SharedPreferences
  - [ ] Clear tracking state saat stop
  - [ ] Test: flutter analyze bersih

- [ ] **Task 2.1.3**: Implement auto-start logic

  - [ ] Check tracking state on app start
  - [ ] Check battery optimization status
  - [ ] Check network connectivity
  - [ ] Start tracking jika was active before reboot
  - [ ] Show notification success/failure
  - [ ] Test: flutter analyze bersih

- [ ] **Task 2.1.4**: Testing Sprint 2.1
  - [ ] Test: Reboot device → tracking auto-start
  - [ ] Test: Stop tracking → reboot → tidak auto-start
  - [ ] Test: Battery optimization denied → show warning
  - [ ] Test: Network offline → queue locations
  - [ ] Fix bugs yang ditemukan

---

#### Sprint 2.2: Background Permission Education

- [ ] **Task 2.2.1**: Design permission education screen

  - [ ] Create `lib/presentation/screens/common/permission_education_screen.dart`
  - [ ] Add illustrations (use assets/images/)
  - [ ] Add step-by-step guide dengan numbered list
  - [ ] Add "Why we need this" section
  - [ ] Add benefits section dengan icons
  - [ ] Test: flutter analyze bersih

- [ ] **Task 2.2.2**: Create illustrated guide for Android 10+

  - [ ] Screenshot Android permission dialog
  - [ ] Highlight "Allow all the time" option
  - [ ] Add arrows dan annotations
  - [ ] Support light/dark theme
  - [ ] Test: UI responsive

- [ ] **Task 2.2.3**: Implement persistent reminder

  - [ ] Check background permission status daily
  - [ ] Show notification jika hanya "While using app"
  - [ ] Add deeplink ke permission education screen
  - [ ] Track reminder dismiss count (max 3)
  - [ ] Test: flutter analyze bersih

- [ ] **Task 2.2.4**: Add in-app prompt

  - [ ] Show bottom sheet saat user dismiss background permission
  - [ ] Explain importance dengan gentle language
  - [ ] Add "Learn More" button → education screen
  - [ ] Add "Not Now" button (track count)
  - [ ] Test: flutter analyze bersih

- [ ] **Task 2.2.5**: Testing Sprint 2.2
  - [ ] Test: Education screen accessible dari Settings
  - [ ] Test: Reminder muncul jika permission tidak granted
  - [ ] Test: Dismiss reminder → muncul lagi setelah 24 jam
  - [ ] Test: Grant permission → reminder hilang
  - [ ] Fix bugs yang ditemukan

---

### Phase 3: Testing & Optimization (Hari 5) 🟢

#### Sprint 3.1: Comprehensive Testing

- [ ] **Task 3.1.1**: Functional testing

  - [ ] Test: Happy path - start tracking berhasil
  - [ ] Test: Stop tracking berhasil
  - [ ] Test: Change tracking mode on the fly
  - [ ] Test: Foreground ↔ Background transitions
  - [ ] Test: App termination handling
  - [ ] Test: Device reboot handling
  - [ ] Test: Network offline/online transitions
  - [ ] Test: Location accuracy filtering
  - [ ] Test: Offline queue sync

- [ ] **Task 3.1.2**: Permission testing

  - [ ] Test: Request foreground permission - grant
  - [ ] Test: Request foreground permission - deny
  - [ ] Test: Request foreground permission - deny permanently
  - [ ] Test: Request background permission - grant
  - [ ] Test: Request background permission - deny
  - [ ] Test: Battery optimization - exemption granted
  - [ ] Test: Battery optimization - exemption denied

- [ ] **Task 3.1.3**: Battery consumption testing

  - [ ] Test: High accuracy mode - 8 hours continuous
  - [ ] Test: Balanced mode - 8 hours continuous
  - [ ] Test: Power saving mode - 8 hours continuous
  - [ ] Measure: Battery percentage drop per hour
  - [ ] Verify: < 5% per hour untuk balanced mode
  - [ ] Optimize: Jika consumption terlalu tinggi

- [ ] **Task 3.1.4**: Network reliability testing

  - [ ] Test: Offline tracking - 1 hour
  - [ ] Test: Network available → auto-sync
  - [ ] Test: Sync failure → retry logic
  - [ ] Test: Max retries reached → mark failed
  - [ ] Verify: Zero data loss

- [ ] **Task 3.1.5**: Memory leak testing

  - [ ] Run: Memory profiler selama 2 jam
  - [ ] Check: Memory usage growth
  - [ ] Check: Garbage collection frequency
  - [ ] Fix: Memory leaks jika ditemukan

- [ ] **Task 3.1.6**: Performance profiling

  - [ ] Profile: Location update latency
  - [ ] Profile: Database write performance
  - [ ] Profile: Notification update overhead
  - [ ] Optimize: Jika ada bottleneck

- [ ] **Task 3.1.7**: Edge case testing
  - [ ] Test: GPS signal loss → recovery
  - [ ] Test: Airplane mode → recovery
  - [ ] Test: Low battery (< 10%) → power saving mode
  - [ ] Test: Battery saver mode enabled
  - [ ] Test: Developer options - Mock location
  - [ ] Test: Rapid permission revoke/grant
  - [ ] Test: Force stop app → auto-restart
  - [ ] Test: Clear app data → clean state

---

#### Sprint 3.2: Bug Fixes & Optimization

- [ ] **Task 3.2.1**: Fix bugs dari testing

  - [ ] List semua bugs yang ditemukan
  - [ ] Prioritize: Critical → High → Medium → Low
  - [ ] Fix bugs satu per satu
  - [ ] Re-test setiap fix
  - [ ] Update: Test cases

- [ ] **Task 3.2.2**: Code optimization

  - [ ] Review: Code complexity
  - [ ] Refactor: Complex methods
  - [ ] Optimize: Database queries
  - [ ] Optimize: Network calls
  - [ ] Remove: Dead code

- [ ] **Task 3.2.3**: Documentation update
  - [ ] Update: README.md dengan new features
  - [ ] Update: Copilot instructions
  - [ ] Create: User guide untuk tracking
  - [ ] Create: Troubleshooting guide
  - [ ] Update: API documentation

---

#### Sprint 3.3: Final Validation

- [ ] **Task 3.3.1**: flutter analyze

  - [ ] Run: flutter analyze
  - [ ] Fix: Semua errors
  - [ ] Fix: Semua warnings (jika mungkin)
  - [ ] Verify: 0 errors, minimal warnings

- [ ] **Task 3.3.2**: Code review

  - [ ] Review: Semua file baru
  - [ ] Review: Semua file yang dimodifikasi
  - [ ] Check: Code quality
  - [ ] Check: Best practices
  - [ ] Check: Error handling
  - [ ] Check: Logging
  - [ ] Check: Comments dan documentation

- [ ] **Task 3.3.3**: Integration testing

  - [ ] Test: End-to-end flow dari patient perspective
  - [ ] Test: End-to-end flow dari family perspective
  - [ ] Test: Emergency button dengan tracking active
  - [ ] Test: Face recognition dengan tracking active
  - [ ] Test: Multiple features running simultaneously

- [ ] **Task 3.3.4**: Performance validation

  - [ ] Verify: App startup time < 3 seconds
  - [ ] Verify: Location update latency < 1 second
  - [ ] Verify: Database write latency < 500ms
  - [ ] Verify: UI responsiveness (60 FPS)
  - [ ] Verify: Battery consumption targets met

- [ ] **Task 3.3.5**: User acceptance testing

  - [ ] Prepare: Test scenarios
  - [ ] Recruit: 2-3 test users (jika ada)
  - [ ] Conduct: Testing sessions
  - [ ] Collect: Feedback
  - [ ] Fix: Critical issues

- [ ] **Task 3.3.6**: Final documentation
  - [ ] Create: IMPLEMENTATION_COMPLETE_TRACKING_FIX.md
  - [ ] Document: All changes made
  - [ ] Document: Known limitations
  - [ ] Document: Future improvements
  - [ ] Update: Project README

---

## 📁 File Structure (Yang Akan Dibuat/Dimodifikasi)

### New Files (Yang Akan Dibuat)

```
lib/data/services/
├── foreground_task_service.dart         ⭐ NEW - Main service
├── location_background_handler.dart     ⭐ NEW - Background callback
└── tracking_state_manager.dart          ⭐ NEW - State persistence

lib/core/utils/
├── battery_optimization_helper.dart     ⭐ NEW - Battery management
└── tracking_state_manager.dart          ⭐ NEW - Could be here instead

lib/presentation/screens/common/
└── permission_education_screen.dart     ⭐ NEW - Education UI

docs/
├── ANALISIS_TRACKING_PATIENT_MENDALAM.md           ✅ CREATED
├── RANCANGAN_IMPLEMENTASI_TRACKING_FIX.md          ✅ THIS FILE
└── IMPLEMENTATION_COMPLETE_TRACKING_FIX.md         ⭐ FUTURE
```

### Modified Files (Yang Akan Dimodifikasi)

```
lib/data/services/
└── location_service.dart                📝 MODIFY - Integration

lib/presentation/screens/patient/
└── patient_home_screen.dart             📝 MODIFY - UI updates

android/app/src/main/AndroidManifest.xml 📝 MODIFY - Service registration

pubspec.yaml                              ✅ NO CHANGE (already has dependencies)
```

---

## 🔧 Technical Implementation Details

### 1. ForegroundTaskService Architecture

```dart
// lib/data/services/foreground_task_service.dart

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk manage foreground task (background tracking)
///
/// Features:
/// - Persistent notification
/// - Auto-restart after reboot
/// - State persistence
/// - Battery efficient
class ForegroundTaskService {
  static const String taskName = 'aivia_location_tracking';
  static const String _prefKeyPatientId = 'tracking_patient_id';
  static const String _prefKeyMode = 'tracking_mode';
  static const String _prefKeyActive = 'tracking_active';

  /// Initialize service configuration
  /// Call this once at app startup
  static Future<void> initialize() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        id: 1000,
        channelId: 'location_tracking',
        channelName: 'Pelacakan Lokasi AIVIA',
        channelDescription: 'Melacak lokasi pasien untuk keamanan',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
        buttons: [
          const NotificationButton(
            id: 'stop_tracking',
            text: 'Stop Tracking',
            textColor: Colors.red,
          ),
        ],
      ),
      iosNotificationOptions: IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        interval: 300000, // 5 minutes (balanced mode default)
        isOnceEvent: false,
        autoRunOnBoot: true, // ⭐ Auto-start after reboot
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// Start foreground service
  /// Returns true jika berhasil start
  static Future<bool> start({
    required String patientId,
    TrackingMode mode = TrackingMode.balanced,
  }) async {
    // Save tracking state untuk auto-restart
    await _saveTrackingState(
      patientId: patientId,
      mode: mode,
      active: true,
    );

    // Start service dengan notification
    final started = await FlutterForegroundTask.startService(
      notificationTitle: '📍 AIVIA Tracking Aktif',
      notificationText: 'Melacak lokasi Anda untuk keamanan',
      callback: startLocationCallback, // Top-level function
    );

    if (started) {
      debugPrint('✅ Foreground service started');
      debugPrint('   Patient ID: $patientId');
      debugPrint('   Mode: ${mode.displayName}');
    }

    return started;
  }

  /// Stop foreground service
  static Future<bool> stop() async {
    await _saveTrackingState(active: false);
    final stopped = await FlutterForegroundTask.stopService();

    if (stopped) {
      debugPrint('🛑 Foreground service stopped');
    }

    return stopped;
  }

  /// Update notification content
  static void updateNotification({
    required String title,
    required String text,
  }) {
    FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: text,
    );
  }

  /// Save tracking state to SharedPreferences
  static Future<void> _saveTrackingState({
    String? patientId,
    TrackingMode? mode,
    bool? active,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (patientId != null) {
      await prefs.setString(_prefKeyPatientId, patientId);
    }

    if (mode != null) {
      await prefs.setString(_prefKeyMode, mode.name);
    }

    if (active != null) {
      await prefs.setBool(_prefKeyActive, active);
    }
  }

  /// Load tracking state dari SharedPreferences
  static Future<TrackingState?> loadTrackingState() async {
    final prefs = await SharedPreferences.getInstance();

    final active = prefs.getBool(_prefKeyActive) ?? false;
    if (!active) return null;

    final patientId = prefs.getString(_prefKeyPatientId);
    final modeName = prefs.getString(_prefKeyMode);

    if (patientId == null) return null;

    final mode = TrackingMode.values.firstWhere(
      (m) => m.name == modeName,
      orElse: () => TrackingMode.balanced,
    );

    return TrackingState(
      patientId: patientId,
      mode: mode,
    );
  }
}

/// Tracking state model
class TrackingState {
  final String patientId;
  final TrackingMode mode;

  TrackingState({
    required this.patientId,
    required this.mode,
  });
}

/// Background callback - must be top-level function
/// ⭐ CRITICAL: @pragma directive required untuk isolate
@pragma('vm:entry-point')
void startLocationCallback() {
  FlutterForegroundTask.setTaskHandler(LocationBackgroundHandler());
}
```

### 2. LocationBackgroundHandler Implementation

```dart
// lib/data/services/location_background_handler.dart

import 'dart:async';
import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_aivia/data/services/location_service.dart';
import 'package:project_aivia/data/services/offline_queue_service.dart';
import 'package:project_aivia/core/utils/location_validator.dart';

/// Background handler untuk location tracking
///
/// Runs in separate isolate, independently dari main app
/// This ensures tracking continues even when app terminated
class LocationBackgroundHandler extends TaskHandler {
  StreamSubscription<Position>? _positionSubscription;
  OfflineQueueService? _offlineQueue;
  TrackingState? _state;
  Location? _lastValidLocation;
  int _totalLocations = 0;
  int _validLocations = 0;

  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    try {
      debugPrint('🚀 Background handler started');

      // Initialize Supabase (required untuk database access)
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );

      // Initialize offline queue
      _offlineQueue = OfflineQueueService();
      await _offlineQueue!.initialize();

      // Load tracking state
      _state = await ForegroundTaskService.loadTrackingState();

      if (_state != null) {
        debugPrint('✅ Tracking state loaded');
        debugPrint('   Patient ID: ${_state!.patientId}');
        debugPrint('   Mode: ${_state!.mode.displayName}');

        // Start position stream
        await _startPositionStream();
      } else {
        debugPrint('⚠️ No tracking state found');
      }
    } catch (e) {
      debugPrint('❌ Error in onStart: $e');
    }
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp, SendPort? sendPort) async {
    // This is called every interval (5 minutes for balanced mode)
    try {
      // Sync pending locations
      if (_offlineQueue != null) {
        final result = await _offlineQueue!.syncPendingLocations();
        result.fold(
          onSuccess: (syncResult) {
            debugPrint('✅ Sync complete: ${syncResult.successCount} synced');
          },
          onFailure: (failure) {
            debugPrint('⚠️ Sync failed: $failure');
          },
        );
      }

      // Update notification dengan stats
      if (_state != null) {
        final accuracy = _totalLocations > 0
          ? ((_validLocations / _totalLocations) * 100).toStringAsFixed(0)
          : '0';

        ForegroundTaskService.updateNotification(
          title: '📍 AIVIA Tracking Aktif',
          text: 'Lokasi valid: $_validLocations/$_totalLocations ($accuracy%)',
        );
      }
    } catch (e) {
      debugPrint('❌ Error in onRepeatEvent: $e');
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    try {
      debugPrint('🛑 Background handler stopping');

      // Cancel position stream
      await _positionSubscription?.cancel();
      _positionSubscription = null;

      // Dispose offline queue
      _offlineQueue?.dispose();

      debugPrint('✅ Background handler stopped cleanly');
    } catch (e) {
      debugPrint('❌ Error in onDestroy: $e');
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'stop_tracking') {
      // Stop button di notification pressed
      FlutterForegroundTask.stopService();
    }
  }

  // ==================== PRIVATE METHODS ====================

  Future<void> _startPositionStream() async {
    if (_state == null) return;

    final settings = _getLocationSettings(_state!.mode);

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (position) => _handlePosition(position),
      onError: (error) {
        debugPrint('❌ Position stream error: $error');
      },
    );

    debugPrint('✅ Position stream started');
  }

  Future<void> _handlePosition(Position position) async {
    try {
      _totalLocations++;

      // Convert to Location model
      final location = Location(
        patientId: _state!.patientId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
      );

      // Validate location
      final validation = LocationValidator.validate(
        location,
        previous: _lastValidLocation,
      );

      if (validation.isInvalid) {
        debugPrint('❌ Invalid location: ${validation.message}');
        return;
      }

      if (validation.isWarning) {
        debugPrint('⚠️ Warning: ${validation.message}');
      }

      // Queue location
      if (_offlineQueue != null) {
        final result = await _offlineQueue!.queueLocation(
          location,
          altitude: position.altitude,
          speed: position.speed,
          heading: position.heading,
          isBackground: true, // ⭐ Mark as background update
        );

        if (result.isSuccess) {
          _validLocations++;
          _lastValidLocation = location;

          debugPrint(
            '📍 Location queued: '
            '${position.latitude.toStringAsFixed(6)}, '
            '${position.longitude.toStringAsFixed(6)} '
            '(accuracy: ${position.accuracy.toStringAsFixed(1)}m)',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error handling position: $e');
    }
  }

  LocationSettings _getLocationSettings(TrackingMode mode) {
    switch (mode) {
      case TrackingMode.highAccuracy:
        return const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 10,
          timeLimit: Duration(minutes: 1),
        );
      case TrackingMode.balanced:
        return const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 25,
          timeLimit: Duration(minutes: 5),
        );
      case TrackingMode.powerSaving:
        return const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 50,
          timeLimit: Duration(minutes: 15),
        );
    }
  }
}
```

### 3. LocationService Integration

```dart
// lib/data/services/location_service.dart
// MODIFY existing file

class LocationService {
  // ... existing code ...

  /// Start location tracking
  ///
  /// ⭐ MODIFIED: Now uses foreground service for background tracking
  Future<Result<void>> startTracking(
    String patientId, {
    TrackingMode mode = TrackingMode.balanced,
  }) async {
    try {
      // Validate permissions (unchanged)
      final permissionResult = await _validatePermissions();
      if (permissionResult.isFailure) {
        return permissionResult;
      }

      // Stop existing tracking if any (unchanged)
      if (_isTracking) {
        await stopTracking();
      }

      // ⭐ NEW: Start foreground service instead of direct stream
      final started = await ForegroundTaskService.start(
        patientId: patientId,
        mode: mode,
      );

      if (!started) {
        return const ResultFailure(
          ServerFailure('Gagal memulai foreground service'),
        );
      }

      // Update state (unchanged)
      _currentPatientId = patientId;
      _trackingMode = mode;
      _isTracking = true;

      debugPrint('✅ Location tracking started with foreground service');
      debugPrint('   Patient ID: $patientId');
      debugPrint('   Mode: ${mode.displayName}');

      return const Success(null);
    } catch (e) {
      return ResultFailure(ServerFailure('Gagal memulai tracking: $e'));
    }
  }

  /// Stop location tracking
  ///
  /// ⭐ MODIFIED: Now stops foreground service
  Future<void> stopTracking() async {
    // ⭐ NEW: Stop foreground service
    await ForegroundTaskService.stop();

    // Update state (unchanged)
    _isTracking = false;
    _currentPatientId = null;

    debugPrint('🛑 Location tracking stopped');
  }

  // ... rest of existing code unchanged ...
}
```

---

## 🎯 Acceptance Criteria

### Functional Requirements

- [ ] ✅ Tracking berjalan ketika app di foreground
- [ ] ✅ Tracking berjalan ketika app di background (minimized)
- [ ] ✅ Tracking berjalan ketika app terminated (swipe dari recent apps)
- [ ] ✅ Tracking auto-start setelah device reboot (jika was active)
- [ ] ✅ Persistent notification visible dengan informasi useful
- [ ] ✅ Location data masuk ke database dengan benar
- [ ] ✅ Offline queue bekerja (data tidak hilang saat no network)
- [ ] ✅ Battery optimization exemption requested dan handled
- [ ] ✅ Permission flow smooth dan educational

### Performance Requirements

- [ ] ✅ Battery consumption < 5% per hour (balanced mode)
- [ ] ✅ Battery consumption < 7% per hour (high accuracy mode)
- [ ] ✅ Battery consumption < 3% per hour (power saving mode)
- [ ] ✅ Location accuracy < 50 meters (95% of the time)
- [ ] ✅ Data sync latency < 5 seconds (when online)
- [ ] ✅ Notification update latency < 1 second
- [ ] ✅ Zero data loss (offline queue)

### Code Quality Requirements

- [ ] ✅ flutter analyze: 0 errors
- [ ] ✅ flutter analyze: < 5 warnings (or all justified)
- [ ] ✅ All public methods documented
- [ ] ✅ Error handling comprehensive
- [ ] ✅ Logging informative (not excessive)
- [ ] ✅ Code follows project conventions
- [ ] ✅ No hardcoded strings (use AppStrings)
- [ ] ✅ No magic numbers (use named constants)

---

## 📱 Testing Scenarios

### Manual Testing Checklist

```
Scenario 1: Happy Path
[ ] Start app → Login → Tracking starts automatically
[ ] See persistent notification
[ ] Minimize app → Notification stays
[ ] Open Maps app → Location still updating
[ ] Terminate app → Notification stays
[ ] Wait 5 minutes → Open Supabase → Verify new locations

Scenario 2: Permissions
[ ] Fresh install → Request foreground permission → Grant
[ ] Request background permission → Grant "Allow all the time"
[ ] Request battery optimization exemption → Grant
[ ] Verify all permissions granted in Settings

Scenario 3: Permission Denial
[ ] Deny foreground permission → See education dialog
[ ] Deny background permission → See education screen
[ ] Deny permanently → Guide to Settings → Grant manually

Scenario 4: Battery Optimization
[ ] Skip battery exemption → See reminder after 3 days
[ ] Battery saver mode ON → Verify tracking still works
[ ] Low battery (< 10%) → Verify auto-switch to power saving mode

Scenario 5: Network Resilience
[ ] Enable airplane mode → Wait 5 minutes
[ ] Disable airplane mode → Verify auto-sync
[ ] Check database → All locations present

Scenario 6: Device Reboot
[ ] Tracking active → Reboot device
[ ] After boot → Verify tracking auto-started
[ ] Check notification → Should be visible
[ ] Stop tracking → Reboot → Verify NOT auto-started

Scenario 7: App Updates
[ ] Tracking active → Install update
[ ] After update → Verify tracking continues
[ ] Check data consistency

Scenario 8: Multi-Device
[ ] Patient device tracking
[ ] Family device viewing map
[ ] Verify real-time updates
[ ] Verify location accuracy
```

---

## 🚀 Deployment Checklist

```
Pre-Deployment:
[ ] All TODO items completed
[ ] All acceptance criteria met
[ ] All tests passed
[ ] flutter analyze clean
[ ] Code review passed
[ ] Documentation updated

Build:
[ ] Clean build: flutter clean
[ ] Get dependencies: flutter pub get
[ ] Run code generation: flutter pub run build_runner build
[ ] Build APK: flutter build apk --release
[ ] Build AAB: flutter build appbundle --release
[ ] Test on physical device

Post-Deployment:
[ ] Monitor crash reports (Firebase Crashlytics)
[ ] Monitor battery consumption reports
[ ] Monitor user feedback
[ ] Plan for hotfix if needed
```

---

## 📝 Notes & Considerations

### Important Reminders

1. **Isolate Communication**: Background handler runs di separate isolate, cannot directly access main app state
2. **Battery Optimization**: Exemption harus di-request explicitly, tidak automatic
3. **Android Versions**: Different behavior untuk Android 6, 8, 10, 11, 12, 13, 14
4. **Notification Required**: Foreground service MUST show notification (Android requirement)
5. **Permissions**: Background location memerlukan foreground permission dulu

### Known Limitations

1. iOS tidak fully supported (flutter_foreground_task has limitations)
2. Some Chinese devices (Xiaomi, Oppo, Vivo) aggressive battery optimization
3. Battery consumption varies by device manufacturer
4. GPS accuracy depends on device hardware
5. Network conditions affect sync reliability

### Future Improvements (Out of Scope)

- [ ] Geofencing untuk notifikasi area tertentu
- [ ] Movement detection untuk adaptive tracking
- [ ] ML prediction untuk optimize battery
- [ ] Smart routing suggestion
- [ ] Historical heatmap visualization
- [ ] Export tracking data (CSV, GPX)

---

## 🎓 References & Resources

### Documentation

- [Flutter Foreground Task Package](https://pub.dev/packages/flutter_foreground_task)
- [Geolocator Package](https://pub.dev/packages/geolocator)
- [Android Foreground Services](https://developer.android.com/guide/components/foreground-services)
- [Android Background Location Best Practices](https://developer.android.com/training/location/background)
- [Android Battery Optimization](https://developer.android.com/training/monitoring-device-state/doze-standby)

### Similar Implementations

- Strava (fitness tracking)
- Google Maps (location history)
- Life360 (family locator)
- Find My (Apple)

### Performance Benchmarks

| App              | Battery (8h) | Accuracy  | Data Loss |
| ---------------- | ------------ | --------- | --------- |
| Google Maps      | 18-22%       | Excellent | 0%        |
| Life360          | 15-20%       | Good      | <1%       |
| Strava           | 25-30%       | Excellent | 0%        |
| **AIVIA Target** | **<20%**     | **Good**  | **<1%**   |

---

**Status**: 📋 Rancangan Complete, Ready untuk Implementation  
**Next**: Mulai Task 1.1.1 - Setup flutter_foreground_task configuration
