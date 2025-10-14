import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:project_aivia/core/utils/result.dart';
import 'package:project_aivia/core/errors/failures.dart';
import 'package:project_aivia/data/repositories/location_repository.dart';

/// Service untuk background location tracking dengan battery optimization
///
/// Features:
/// - Real-time GPS tracking
/// - Background location updates
/// - Permission handling (foreground + background)
/// - Battery-efficient tracking modes
/// - Automatic save to database
/// - Location accuracy filtering
class LocationService {
  LocationService(this._locationRepository);

  final LocationRepository _locationRepository;

  // Tracking state
  bool _isTracking = false;
  String? _currentPatientId;
  StreamSubscription<Position>? _positionSubscription;
  TrackingMode _trackingMode = TrackingMode.balanced;

  // Getters
  bool get isTracking => _isTracking;
  TrackingMode get currentMode => _trackingMode;

  /// Initialize location service
  ///
  /// Call this once at app startup
  Future<Result<void>> initialize() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const ResultFailure(
          ValidationFailure(
            'Layanan lokasi tidak aktif. '
            'Silakan aktifkan GPS di pengaturan perangkat.',
          ),
        );
      }

      return const Success(null);
    } catch (e) {
      return ResultFailure(
        ServerFailure('Gagal menginisialisasi location service: $e'),
      );
    }
  }

  /// Check current location permission status
  Future<ph.PermissionStatus> checkPermission() async {
    return await ph.Permission.location.status;
  }

  /// Check background location permission (Android 10+)
  Future<ph.PermissionStatus> checkBackgroundPermission() async {
    return await ph.Permission.locationAlways.status;
  }

  /// Request foreground location permission
  ///
  /// Returns true if granted
  Future<Result<bool>> requestLocationPermission() async {
    try {
      final status = await ph.Permission.location.request();

      if (status.isGranted) {
        return const Success(true);
      } else if (status.isDenied) {
        return const ResultFailure(
          ValidationFailure(
            'Izin lokasi ditolak. '
            'Aplikasi memerlukan akses lokasi untuk melacak keberadaan pasien.',
          ),
        );
      } else if (status.isPermanentlyDenied) {
        return const ResultFailure(
          ValidationFailure(
            'Izin lokasi ditolak permanen. '
            'Silakan aktifkan di Pengaturan > Aplikasi > AIVIA > Izin.',
          ),
        );
      }

      return const Success(false);
    } catch (e) {
      return ResultFailure(ServerFailure('Gagal meminta izin lokasi: $e'));
    }
  }

  /// Request background location permission (Android 10+)
  ///
  /// Must request foreground permission first!
  Future<Result<bool>> requestBackgroundPermission() async {
    try {
      // Check if foreground permission granted first
      final foregroundStatus = await ph.Permission.location.status;
      if (!foregroundStatus.isGranted) {
        return const ResultFailure(
          ValidationFailure(
            'Izin lokasi foreground harus diberikan terlebih dahulu.',
          ),
        );
      }

      final status = await ph.Permission.locationAlways.request();

      if (status.isGranted) {
        return const Success(true);
      } else if (status.isDenied) {
        return const ResultFailure(
          ValidationFailure(
            'Izin lokasi latar belakang ditolak. '
            'Aplikasi tidak dapat melacak lokasi saat ditutup.',
          ),
        );
      } else if (status.isPermanentlyDenied) {
        return const ResultFailure(
          ValidationFailure(
            'Izin lokasi latar belakang ditolak permanen. '
            'Silakan pilih "Izinkan sepanjang waktu" di Pengaturan.',
          ),
        );
      }

      return const Success(false);
    } catch (e) {
      return ResultFailure(
        ServerFailure('Gagal meminta izin lokasi latar belakang: $e'),
      );
    }
  }

  /// Open app settings for manual permission grant
  Future<bool> openAppSettings() async {
    return await ph.openAppSettings();
  }

  /// Start location tracking for a patient
  ///
  /// [patientId] - ID pasien yang akan dilacak
  /// [mode] - Tracking mode (affects battery usage)
  Future<Result<void>> startTracking(
    String patientId, {
    TrackingMode mode = TrackingMode.balanced,
  }) async {
    try {
      // Validate permissions
      final permissionResult = await _validatePermissions();
      if (permissionResult.isFailure) {
        return permissionResult;
      }

      // Stop existing tracking if any
      if (_isTracking) {
        await stopTracking();
      }

      _currentPatientId = patientId;
      _trackingMode = mode;
      _isTracking = true;

      // Configure location settings based on mode
      final locationSettings = _getLocationSettings(mode);

      // Start listening to position stream
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (Position position) async {
              await _handlePositionUpdate(position, patientId);
            },
            onError: (error) {
              debugPrint('❌ Location stream error: $error');
            },
          );

      debugPrint('✅ Location tracking started for patient: $patientId');
      debugPrint('🔋 Tracking mode: ${mode.displayName}');

      return const Success(null);
    } catch (e) {
      return ResultFailure(ServerFailure('Gagal memulai tracking lokasi: $e'));
    }
  }

  /// Stop location tracking
  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _isTracking = false;
    _currentPatientId = null;

    debugPrint('🛑 Location tracking stopped');
  }

  /// Get current position (one-time fetch)
  Future<Result<Position>> getCurrentPosition() async {
    try {
      final permissionResult = await _validatePermissions();
      if (permissionResult.isFailure) {
        return ResultFailure(permissionResult.failure);
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return Success(position);
    } catch (e) {
      return ResultFailure(
        ServerFailure('Gagal mendapatkan lokasi saat ini: $e'),
      );
    }
  }

  /// Change tracking mode (affects battery usage)
  void setTrackingMode(TrackingMode mode) {
    if (_trackingMode == mode) return;

    _trackingMode = mode;

    // Restart tracking with new mode if currently tracking
    if (_isTracking && _currentPatientId != null) {
      final patientId = _currentPatientId!;
      stopTracking().then((_) {
        startTracking(patientId, mode: mode);
      });
    }
  }

  // ==================== PRIVATE METHODS ====================

  /// Validate that necessary permissions are granted
  Future<Result<void>> _validatePermissions() async {
    final foreground = await ph.Permission.location.status;
    if (!foreground.isGranted) {
      return const ResultFailure(
        ValidationFailure('Izin lokasi belum diberikan'),
      );
    }

    return const Success(null);
  }

  /// Get LocationSettings based on TrackingMode
  LocationSettings _getLocationSettings(TrackingMode mode) {
    switch (mode) {
      case TrackingMode.highAccuracy:
        return const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 10, // Update every 10 meters
          timeLimit: Duration(minutes: 1), // Max 1 min between updates
        );

      case TrackingMode.balanced:
        return const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 25, // Update every 25 meters
          timeLimit: Duration(minutes: 5), // Max 5 min between updates
        );

      case TrackingMode.powerSaving:
        return const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 50, // Update every 50 meters
          timeLimit: Duration(minutes: 15), // Max 15 min between updates
        );
    }
  }

  /// Handle position update from stream
  Future<void> _handlePositionUpdate(
    Position position,
    String patientId,
  ) async {
    try {
      // Filter out low accuracy positions (> 100 meters)
      if (position.accuracy > 100) {
        debugPrint('⚠️ Low accuracy position skipped: ${position.accuracy}m');
        return;
      }

      // Save to database
      final result = await _locationRepository.insertLocation(
        patientId: patientId,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );

      if (result.isSuccess) {
        debugPrint(
          '📍 Location saved: '
          '${position.latitude.toStringAsFixed(6)}, '
          '${position.longitude.toStringAsFixed(6)} '
          '(accuracy: ${position.accuracy.toStringAsFixed(1)}m)',
        );
      } else {
        debugPrint('❌ Failed to save location: ${result.failure}');
      }
    } catch (e) {
      debugPrint('❌ Error handling position update: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
  }
}

/// Tracking mode affects battery usage and location accuracy
enum TrackingMode {
  /// High accuracy, frequent updates (1 min / 10m)
  /// Battery impact: ~5-7% per hour
  highAccuracy,

  /// Balanced mode (5 min / 25m) - RECOMMENDED
  /// Battery impact: ~2-3% per hour
  balanced,

  /// Power saving mode (15 min / 50m)
  /// Battery impact: ~1-2% per hour
  powerSaving,
}

extension TrackingModeExtension on TrackingMode {
  String get displayName {
    switch (this) {
      case TrackingMode.highAccuracy:
        return 'Akurasi Tinggi';
      case TrackingMode.balanced:
        return 'Seimbang';
      case TrackingMode.powerSaving:
        return 'Hemat Daya';
    }
  }

  String get description {
    switch (this) {
      case TrackingMode.highAccuracy:
        return 'Pembaruan setiap 1 menit atau 10 meter. '
            'Akurasi terbaik, konsumsi baterai ~5-7% per jam.';
      case TrackingMode.balanced:
        return 'Pembaruan setiap 5 menit atau 25 meter. '
            'Keseimbangan optimal, konsumsi baterai ~2-3% per jam.';
      case TrackingMode.powerSaving:
        return 'Pembaruan setiap 15 menit atau 50 meter. '
            'Hemat daya, konsumsi baterai ~1-2% per jam.';
    }
  }

  Duration get updateInterval {
    switch (this) {
      case TrackingMode.highAccuracy:
        return const Duration(minutes: 1);
      case TrackingMode.balanced:
        return const Duration(minutes: 5);
      case TrackingMode.powerSaving:
        return const Duration(minutes: 15);
    }
  }

  double get distanceFilter {
    switch (this) {
      case TrackingMode.highAccuracy:
        return 10.0;
      case TrackingMode.balanced:
        return 25.0;
      case TrackingMode.powerSaving:
        return 50.0;
    }
  }
}
