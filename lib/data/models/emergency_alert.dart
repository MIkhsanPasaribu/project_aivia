/// Model untuk peringatan darurat yang dipicu oleh pasien
///
/// Melacak emergency alerts dengan informasi lokasi, status, severity,
/// dan tracking resolusi oleh anggota keluarga.
class EmergencyAlert {
  final String id;
  final String patientId;
  final double? latitude;
  final double? longitude;
  final String message;
  final String
  alertType; // panic_button, fall_detection, geofence_exit, no_activity
  final String status; // active, acknowledged, resolved, false_alarm
  final String severity; // low, medium, high, critical
  final String? notes;
  final String? resolvedBy;
  final DateTime createdAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;

  const EmergencyAlert({
    required this.id,
    required this.patientId,
    this.latitude,
    this.longitude,
    required this.message,
    required this.alertType,
    required this.status,
    required this.severity,
    this.notes,
    this.resolvedBy,
    required this.createdAt,
    this.acknowledgedAt,
    this.resolvedAt,
  });

  /// Membuat [EmergencyAlert] dari JSON response Supabase
  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    // Parse PostGIS POINT format jika ada
    double? lat;
    double? lng;

    if (json['location'] != null) {
      final locationStr = json['location'] as String;
      // Format: "POINT(longitude latitude)" or direct "SRID=4326;POINT(...)"
      final coordPattern = RegExp(r'POINT\s*\(\s*([-\d.]+)\s+([-\d.]+)\s*\)');
      final match = coordPattern.firstMatch(locationStr);

      if (match != null) {
        lng = double.tryParse(match.group(1)!);
        lat = double.tryParse(match.group(2)!);
      }
    }

    return EmergencyAlert(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      latitude: lat,
      longitude: lng,
      message: json['message'] as String? ?? 'Peringatan Darurat!',
      alertType: json['alert_type'] as String? ?? 'panic_button',
      status: json['status'] as String? ?? 'active',
      severity: json['severity'] as String? ?? 'high',
      notes: json['notes'] as String?,
      resolvedBy: json['resolved_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      acknowledgedAt: json['acknowledged_at'] != null
          ? DateTime.parse(json['acknowledged_at'] as String)
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
    );
  }

  /// Mengkonversi [EmergencyAlert] ke JSON untuk insert/update Supabase
  Map<String, dynamic> toJson() {
    // Format PostGIS POINT jika koordinat tersedia
    String? locationStr;
    if (latitude != null && longitude != null) {
      locationStr = 'POINT($longitude $latitude)';
    }

    return {
      'id': id,
      'patient_id': patientId,
      'location': locationStr,
      'message': message,
      'alert_type': alertType,
      'status': status,
      'severity': severity,
      'notes': notes,
      'resolved_by': resolvedBy,
      'created_at': createdAt.toIso8601String(),
      'acknowledged_at': acknowledgedAt?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  /// Membuat salinan dengan field yang diubah
  EmergencyAlert copyWith({
    String? id,
    String? patientId,
    double? latitude,
    double? longitude,
    String? message,
    String? alertType,
    String? status,
    String? severity,
    String? notes,
    String? resolvedBy,
    DateTime? createdAt,
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
  }) {
    return EmergencyAlert(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      message: message ?? this.message,
      alertType: alertType ?? this.alertType,
      status: status ?? this.status,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      createdAt: createdAt ?? this.createdAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  /// Apakah alert masih aktif
  bool get isActive => status == 'active';

  /// Apakah alert sudah di-acknowledge
  bool get isAcknowledged => status == 'acknowledged' || status == 'resolved';

  /// Apakah alert sudah di-resolve
  bool get isResolved => status == 'resolved' || status == 'false_alarm';

  /// Label status untuk UI
  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'acknowledged':
        return 'Diterima';
      case 'resolved':
        return 'Selesai';
      case 'false_alarm':
        return 'Alarm Palsu';
      default:
        return status;
    }
  }

  /// Label tipe alert untuk UI
  String get alertTypeLabel {
    switch (alertType) {
      case 'panic_button':
        return 'Tombol Panik';
      case 'fall_detection':
        return 'Deteksi Jatuh';
      case 'geofence_exit':
        return 'Keluar Area';
      case 'no_activity':
        return 'Tidak Ada Aktivitas';
      default:
        return alertType;
    }
  }

  /// Label severity untuk UI
  String get severityLabel {
    switch (severity) {
      case 'low':
        return 'Rendah';
      case 'medium':
        return 'Sedang';
      case 'high':
        return 'Tinggi';
      case 'critical':
        return 'Kritis';
      default:
        return severity;
    }
  }

  /// Lokasi dalam format string untuk UI
  String get formattedLocation {
    if (latitude != null && longitude != null) {
      return '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}';
    }
    return 'Lokasi tidak tersedia';
  }

  /// Apakah alert memiliki lokasi
  bool get hasLocation => latitude != null && longitude != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EmergencyAlert &&
        other.id == id &&
        other.patientId == patientId &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.message == message &&
        other.alertType == alertType &&
        other.status == status &&
        other.severity == severity &&
        other.notes == notes &&
        other.resolvedBy == resolvedBy &&
        other.createdAt == createdAt &&
        other.acknowledgedAt == acknowledgedAt &&
        other.resolvedAt == resolvedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      patientId,
      latitude,
      longitude,
      message,
      alertType,
      status,
      severity,
      notes,
      resolvedBy,
      createdAt,
      acknowledgedAt,
      resolvedAt,
    );
  }

  @override
  String toString() {
    return 'EmergencyAlert(id: $id, patientId: $patientId, '
        'message: $message, alertType: $alertType, status: $status, '
        'severity: $severity, createdAt: $createdAt)';
  }
}
