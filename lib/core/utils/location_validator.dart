import 'dart:math' as math;
import 'package:project_aivia/data/models/location.dart' as models;

/// Validation result untuk location checks
class ValidationResult {
  final ValidationStatus status;
  final String? message;

  const ValidationResult._({required this.status, this.message});

  factory ValidationResult.valid() =>
      const ValidationResult._(status: ValidationStatus.valid);

  factory ValidationResult.warning(String message) =>
      ValidationResult._(status: ValidationStatus.warning, message: message);

  factory ValidationResult.invalid(String message) =>
      ValidationResult._(status: ValidationStatus.invalid, message: message);

  bool get isValid => status == ValidationStatus.valid;
  bool get isWarning => status == ValidationStatus.warning;
  bool get isInvalid => status == ValidationStatus.invalid;

  @override
  String toString() {
    return 'ValidationResult(status: $status, message: $message)';
  }
}

enum ValidationStatus { valid, warning, invalid }

/// Enterprise-grade location validator dengan comprehensive checks
///
/// Best practices:
/// - Coordinate bounds validation
/// - Accuracy threshold enforcement
/// - Unrealistic speed detection
/// - GPS spoofing prevention
class LocationValidator {
  // Coordinate bounds (WGS84)
  static const double minLatitude = -90.0;
  static const double maxLatitude = 90.0;
  static const double minLongitude = -180.0;
  static const double maxLongitude = 180.0;

  // Accuracy thresholds (meters)
  static const double maxAcceptableAccuracy = 100.0; // 100m
  static const double goodAccuracyThreshold = 50.0; // 50m

  // Speed thresholds (m/s)
  static const double maxRealisticSpeed = 50.0; // ~180 km/h (car on highway)
  static const double warningSpeed = 30.0; // ~108 km/h

  // Time threshold untuk speed calculation
  static const int minTimeDiffSeconds = 5; // Minimum 5 detik

  // Earth radius untuk Haversine formula (meters)
  static const double earthRadius = 6371000.0;

  /// Validate single location dengan optional previous location untuk speed check
  ///
  /// Returns:
  /// - [ValidationResult.valid()] - Location valid
  /// - [ValidationResult.warning()] - Location acceptable tapi ada concern
  /// - [ValidationResult.invalid()] - Location harus rejected
  static ValidationResult validate(
    models.Location current, {
    models.Location? previous,
  }) {
    // 1. Coordinate bounds check
    final boundsResult = _validateCoordinateBounds(current);
    if (boundsResult.isInvalid) return boundsResult;

    // 2. Accuracy check
    final accuracyResult = _validateAccuracy(current);
    if (accuracyResult.isInvalid) return accuracyResult;

    // 3. Speed check (jika ada previous location)
    if (previous != null) {
      final speedResult = _validateSpeed(current, previous);
      if (speedResult.isInvalid) return speedResult;
      if (speedResult.isWarning) return speedResult; // Return warning
    }

    // Semua checks passed
    if (accuracyResult.isWarning) {
      return accuracyResult; // Return accuracy warning
    }
    return ValidationResult.valid();
  }

  /// Validate coordinate bounds (WGS84 limits)
  static ValidationResult _validateCoordinateBounds(models.Location location) {
    if (location.latitude < minLatitude || location.latitude > maxLatitude) {
      return ValidationResult.invalid(
        'Latitude invalid: ${location.latitude} (harus antara $minLatitude dan $maxLatitude)',
      );
    }

    if (location.longitude < minLongitude ||
        location.longitude > maxLongitude) {
      return ValidationResult.invalid(
        'Longitude invalid: ${location.longitude} (harus antara $minLongitude dan $maxLongitude)',
      );
    }

    return ValidationResult.valid();
  }

  /// Validate GPS accuracy
  static ValidationResult _validateAccuracy(models.Location location) {
    final accuracy = location.accuracy;

    // Null accuracy = unknown accuracy (warning)
    if (accuracy == null) {
      return ValidationResult.warning('Akurasi GPS tidak diketahui');
    }

    // Negative accuracy = invalid
    if (accuracy < 0) {
      return ValidationResult.invalid(
        'Akurasi GPS invalid: $accuracy m (tidak boleh negatif)',
      );
    }

    // Poor accuracy = invalid (reject)
    if (accuracy > maxAcceptableAccuracy) {
      return ValidationResult.invalid(
        'Akurasi GPS terlalu rendah: ${accuracy.toStringAsFixed(1)}m (maksimal ${maxAcceptableAccuracy}m)',
      );
    }

    // Medium accuracy = warning (accept dengan concern)
    if (accuracy > goodAccuracyThreshold) {
      return ValidationResult.warning(
        'Akurasi GPS sedang: ${accuracy.toStringAsFixed(1)}m',
      );
    }

    // Good accuracy
    return ValidationResult.valid();
  }

  /// Validate speed between two locations (detect unrealistic movement)
  static ValidationResult _validateSpeed(
    models.Location current,
    models.Location previous,
  ) {
    // Calculate time difference
    final timeDiff = current.timestamp.difference(previous.timestamp);
    final seconds = timeDiff.inSeconds;

    // Skip jika time difference terlalu kecil
    if (seconds < minTimeDiffSeconds) {
      return ValidationResult.warning(
        'Lokasi terlalu dekat waktu: ${seconds}s (minimum ${minTimeDiffSeconds}s)',
      );
    }

    // Calculate distance using Haversine formula
    final distance = _calculateDistance(
      previous.latitude,
      previous.longitude,
      current.latitude,
      current.longitude,
    );

    // Calculate speed (m/s)
    final speed = distance / seconds;

    // Unrealistic speed = invalid (possible GPS jump or spoofing)
    if (speed > maxRealisticSpeed) {
      return ValidationResult.invalid(
        'Kecepatan tidak realistis: ${speed.toStringAsFixed(1)} m/s '
        '(~${(speed * 3.6).toStringAsFixed(0)} km/h) - '
        'maksimal ${(maxRealisticSpeed * 3.6).toStringAsFixed(0)} km/h',
      );
    }

    // High speed = warning (accept tapi flag)
    if (speed > warningSpeed) {
      return ValidationResult.warning(
        'Kecepatan tinggi: ${speed.toStringAsFixed(1)} m/s '
        '(~${(speed * 3.6).toStringAsFixed(0)} km/h)',
      );
    }

    return ValidationResult.valid();
  }

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in meters
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    // Convert to radians
    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    // Haversine formula
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c; // Distance in meters
  }

  /// Convert degrees to radians
  static double _toRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Batch validate multiple locations
  /// Returns map of location ID to validation result
  static Map<String, ValidationResult> validateBatch(
    List<models.Location> locations,
  ) {
    final results = <String, ValidationResult>{};

    for (var i = 0; i < locations.length; i++) {
      final current = locations[i];
      final previous = i > 0 ? locations[i - 1] : null;

      results[current.id.toString()] = validate(current, previous: previous);
    }

    return results;
  }

  /// Check if location seems like GPS spoofing
  ///
  /// Indicators:
  /// - Exact same coordinates multiple times
  /// - Perfect round numbers
  /// - Impossible speed changes
  static bool isPossibleSpoofing(
    models.Location current, {
    models.Location? previous,
  }) {
    // Check for exact duplicate coordinates
    if (previous != null) {
      if (current.latitude == previous.latitude &&
          current.longitude == previous.longitude) {
        // Same coordinates = suspicious (real GPS has noise)
        return true;
      }

      // Check for perfect round numbers (e.g., 0.000000)
      if (_isPerfectRound(current.latitude) &&
          _isPerfectRound(current.longitude)) {
        return true;
      }
    }

    return false;
  }

  /// Check if number is suspiciously round (possible fake GPS)
  static bool _isPerfectRound(double value) {
    final decimal = (value * 1000000) % 1000000;
    return decimal == 0.0;
  }
}
