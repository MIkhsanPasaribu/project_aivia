import 'package:flutter/foundation.dart';

/// **Geofence Model**
///
/// Represents zona geografis (safe/danger zones) untuk monitoring pasien
///
/// Corresponds to `public.geofences` table di Supabase
///
/// **Tipe Zona**:
/// - `safe`: Zona aman (rumah, sekolah, rumah sakit)
/// - `danger`: Zona bahaya (jalan raya, area tidak aman)
/// - `home`: Zona rumah (special safe zone)
/// - `hospital`: Fasilitas medis
/// - `school`: Institusi pendidikan
/// - `custom`: Zona custom user-defined
@immutable
class Geofence {
  /// Unique ID (UUID)
  final String id;

  /// ID pasien yang di-monitor
  final String patientId;

  /// Nama zona (contoh: "Rumah", "Sekolah", "RS Siloam")
  final String name;

  /// Deskripsi zona (optional)
  final String? description;

  /// Jenis zona geografis
  final FenceType fenceType;

  /// Latitude center point
  final double latitude;

  /// Longitude center point
  final double longitude;

  /// Radius dalam meters (50m - 10,000m)
  final int radiusMeters;

  /// Status aktif/nonaktif
  final bool isActive;

  /// Alert saat masuk zona?
  final bool alertOnEnter;

  /// Alert saat keluar zona?
  final bool alertOnExit;

  /// Priority (1 = tertinggi, 10 = terendah)
  final int priority;

  /// Alamat human-readable (optional)
  final String? address;

  /// Metadata tambahan (JSON)
  final Map<String, dynamic>? metadata;

  /// Dibuat oleh (family member ID)
  final String? createdBy;

  /// Timestamp dibuat
  final DateTime createdAt;

  /// Timestamp terakhir diupdate
  final DateTime updatedAt;

  const Geofence({
    required this.id,
    required this.patientId,
    required this.name,
    this.description,
    required this.fenceType,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.isActive = true,
    this.alertOnEnter = true,
    this.alertOnExit = true,
    this.priority = 5,
    this.address,
    this.metadata,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create Geofence from Supabase JSON
  ///
  /// Handles PostGIS GEOGRAPHY(POINT) format:
  /// - Format: "POINT(longitude latitude)"
  /// - Example: "POINT(106.8456 -6.2088)"
  factory Geofence.fromJson(Map<String, dynamic> json) {
    // Parse PostGIS POINT format
    final coords = _parseGeographyPoint(json['center_coordinates'] as String);

    return Geofence(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      fenceType: _parseFenceType(json['fence_type'] as String),
      latitude: coords['latitude']!,
      longitude: coords['longitude']!,
      radiusMeters: json['radius_meters'] as int,
      isActive: json['is_active'] as bool? ?? true,
      alertOnEnter: json['alert_on_enter'] as bool? ?? true,
      alertOnExit: json['alert_on_exit'] as bool? ?? true,
      priority: json['priority'] as int? ?? 5,
      address: json['address'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert Geofence to JSON untuk Supabase
  ///
  /// Converts lat/lng to PostGIS POINT format
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'name': name,
      'description': description,
      'fence_type': fenceType.toDbString(),
      // PostGIS POINT format: POINT(longitude latitude)
      'center_coordinates': 'POINT($longitude $latitude)',
      'radius_meters': radiusMeters,
      'is_active': isActive,
      'alert_on_enter': alertOnEnter,
      'alert_on_exit': alertOnExit,
      'priority': priority,
      'address': address,
      'metadata': metadata,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Parse PostGIS GEOGRAPHY(POINT) format
  ///
  /// Input: "POINT(106.8456 -6.2088)"
  /// Output: {latitude: -6.2088, longitude: 106.8456}
  static Map<String, double> _parseGeographyPoint(String point) {
    // Remove "POINT(" and ")"
    final coords = point
        .replaceAll('POINT(', '')
        .replaceAll(')', '')
        .split(' ');

    return {
      'longitude': double.parse(coords[0]),
      'latitude': double.parse(coords[1]),
    };
  }

  /// Parse fence type dari database string
  static FenceType _parseFenceType(String type) {
    switch (type) {
      case 'safe':
        return FenceType.safe;
      case 'danger':
        return FenceType.danger;
      case 'home':
        return FenceType.home;
      case 'hospital':
        return FenceType.hospital;
      case 'school':
        return FenceType.school;
      case 'custom':
      default:
        return FenceType.custom;
    }
  }

  /// Copy with method untuk immutable updates
  Geofence copyWith({
    String? id,
    String? patientId,
    String? name,
    String? description,
    FenceType? fenceType,
    double? latitude,
    double? longitude,
    int? radiusMeters,
    bool? isActive,
    bool? alertOnEnter,
    bool? alertOnExit,
    int? priority,
    String? address,
    Map<String, dynamic>? metadata,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Geofence(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      description: description ?? this.description,
      fenceType: fenceType ?? this.fenceType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      isActive: isActive ?? this.isActive,
      alertOnEnter: alertOnEnter ?? this.alertOnEnter,
      alertOnExit: alertOnExit ?? this.alertOnExit,
      priority: priority ?? this.priority,
      address: address ?? this.address,
      metadata: metadata ?? this.metadata,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Geofence(id: $id, name: $name, type: ${fenceType.displayName}, '
        'radius: ${radiusMeters}m, active: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Geofence && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// **Fence Type Enum**
///
/// Jenis-jenis zona geografis yang didukung
enum FenceType {
  /// Zona aman (rumah, sekolah, rumah sakit)
  safe,

  /// Zona bahaya (jalan raya, area tidak aman)
  danger,

  /// Zona rumah (special safe zone)
  home,

  /// Fasilitas medis
  hospital,

  /// Institusi pendidikan
  school,

  /// Zona custom user-defined
  custom,
}

/// Extension untuk FenceType
extension FenceTypeExtension on FenceType {
  /// Display name untuk UI (Bahasa Indonesia)
  String get displayName {
    switch (this) {
      case FenceType.safe:
        return 'Zona Aman';
      case FenceType.danger:
        return 'Zona Bahaya';
      case FenceType.home:
        return 'Rumah';
      case FenceType.hospital:
        return 'Rumah Sakit';
      case FenceType.school:
        return 'Sekolah';
      case FenceType.custom:
        return 'Custom';
    }
  }

  /// Database string value
  String toDbString() {
    switch (this) {
      case FenceType.safe:
        return 'safe';
      case FenceType.danger:
        return 'danger';
      case FenceType.home:
        return 'home';
      case FenceType.hospital:
        return 'hospital';
      case FenceType.school:
        return 'school';
      case FenceType.custom:
        return 'custom';
    }
  }

  /// Icon untuk UI
  /// Returns Material icon name yang sesuai
  String get iconName {
    switch (this) {
      case FenceType.safe:
        return 'shield';
      case FenceType.danger:
        return 'warning';
      case FenceType.home:
        return 'home';
      case FenceType.hospital:
        return 'local_hospital';
      case FenceType.school:
        return 'school';
      case FenceType.custom:
        return 'location_on';
    }
  }
}
