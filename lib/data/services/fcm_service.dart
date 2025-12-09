import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// **FCMService - Firebase Cloud Messaging Service**
///
/// Enterprise-grade FCM implementation dengan fitur:
/// - ✅ Token management & auto-refresh
/// - ✅ Foreground & background message handling
/// - ✅ Local notification display untuk foreground messages
/// - ✅ Notification tap handling dengan navigation
/// - ✅ Token persistence ke Supabase
/// - ✅ Device info tracking
/// - ✅ Error handling & logging
///
/// **FREE TIER**: Firebase FCM unlimited messages
/// **Cost**: $0/month
class FCMService {
  // Singleton pattern
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  // Firebase Messaging instance
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Local notifications plugin
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Supabase client
  final SupabaseClient _supabase = Supabase.instance.client;

  // Device info
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Current FCM token
  String? _currentToken;

  // Stream controllers
  final StreamController<RemoteMessage> _messageStreamController =
      StreamController<RemoteMessage>.broadcast();

  final StreamController<String> _tokenRefreshController =
      StreamController<String>.broadcast();

  /// 🆕 Global navigator key untuk navigation dari background
  static GlobalKey<NavigatorState>? navigatorKey;

  /// 🆕 Set navigator key (call dari main.dart)
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
    debugPrint('✅ FCMService: Navigator key set');
  }

  /// Stream untuk listening foreground messages
  Stream<RemoteMessage> get onMessage => _messageStreamController.stream;

  /// Stream untuk listening token refresh
  Stream<String> get onTokenRefresh => _tokenRefreshController.stream;

  /// Current FCM token (nullable)
  String? get currentToken => _currentToken;

  /// Initialize FCM Service
  ///
  /// **Steps**:
  /// 1. Request notification permissions
  /// 2. Initialize local notifications
  /// 3. Get FCM token
  /// 4. Save token to Supabase
  /// 5. Setup message handlers
  /// 6. Setup token refresh listener
  Future<void> initialize() async {
    try {
      debugPrint('🔔 FCMService: Initializing...');

      // Step 1: Request permissions
      final permissionGranted = await requestPermission();
      if (!permissionGranted) {
        debugPrint('⚠️ FCMService: Notification permission denied');
        return;
      }

      // Step 2: Initialize local notifications
      await _initializeLocalNotifications();

      // Step 3: Get FCM token
      _currentToken = await _firebaseMessaging.getToken();
      if (_currentToken != null) {
        debugPrint(
          '✅ FCMService: Token obtained: ${_currentToken!.substring(0, 20)}...',
        );

        // Step 4: Save to Supabase
        await _saveTokenToDatabase(_currentToken!);
      } else {
        debugPrint('❌ FCMService: Failed to get FCM token');
      }

      // Step 5: Setup message handlers
      _setupMessageHandlers();

      // Step 6: Setup token refresh listener
      _setupTokenRefreshListener();

      // 🆕 Step 7: Setup notification tap handlers
      _setupNotificationTapHandlers();

      debugPrint('✅ FCMService: Initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ FCMService: Initialization error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Request notification permissions (Android 13+, iOS always)
  ///
  /// Returns `true` if permission granted
  Future<bool> requestPermission() async {
    try {
      debugPrint('🔔 FCMService: Requesting notification permission...');

      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true, // For emergency alerts
        provisional: false,
        sound: true,
      );

      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      if (granted) {
        debugPrint('✅ FCMService: Notification permission granted');
      } else {
        debugPrint(
          '⚠️ FCMService: Notification permission denied (${settings.authorizationStatus})',
        );
      }

      return granted;
    } catch (e) {
      debugPrint('❌ FCMService: Permission request error: $e');
      return false;
    }
  }

  /// Initialize local notifications untuk foreground messages
  Future<void> _initializeLocalNotifications() async {
    try {
      debugPrint('🔔 FCMService: Initializing local notifications...');

      // Android initialization
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS initialization
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize dengan onDidReceiveNotificationResponse untuk tap handling
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels (Android)
      if (Platform.isAndroid) {
        await _createNotificationChannels();
      }

      debugPrint('✅ FCMService: Local notifications initialized');
    } catch (e) {
      debugPrint('❌ FCMService: Local notifications init error: $e');
    }
  }

  /// Create notification channels untuk Android
  Future<void> _createNotificationChannels() async {
    try {
      // Channel untuk emergency alerts
      const emergencyChannel = AndroidNotificationChannel(
        'emergency_alerts', // id
        'Emergency Alerts', // name
        description: 'Notifikasi darurat dari pasien',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        sound: RawResourceAndroidNotificationSound('emergency'), // Custom sound
      );

      // Channel untuk regular notifications
      const regularChannel = AndroidNotificationChannel(
        'general_notifications', // id
        'General Notifications', // name
        description: 'Notifikasi umum aplikasi',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(emergencyChannel);

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(regularChannel);

      debugPrint('✅ FCMService: Notification channels created');
    } catch (e) {
      debugPrint('❌ FCMService: Create channels error: $e');
    }
  }

  /// Save FCM token to Supabase database
  Future<void> _saveTokenToDatabase(String token) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('⚠️ FCMService: No authenticated user, skipping token save');
        return;
      }

      debugPrint('💾 FCMService: Saving token to database...');

      // Get device info with platform
      final deviceInfoMap = await _getDeviceInfo();

      // Add platform info to device_info JSONB
      deviceInfoMap['platform'] = Platform.isAndroid ? 'android' : 'ios';

      // Upsert token ke fcm_tokens table (tanpa device_type column)
      await _supabase.from('fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'device_info': deviceInfoMap,
        'is_active': true,
        'last_used_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'token');

      debugPrint('✅ FCMService: Token saved to database');
    } catch (e) {
      debugPrint('❌ FCMService: Save token error: $e');
    }
  }

  /// Get device info untuk logging
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'brand': androidInfo.brand,
          'model': androidInfo.model,
          'sdk_version': androidInfo.version.sdkInt,
          'android_version': androidInfo.version.release,
          'device': androidInfo.device,
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'model': iosInfo.model,
          'system_name': iosInfo.systemName,
          'system_version': iosInfo.systemVersion,
          'name': iosInfo.name,
        };
      }
      return {'platform': 'unknown'};
    } catch (e) {
      debugPrint('❌ FCMService: Get device info error: $e');
      return {'error': e.toString()};
    }
  }

  /// Setup message handlers (foreground, background, terminated)
  void _setupMessageHandlers() {
    // 1. FOREGROUND messages - app is open
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 FCMService: Foreground message received');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');

      // Add to stream
      _messageStreamController.add(message);

      // Show local notification
      _showLocalNotification(message);
    });

    // 2. BACKGROUND/TERMINATED messages - user taps notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📲 FCMService: Notification tapped (background/terminated)');
      debugPrint('Data: ${message.data}');

      // Handle navigation
      _handleNotificationTap(message);
    });

    // 3. Check initial message - app opened from terminated state
    _checkInitialMessage();
  }

  /// Check if app was opened from a notification (terminated state)
  Future<void> _checkInitialMessage() async {
    try {
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🚀 FCMService: App opened from notification (terminated)');
        debugPrint('Data: ${initialMessage.data}');

        // Handle navigation
        _handleNotificationTap(initialMessage);
      }
    } catch (e) {
      debugPrint('❌ FCMService: Check initial message error: $e');
    }
  }

  /// Setup token refresh listener
  void _setupTokenRefreshListener() {
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FCMService: Token refreshed');
      debugPrint('New token: ${newToken.substring(0, 20)}...');

      _currentToken = newToken;

      // Save to database
      _saveTokenToDatabase(newToken);

      // Notify listeners
      _tokenRefreshController.add(newToken);
    });
  }

  /// Show local notification untuk foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) {
        debugPrint(
          '⚠️ FCMService: No notification payload, skipping local notification',
        );
        return;
      }

      // Determine channel based on message data
      final isEmergency = message.data['type'] == 'emergency';
      final channelId = isEmergency
          ? 'emergency_alerts'
          : 'general_notifications';

      // Android notification details
      final androidDetails = AndroidNotificationDetails(
        channelId,
        isEmergency ? 'Emergency Alerts' : 'General Notifications',
        channelDescription: isEmergency
            ? 'Notifikasi darurat dari pasien'
            : 'Notifikasi umum aplikasi',
        importance: isEmergency ? Importance.max : Importance.high,
        priority: isEmergency ? Priority.max : Priority.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        sound: isEmergency
            ? const RawResourceAndroidNotificationSound('emergency')
            : null,
      );

      // iOS notification details
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show notification
      await _localNotifications.show(
        message.hashCode, // Use message hash as notification ID
        notification.title,
        notification.body,
        notificationDetails,
        payload: message.data.toString(), // Pass data as payload
      );

      debugPrint('✅ FCMService: Local notification shown');
    } catch (e) {
      debugPrint('❌ FCMService: Show local notification error: $e');
    }
  }

  /// Handle notification tap (from local notifications)
  ///
  /// Routes to appropriate screen based on notification data:
  /// - activity: Activity detail or list
  /// - emergency: Emergency alert screen
  /// - geofence: Patient map screen
  /// - location: Patient tracking
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('👆 FCMService: Local notification tapped');

    if (response.payload == null || response.payload!.isEmpty) {
      debugPrint('⚠️ No payload data');
      return;
    }

    try {
      // Parse payload (format: {key1: value1, key2: value2})
      final payload = response.payload!;
      debugPrint('📦 Payload: $payload');

      // Get navigator context
      final context = navigatorKey?.currentContext;
      if (context == null) {
        debugPrint('⚠️ Navigator context not available');
        return;
      }

      // Extract notification type from payload string
      // Payload format from RemoteMessage.data.toString()
      if (payload.contains('type')) {
        // Simple string parsing for type
        if (payload.contains('emergency')) {
          _navigateToEmergency(context);
        } else if (payload.contains('geofence')) {
          _navigateToPatientMap(context);
        } else if (payload.contains('activity')) {
          _navigateToActivity(context);
        } else {
          debugPrint('⚠️ Unknown notification type in payload');
        }
      }
    } catch (e) {
      debugPrint('❌ FCMService: Navigation error: $e');
    }
  }

  /// Navigate to emergency alert screen
  void _navigateToEmergency(BuildContext context) {
    debugPrint('🚨 Navigating to emergency screen');
    Navigator.of(context).pushNamed('/family/home');
  }

  /// Navigate to patient tracking map
  void _navigateToPatientMap(BuildContext context) {
    debugPrint('📍 Navigating to patient map');
    Navigator.of(context).pushNamed('/family/home');
  }

  /// Navigate to activity screen
  void _navigateToActivity(BuildContext context) {
    debugPrint('📋 Navigating to activity screen');
    Navigator.of(context).pushNamed('/patient/home');
  }

  /// Manually refresh FCM token
  Future<String?> refreshToken() async {
    try {
      debugPrint('🔄 FCMService: Manually refreshing token...');

      // Delete current token
      await _firebaseMessaging.deleteToken();

      // Get new token
      _currentToken = await _firebaseMessaging.getToken();

      if (_currentToken != null) {
        debugPrint(
          '✅ FCMService: Token refreshed: ${_currentToken!.substring(0, 20)}...',
        );

        // Save to database
        await _saveTokenToDatabase(_currentToken!);

        // Notify listeners
        _tokenRefreshController.add(_currentToken!);
      }

      return _currentToken;
    } catch (e) {
      debugPrint('❌ FCMService: Refresh token error: $e');
      return null;
    }
  }

  /// Get current notification permission status
  Future<AuthorizationStatus> getPermissionStatus() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus;
    } catch (e) {
      debugPrint('❌ FCMService: Get permission status error: $e');
      return AuthorizationStatus.notDetermined;
    }
  }

  // ============================================================================
  // 🆕 NOTIFICATION TAP HANDLERS
  // ============================================================================

  /// Setup notification tap handlers
  ///
  /// Handles:
  /// - App opened from terminated state (getInitialMessage)
  /// - App opened from background (onMessageOpenedApp)
  void _setupNotificationTapHandlers() {
    debugPrint('🔔 FCMService: Setting up notification tap handlers...');

    // Handle notification tap ketika app opened from terminated state
    _firebaseMessaging.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('🔔 FCMService: App opened from terminated by notification');
        _handleNotificationTap(message);
      }
    });

    // Handle notification tap ketika app di background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('🔔 FCMService: App opened from background by notification');
      _handleNotificationTap(message);
    });

    debugPrint('✅ FCMService: Notification tap handlers setup complete');
  }

  /// Handle notification tap - navigate based on notification type
  ///
  /// Navigation routes:
  /// - `emergency_alert` → Patient map screen
  /// - `geofence_alert` → Geofence detail screen
  /// - `activity_reminder` → Activity list screen
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 FCMService: Notification tapped');
    debugPrint('Data: ${message.data}');

    // Check if navigator key is set
    if (navigatorKey == null || navigatorKey!.currentContext == null) {
      debugPrint('⚠️ FCMService: Navigator key not set, cannot navigate');
      return;
    }

    final data = message.data;
    final type = data['type'] as String?;

    if (type == null) {
      debugPrint('⚠️ FCMService: Notification type not found in data');
      return;
    }

    debugPrint('🔔 FCMService: Handling notification type: $type');

    // Navigate based on type
    switch (type) {
      case 'emergency_alert':
        final patientId = data['patient_id'] as String?;
        if (patientId != null) {
          debugPrint('🔔 FCMService: Navigating to patient map...');
          navigatorKey!.currentState?.pushNamed(
            '/family/patient-map',
            arguments: {'patient_id': patientId},
          );
        } else {
          debugPrint(
            '⚠️ FCMService: patient_id not found in emergency alert data',
          );
        }
        break;

      case 'geofence_alert':
        final geofenceId = data['geofence_id'] as String?;
        if (geofenceId != null) {
          debugPrint('🔔 FCMService: Navigating to geofence detail...');
          navigatorKey!.currentState?.pushNamed(
            '/family/geofence-detail',
            arguments: {'geofence_id': geofenceId},
          );
        } else {
          debugPrint(
            '⚠️ FCMService: geofence_id not found in geofence alert data',
          );
        }
        break;

      case 'activity_reminder':
        debugPrint('🔔 FCMService: Navigating to activity list...');
        navigatorKey!.currentState?.pushNamed('/patient/activities');
        break;

      default:
        debugPrint('⚠️ FCMService: Unknown notification type: $type');
    }
  }

  /// Dispose resources
  void dispose() {
    _messageStreamController.close();
    _tokenRefreshController.close();
  }
}

/// Background message handler
///
/// MUST be top-level function or static method
/// Annotated with @pragma('vm:entry-point') for tree-shaking prevention
/// Background message handler (MUST be top-level function)
///
/// Called when app is in background or terminated and receives FCM message.
/// Limited operations allowed (no UI, no long-running tasks).
///
/// Allowed:
/// - Show local notification
/// - Save to local database (SQLite)
/// - Update shared preferences
/// - Log events
///
/// **Performance**: Must complete in < 30 seconds or will be killed by OS
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase (already called in main.dart, but safe to call again)
  // Note: Firebase.initializeApp() is idempotent

  final timestamp = DateTime.now().toIso8601String();

  debugPrint('🔔 FCMService: Background message received at $timestamp');
  debugPrint('   Message ID: ${message.messageId}');
  debugPrint('   Title: ${message.notification?.title}');
  debugPrint('   Body: ${message.notification?.body}');
  debugPrint('   Data: ${message.data}');

  // Extract notification type
  final notificationType = message.data['type'] as String?;

  // Process based on type
  try {
    switch (notificationType) {
      case 'emergency_alert':
        debugPrint('🚨 Background: Emergency alert received');
        // High priority - ensure notification is shown
        // System will auto-show notification if notification field exists
        break;

      case 'geofence_entered':
      case 'geofence_exited':
        debugPrint('📍 Background: Geofence event received');
        // Could save to local DB for offline sync
        break;

      case 'activity_reminder':
        debugPrint('📋 Background: Activity reminder received');
        // Local notification already handled by awesome_notifications
        break;

      case 'location_request':
        debugPrint('📍 Background: Location update request received');
        // Could trigger location service to send update
        break;

      default:
        debugPrint('ℹ️ Background: Generic message received');
    }

    debugPrint('✅ Background message processed successfully');
  } catch (e, stackTrace) {
    debugPrint('❌ Background message processing error: $e');
    debugPrint('   Stack: $stackTrace');
  }
}
