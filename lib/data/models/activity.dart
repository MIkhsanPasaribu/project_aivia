/// Model untuk aktivitas harian
class Activity {
  final String id;
  final String patientId;
  final String title;
  final String? description;
  final DateTime activityTime;
  final bool reminderSent;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? pickupByProfileId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Activity({
    required this.id,
    required this.patientId,
    required this.title,
    this.description,
    required this.activityTime,
    this.reminderSent = false,
    this.isCompleted = false,
    this.completedAt,
    this.pickupByProfileId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create dari JSON
  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      activityTime: DateTime.parse(json['activity_time'] as String),
      reminderSent: json['reminder_sent'] as bool? ?? false,
      isCompleted: json['is_completed'] as bool? ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      pickupByProfileId: json['pickup_by_profile_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'title': title,
      'description': description,
      'activity_time': activityTime.toIso8601String(),
      'reminder_sent': reminderSent,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'pickup_by_profile_id': pickupByProfileId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Convert ke JSON untuk insert/update (tanpa id dan timestamps)
  Map<String, dynamic> toInsertJson() {
    return {
      'patient_id': patientId,
      'title': title,
      'description': description,
      'activity_time': activityTime.toIso8601String(),
      'reminder_sent': reminderSent,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toIso8601String(),
      'pickup_by_profile_id': pickupByProfileId,
    };
  }

  /// Copy with
  Activity copyWith({
    String? id,
    String? patientId,
    String? title,
    String? description,
    DateTime? activityTime,
    bool? reminderSent,
    bool? isCompleted,
    DateTime? completedAt,
    String? pickupByProfileId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Activity(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      title: title ?? this.title,
      description: description ?? this.description,
      activityTime: activityTime ?? this.activityTime,
      reminderSent: reminderSent ?? this.reminderSent,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      pickupByProfileId: pickupByProfileId ?? this.pickupByProfileId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Cek apakah aktivitas sudah lewat
  bool get isPast {
    return activityTime.isBefore(DateTime.now());
  }

  /// Cek apakah aktivitas hari ini
  bool get isToday {
    final now = DateTime.now();
    return activityTime.year == now.year &&
        activityTime.month == now.month &&
        activityTime.day == now.day;
  }

  @override
  String toString() {
    return 'Activity(id: $id, title: $title, activityTime: $activityTime, isCompleted: $isCompleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Activity &&
        other.id == id &&
        other.patientId == patientId &&
        other.title == title &&
        other.description == description &&
        other.activityTime == activityTime &&
        other.reminderSent == reminderSent &&
        other.isCompleted == isCompleted &&
        other.completedAt == completedAt &&
        other.pickupByProfileId == pickupByProfileId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        patientId.hashCode ^
        title.hashCode ^
        description.hashCode ^
        activityTime.hashCode ^
        reminderSent.hashCode ^
        isCompleted.hashCode ^
        completedAt.hashCode ^
        pickupByProfileId.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
