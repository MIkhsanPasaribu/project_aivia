import 'package:flutter/foundation.dart';

/// **Geofence Event Model**
///
/// Represents event ketika pasien masuk/keluar zona geografis
///
/// Corresponds to `public.geofence_events` table di Supabase
///
/// **Event Types**:
/// - `enter`: Pasien masuk zona geografis
/// - `exit`: Pasien keluar dari zona geografis
@immutable
class GeofenceEvent {
  /// Unique ID (UUID)
  final String id;

  /// ID geofence yang di-trigger
  final String geofenceId;

  /// ID lokasi yang trigger event
  final int locationId;

  /// Tipe event (enter/exit)
  final GeofenceEventType eventType;

  /// ID pasien yang trigger event
  final String patientId;

  /// Jarak dari center geofence (meters)
  final double? distanceFromCenter;

  /// Sudah notified ke family members?
  final bool notified;

  /// Timestamp notified
  final DateTime? notifiedAt;

  /// Array ID family members yang sudah di-notified
  final List<String> notificationSentTo;

  /// Metadata tambahan (JSON)
  final Map<String, dynamic>? metadata;

  /// Timestamp event detected
  final DateTime detectedAt;

  /// Timestamp created
  final DateTime createdAt;

  const GeofenceEvent({
    required this.id,
    required this.geofenceId,
    required this.locationId,
    required this.eventType,
    required this.patientId,
    this.distanceFromCenter,
    this.notified = false,
    this.notifiedAt,
    this.notificationSentTo = const [],
    this.metadata,
    required this.detectedAt,
    required this.createdAt,
  });

  /// Create GeofenceEvent from Supabase JSON
  factory GeofenceEvent.fromJson(Map<String, dynamic> json) {
    return GeofenceEvent(
      id: json['id'] as String,
      geofenceId: json['geofence_id'] as String,
      locationId: json['location_id'] as int,
      eventType: _parseEventType(json['event_type'] as String),
      patientId: json['patient_id'] as String,
      distanceFromCenter: json['distance_from_center'] != null
          ? (json['distance_from_center'] as num).toDouble()
          : null,
      notified: json['notified'] as bool? ?? false,
      notifiedAt: json['notified_at'] != null
          ? DateTime.parse(json['notified_at'] as String)
          : null,
      notificationSentTo: json['notification_sent_to'] != null
          ? List<String>.from(json['notification_sent_to'] as List)
          : const [],
      metadata: json['metadata'] as Map<String, dynamic>?,
      detectedAt: DateTime.parse(json['detected_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert GeofenceEvent to JSON untuk Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'geofence_id': geofenceId,
      'location_id': locationId,
      'event_type': eventType.toDbString(),
      'patient_id': patientId,
      'distance_from_center': distanceFromCenter,
      'notified': notified,
      'notified_at': notifiedAt?.toIso8601String(),
      'notification_sent_to': notificationSentTo,
      'metadata': metadata,
      'detected_at': detectedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Parse event type dari database string
  static GeofenceEventType _parseEventType(String type) {
    switch (type) {
      case 'enter':
        return GeofenceEventType.enter;
      case 'exit':
        return GeofenceEventType.exit;
      default:
        throw ArgumentError('Unknown geofence event type: $type');
    }
  }

  /// Copy with method untuk immutable updates
  GeofenceEvent copyWith({
    String? id,
    String? geofenceId,
    int? locationId,
    GeofenceEventType? eventType,
    String? patientId,
    double? distanceFromCenter,
    bool? notified,
    DateTime? notifiedAt,
    List<String>? notificationSentTo,
    Map<String, dynamic>? metadata,
    DateTime? detectedAt,
    DateTime? createdAt,
  }) {
    return GeofenceEvent(
      id: id ?? this.id,
      geofenceId: geofenceId ?? this.geofenceId,
      locationId: locationId ?? this.locationId,
      eventType: eventType ?? this.eventType,
      patientId: patientId ?? this.patientId,
      distanceFromCenter: distanceFromCenter ?? this.distanceFromCenter,
      notified: notified ?? this.notified,
      notifiedAt: notifiedAt ?? this.notifiedAt,
      notificationSentTo: notificationSentTo ?? this.notificationSentTo,
      metadata: metadata ?? this.metadata,
      detectedAt: detectedAt ?? this.detectedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'GeofenceEvent(id: $id, type: ${eventType.displayName}, '
        'geofence: $geofenceId, notified: $notified)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GeofenceEvent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// **Geofence Event Type Enum**
///
/// Tipe event geofencing
enum GeofenceEventType {
  /// Pasien masuk zona geografis
  enter,

  /// Pasien keluar dari zona geografis
  exit,
}

/// Extension untuk GeofenceEventType
extension GeofenceEventTypeExtension on GeofenceEventType {
  /// Display name untuk UI (Bahasa Indonesia)
  String get displayName {
    switch (this) {
      case GeofenceEventType.enter:
        return 'Masuk Zona';
      case GeofenceEventType.exit:
        return 'Keluar Zona';
    }
  }

  /// Database string value
  String toDbString() {
    switch (this) {
      case GeofenceEventType.enter:
        return 'enter';
      case GeofenceEventType.exit:
        return 'exit';
    }
  }

  /// Icon untuk UI
  String get iconName {
    switch (this) {
      case GeofenceEventType.enter:
        return 'arrow_downward'; // masuk
      case GeofenceEventType.exit:
        return 'arrow_upward'; // keluar
    }
  }

  /// Warna untuk UI (hex string)
  String get colorHex {
    switch (this) {
      case GeofenceEventType.enter:
        return '#4CAF50'; // Green untuk masuk zona aman
      case GeofenceEventType.exit:
        return '#FF9800'; // Orange untuk keluar zona
    }
  }
}
