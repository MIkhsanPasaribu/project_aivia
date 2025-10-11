/// Model untuk kontak darurat pasien
///
/// Mewakili kontak darurat yang akan dihubungi ketika terjadi emergency alert.
/// Kontak diurutkan berdasarkan prioritas (1 = tertinggi).
class EmergencyContact {
  final String id;
  final String patientId;
  final String contactId;
  final int priority;
  final bool notificationEnabled;
  final DateTime createdAt;

  const EmergencyContact({
    required this.id,
    required this.patientId,
    required this.contactId,
    required this.priority,
    required this.notificationEnabled,
    required this.createdAt,
  });

  /// Membuat [EmergencyContact] dari JSON response Supabase
  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      contactId: json['contact_id'] as String,
      priority: json['priority'] as int,
      notificationEnabled: json['notification_enabled'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Mengkonversi [EmergencyContact] ke JSON untuk insert/update Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'contact_id': contactId,
      'priority': priority,
      'notification_enabled': notificationEnabled,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Membuat salinan dengan field yang diubah
  EmergencyContact copyWith({
    String? id,
    String? patientId,
    String? contactId,
    int? priority,
    bool? notificationEnabled,
    DateTime? createdAt,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      contactId: contactId ?? this.contactId,
      priority: priority ?? this.priority,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Label prioritas untuk UI (1 = "Prioritas Tinggi", 2 = "Prioritas Sedang", dst)
  String get priorityLabel {
    switch (priority) {
      case 1:
        return 'Prioritas Tinggi';
      case 2:
        return 'Prioritas Sedang';
      case 3:
        return 'Prioritas Rendah';
      default:
        return 'Prioritas $priority';
    }
  }

  /// Status notifikasi untuk UI
  String get notificationStatusLabel {
    return notificationEnabled ? 'Notifikasi Aktif' : 'Notifikasi Nonaktif';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is EmergencyContact &&
        other.id == id &&
        other.patientId == patientId &&
        other.contactId == contactId &&
        other.priority == priority &&
        other.notificationEnabled == notificationEnabled &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      patientId,
      contactId,
      priority,
      notificationEnabled,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'EmergencyContact(id: $id, patientId: $patientId, contactId: $contactId, '
        'priority: $priority, notificationEnabled: $notificationEnabled, '
        'createdAt: $createdAt)';
  }
}
