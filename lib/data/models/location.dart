/// Location model untuk tracking lokasi patient
/// Corresponds to `locations` table in Supabase
class Location {
  final int? id;
  final String patientId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime timestamp;

  const Location({
    this.id,
    required this.patientId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.timestamp,
  });

  /// Create Location from Supabase JSON
  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] as int?,
      patientId: json['patient_id'] as String,
      latitude: _parseCoordinate(json, 'latitude'),
      longitude: _parseCoordinate(json, 'longitude'),
      accuracy: json['accuracy'] != null
          ? (json['accuracy'] as num?)?.toDouble()
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Parse coordinate dari PostGIS geography atau langsung dari field
  static double _parseCoordinate(Map<String, dynamic> json, String field) {
    // Jika ada field langsung (untuk insert)
    if (json.containsKey(field)) {
      return (json[field] as num?)?.toDouble() ?? 0.0;
    }

    // Jika dari PostGIS POINT format: "POINT(longitude latitude)"
    if (json.containsKey('coordinates')) {
      final coords = json['coordinates'] as String;
      final match = RegExp(
        r'POINT\((-?\d+\.?\d*)\s+(-?\d+\.?\d*)\)',
      ).firstMatch(coords);
      if (match != null) {
        if (field == 'longitude') {
          return double.parse(match.group(1)!);
        } else {
          return double.parse(match.group(2)!);
        }
      }
    }

    throw ArgumentError('Cannot parse $field from JSON: $json');
  }

  /// Convert Location to Supabase JSON for insert/update
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patient_id': patientId,
      // PostGIS format: POINT(longitude latitude)
      'coordinates': 'POINT($longitude $latitude)',
      if (accuracy != null) 'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Create copy with modified fields
  Location copyWith({
    int? id,
    String? patientId,
    double? latitude,
    double? longitude,
    double? accuracy,
    DateTime? timestamp,
  }) {
    return Location(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Get formatted address (simplified - for display only)
  String get formattedLocation {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  /// Get accuracy label for UI
  String get accuracyLabel {
    if (accuracy == null) return 'Unknown';
    if (accuracy! < 10) return 'Sangat Akurat';
    if (accuracy! < 50) return 'Akurat';
    if (accuracy! < 100) return 'Cukup Akurat';
    return 'Kurang Akurat';
  }

  /// Check if location is recent (within last 5 minutes)
  bool get isRecent {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference.inMinutes < 5;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Location &&
        other.id == id &&
        other.patientId == patientId &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.accuracy == accuracy &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(id, patientId, latitude, longitude, accuracy, timestamp);
  }

  @override
  String toString() {
    return 'Location(id: $id, patientId: $patientId, '
        'lat: ${latitude.toStringAsFixed(6)}, '
        'lng: ${longitude.toStringAsFixed(6)}, '
        'accuracy: $accuracy, timestamp: $timestamp)';
  }
}
