import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../main.dart'; // For navigatorKey

/// Service untuk mengelola local notifications menggunakan Awesome Notifications
///
/// Features:
/// - Initialize notification channels
/// - Schedule activity reminders
/// - Handle notification actions
/// - Request permissions
/// - Notification with precise timing
///
/// Usage:
/// ```dart
/// // Initialize in main.dart
/// await NotificationService.initialize();
///
/// // Schedule reminder
/// await NotificationService.scheduleActivityReminder(
///   activityId: '123',
///   title: 'Minum Obat',
///   body: 'Saatnya minum obat pagi',
///   scheduledTime: DateTime.now().add(Duration(hours: 1)),
/// );
/// ```
class NotificationService {
  static const String _channelKey = 'activity_reminders';
  static const String _channelName = 'Pengingat Aktivitas';
  static const String _channelDescription =
      'Notifikasi pengingat untuk aktivitas harian';

  /// Initialize Awesome Notifications
  ///
  /// Harus dipanggil di main() sebelum runApp()
  static Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      // Icon untuk notification (gunakan app icon)
      null, // null akan gunakan default app icon
      [
        NotificationChannel(
          channelKey: _channelKey,
          channelName: _channelName,
          channelDescription: _channelDescription,
          defaultColor: AppColors.primary,
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        ),
      ],
      debug: false, // Set true untuk debugging
    );

    // Set listeners untuk notification actions
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: _onActionReceivedMethod,
      onNotificationCreatedMethod: _onNotificationCreatedMethod,
      onNotificationDisplayedMethod: _onNotificationDisplayedMethod,
      onDismissActionReceivedMethod: _onDismissActionReceivedMethod,
    );
  }

  /// Request notification permissions dari user
  ///
  /// Harus dipanggil sebelum schedule notifications
  /// Returns: true jika permission granted
  static Future<bool> requestPermissions() async {
    final isAllowed = await AwesomeNotifications().isNotificationAllowed();

    if (!isAllowed) {
      // Request permission dengan dialog
      return await AwesomeNotifications()
          .requestPermissionToSendNotifications();
    }

    return true;
  }

  /// Check apakah notifications diizinkan
  static Future<bool> isNotificationAllowed() async {
    return await AwesomeNotifications().isNotificationAllowed();
  }

  /// Schedule activity reminder notification
  ///
  /// [activityId] - ID aktivitas (untuk tracking)
  /// [title] - Judul aktivitas
  /// [body] - Deskripsi/detail aktivitas
  /// [scheduledTime] - Waktu notifikasi muncul
  /// [minutesBefore] - Menit sebelum waktu aktivitas (default: 15)
  static Future<void> scheduleActivityReminder({
    required String activityId,
    required String title,
    String? body,
    required DateTime scheduledTime,
    int minutesBefore = 15,
  }) async {
    // Check permission terlebih dahulu
    final isAllowed = await isNotificationAllowed();
    if (!isAllowed) {
      debugPrint('⚠️ Notification permission not granted');
      return;
    }

    // Hitung waktu notifikasi (X menit sebelum aktivitas)
    final notificationTime = scheduledTime.subtract(
      Duration(minutes: minutesBefore),
    );

    // Jangan schedule jika waktu sudah lewat
    if (notificationTime.isBefore(DateTime.now())) {
      debugPrint('⚠️ Notification time is in the past, skipping');
      return;
    }

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: activityId.hashCode, // Unique ID per activity
          channelKey: _channelKey,
          title: '⏰ Pengingat: $title',
          body: body ?? 'Saatnya melakukan aktivitas ini',
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Reminder,
          wakeUpScreen: true,
          criticalAlert: false,
          payload: {'activity_id': activityId, 'type': 'activity_reminder'},
        ),
        schedule: NotificationCalendar.fromDate(
          date: notificationTime,
          preciseAlarm: true, // Penting untuk exact timing
          allowWhileIdle: true,
        ),
      );

      debugPrint('✅ Notification scheduled for $notificationTime');
    } catch (e) {
      debugPrint('❌ Error scheduling notification: $e');
    }
  }

  /// Cancel notification for specific activity
  static Future<void> cancelActivityReminder(String activityId) async {
    try {
      await AwesomeNotifications().cancel(activityId.hashCode);
      debugPrint('✅ Notification cancelled for activity: $activityId');
    } catch (e) {
      debugPrint('❌ Error cancelling notification: $e');
    }
  }

  /// Cancel all scheduled notifications
  static Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
    debugPrint('✅ All notifications cancelled');
  }

  /// Get list of all scheduled notifications
  static Future<List<NotificationModel>> getScheduledNotifications() async {
    return await AwesomeNotifications().listScheduledNotifications();
  }

  /// Show immediate notification (tidak scheduled)
  ///
  /// Useful untuk testing atau notifikasi instant
  static Future<void> showImmediateNotification({
    required String title,
    required String body,
    Map<String, String>? payload,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        channelKey: _channelKey,
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        payload: payload,
      ),
    );
  }

  // ==================== NOTIFICATION LISTENERS ====================

  /// Called when notification is created (sebelum ditampilkan)
  @pragma('vm:entry-point')
  static Future<void> _onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    debugPrint('📱 Notification Created: ${receivedNotification.id}');
  }

  /// Called when notification is displayed (muncul di notification bar)
  @pragma('vm:entry-point')
  static Future<void> _onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    debugPrint('📱 Notification Displayed: ${receivedNotification.title}');
  }

  /// Called when user taps notification
  ///
  /// Handles navigation based on notification type:
  /// - activity_reminder → Navigate to activity detail
  /// - activity_pickup → Navigate to activity detail
  /// - emergency_alert → Navigate to emergency screen (family)
  /// - geofence_event → Navigate to patient map (family)
  @pragma('vm:entry-point')
  static Future<void> _onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    debugPrint('📱 Notification Tapped: ${receivedAction.title}');

    // Get notification payload
    if (receivedAction.payload == null || receivedAction.payload!.isEmpty) {
      debugPrint('⚠️ No payload, skipping navigation');
      return;
    }

    final payload = receivedAction.payload!;
    final type = payload['type'];

    debugPrint('   Type: $type');
    debugPrint('   Payload: $payload');

    // Import navigator key from main.dart
    // Navigate based on notification type
    try {
      final context = navigatorKey.currentContext;
      if (context == null) {
        debugPrint('⚠️ Navigator context not available');
        return;
      }

      switch (type) {
        case 'activity_reminder':
        case 'activity_pickup':
          // Navigate to activity detail (patient view)
          final activityId = payload['activity_id'];
          if (activityId != null) {
            debugPrint('🔄 Navigating to activity detail: $activityId');
            // Note: ActivityDetailScreen should be created or use existing ActivityListScreen
            Navigator.of(context).pushNamed(
              '/patient/home', // Navigate to home, activity tab will show
            );
          }
          break;

        case 'emergency_alert':
          // Navigate to emergency screen (family view)
          final alertId = payload['alert_id'];
          if (alertId != null) {
            debugPrint('🚨 Navigating to emergency alert: $alertId');
            Navigator.of(context).pushNamed(
              '/family/home', // Family home, will show emergency notification
            );
          }
          break;

        case 'geofence_entered':
        case 'geofence_exited':
          // Navigate to patient tracking map (family view)
          final patientId = payload['patient_id'];
          if (patientId != null) {
            debugPrint('📍 Navigating to patient map: $patientId');
            Navigator.of(context).pushNamed(
              '/family/home', // Family home, navigate to map tab
            );
          }
          break;

        case 'face_recognition':
          // Navigate to face recognition result (patient view)
          debugPrint('👤 Navigating to face recognition');
          Navigator.of(context).pushNamed(
            '/patient/home', // Patient home, navigate to kenali wajah tab
          );
          break;

        default:
          debugPrint('⚠️ Unknown notification type: $type');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Navigation error: $e');
      debugPrint('   Stack: $stackTrace');
    }
  }

  /// Called when notification is dismissed (swipe away)
  @pragma('vm:entry-point')
  static Future<void> _onDismissActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    debugPrint('📱 Notification Dismissed: ${receivedAction.id}');
  }

  // ==================== UTILITY METHODS ====================

  /// Reset notification badge count (Android)
  static Future<void> resetBadgeCount() async {
    await AwesomeNotifications().resetGlobalBadge();
  }

  /// Get notification badge count
  static Future<int> getBadgeCount() async {
    return await AwesomeNotifications().getGlobalBadgeCounter();
  }
}
