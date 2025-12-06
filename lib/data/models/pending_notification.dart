import 'package:flutter/foundation.dart';

/// **Pending Notification Model**
///
/// Represents notifikasi yang belum terkirim dalam queue
///
/// Corresponds to `public.pending_notifications` table di Supabase
///
/// **Notification Types**:
/// - `emergency`: Notifikasi emergency alert
/// - `geofence`: Notifikasi geofence enter/exit
/// - `activity`: Notifikasi aktivitas reminder
/// - `reminder`: Notifikasi reminder umum
/// - `system`: Notifikasi sistem
///
/// **Status**:
/// - `pending`: Menunggu dikirim
/// - `sent`: Berhasil dikirim ke semua penerima
/// - `failed`: Gagal dikirim
/// - `partial`: Sebagian terkirim, sebagian gagal
@immutable
class PendingNotification {
  /// Unique ID (UUID)
  final String id;

  /// ID user penerima notifikasi
  final String recipientUserId;

  /// Tipe notifikasi
  final NotificationType notificationType;

  /// Judul notifikasi
  final String title;

  /// Isi notifikasi
  final String body;

  /// Data tambahan (JSON) untuk navigation & actions
  final Map<String, dynamic> data;

  /// Status notifikasi
  final NotificationStatus status;

  /// Scheduled time (kapan harus dikirim)
  final DateTime scheduledAt;

  /// Timestamp sent (kapan dikirim)
  final DateTime? sentAt;

  /// Priority (1-10, 10 = tertinggi)
  final int priority;

  /// Retry count
  final int retryCount;

  /// Max retries allowed
  final int maxRetries;

  /// Timestamp created
  final DateTime createdAt;

  /// Timestamp updated
  final DateTime updatedAt;

  const PendingNotification({
    required this.id,
    required this.recipientUserId,
    required this.notificationType,
    required this.title,
    required this.body,
    this.data = const {},
    this.status = NotificationStatus.pending,
    required this.scheduledAt,
    this.sentAt,
    this.priority = 5,
    this.retryCount = 0,
    this.maxRetries = 3,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create PendingNotification from Supabase JSON
  factory PendingNotification.fromJson(Map<String, dynamic> json) {
    return PendingNotification(
      id: json['id'] as String,
      recipientUserId: json['recipient_user_id'] as String,
      notificationType: _parseNotificationType(
        json['notification_type'] as String,
      ),
      title: json['title'] as String,
      body: json['body'] as String,
      data: json['data'] as Map<String, dynamic>? ?? {},
      status: _parseStatus(json['status'] as String),
      scheduledAt: DateTime.parse(json['scheduled_at'] as String),
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'] as String)
          : null,
      priority: json['priority'] as int? ?? 5,
      retryCount: json['retry_count'] as int? ?? 0,
      maxRetries: json['max_retries'] as int? ?? 3,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// Convert PendingNotification to JSON untuk Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient_user_id': recipientUserId,
      'notification_type': notificationType.toDbString(),
      'title': title,
      'body': body,
      'data': data,
      'status': status.toDbString(),
      'scheduled_at': scheduledAt.toIso8601String(),
      'sent_at': sentAt?.toIso8601String(),
      'priority': priority,
      'retry_count': retryCount,
      'max_retries': maxRetries,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Parse notification type dari database string
  static NotificationType _parseNotificationType(String type) {
    switch (type) {
      case 'emergency':
        return NotificationType.emergency;
      case 'geofence':
        return NotificationType.geofence;
      case 'activity':
        return NotificationType.activity;
      case 'reminder':
        return NotificationType.reminder;
      case 'system':
        return NotificationType.system;
      default:
        throw ArgumentError('Unknown notification type: $type');
    }
  }

  /// Parse status dari database string
  static NotificationStatus _parseStatus(String status) {
    switch (status) {
      case 'pending':
        return NotificationStatus.pending;
      case 'sent':
        return NotificationStatus.sent;
      case 'failed':
        return NotificationStatus.failed;
      case 'partial':
        return NotificationStatus.partial;
      default:
        throw ArgumentError('Unknown notification status: $status');
    }
  }

  /// Copy with method untuk immutable updates
  PendingNotification copyWith({
    String? id,
    String? recipientUserId,
    NotificationType? notificationType,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    NotificationStatus? status,
    DateTime? scheduledAt,
    DateTime? sentAt,
    int? priority,
    int? retryCount,
    int? maxRetries,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PendingNotification(
      id: id ?? this.id,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      notificationType: notificationType ?? this.notificationType,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      status: status ?? this.status,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      sentAt: sentAt ?? this.sentAt,
      priority: priority ?? this.priority,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'PendingNotification(id: $id, type: ${notificationType.displayName}, '
        'status: ${status.displayName}, priority: $priority)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PendingNotification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// **Notification Type Enum**
///
/// Tipe-tipe notifikasi yang didukung
enum NotificationType {
  /// Notifikasi emergency alert
  emergency,

  /// Notifikasi geofence enter/exit
  geofence,

  /// Notifikasi aktivitas reminder
  activity,

  /// Notifikasi reminder umum
  reminder,

  /// Notifikasi sistem
  system,
}

/// Extension untuk NotificationType
extension NotificationTypeExtension on NotificationType {
  /// Display name untuk UI (Bahasa Indonesia)
  String get displayName {
    switch (this) {
      case NotificationType.emergency:
        return 'Darurat';
      case NotificationType.geofence:
        return 'Zona Geografis';
      case NotificationType.activity:
        return 'Aktivitas';
      case NotificationType.reminder:
        return 'Pengingat';
      case NotificationType.system:
        return 'Sistem';
    }
  }

  /// Database string value
  String toDbString() {
    switch (this) {
      case NotificationType.emergency:
        return 'emergency';
      case NotificationType.geofence:
        return 'geofence';
      case NotificationType.activity:
        return 'activity';
      case NotificationType.reminder:
        return 'reminder';
      case NotificationType.system:
        return 'system';
    }
  }
}

/// **Notification Status Enum**
///
/// Status notifikasi dalam queue
enum NotificationStatus {
  /// Menunggu dikirim
  pending,

  /// Berhasil dikirim ke semua penerima
  sent,

  /// Gagal dikirim
  failed,

  /// Sebagian terkirim, sebagian gagal
  partial,
}

/// Extension untuk NotificationStatus
extension NotificationStatusExtension on NotificationStatus {
  /// Display name untuk UI (Bahasa Indonesia)
  String get displayName {
    switch (this) {
      case NotificationStatus.pending:
        return 'Menunggu';
      case NotificationStatus.sent:
        return 'Terkirim';
      case NotificationStatus.failed:
        return 'Gagal';
      case NotificationStatus.partial:
        return 'Sebagian Terkirim';
    }
  }

  /// Database string value
  String toDbString() {
    switch (this) {
      case NotificationStatus.pending:
        return 'pending';
      case NotificationStatus.sent:
        return 'sent';
      case NotificationStatus.failed:
        return 'failed';
      case NotificationStatus.partial:
        return 'partial';
    }
  }

  /// Warna untuk UI (hex string)
  String get colorHex {
    switch (this) {
      case NotificationStatus.pending:
        return '#FFC107'; // Amber - menunggu
      case NotificationStatus.sent:
        return '#4CAF50'; // Green - sukses
      case NotificationStatus.failed:
        return '#F44336'; // Red - gagal
      case NotificationStatus.partial:
        return '#FF9800'; // Orange - partial
    }
  }
}
