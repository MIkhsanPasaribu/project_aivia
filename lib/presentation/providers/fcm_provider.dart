import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../data/services/fcm_service.dart';
import '../../data/repositories/fcm_repository.dart';

/// **FCM Providers - Riverpod State Management untuk FCM**
///
/// Provides:
/// - FCM Service instance
/// - FCM Repository instance
/// - Current FCM token state
/// - Token refresh notifications
/// - Permission status
///
/// **Pattern**: Riverpod 2.x with AsyncNotifier

// ============================================================================
// SERVICE & REPOSITORY PROVIDERS
// ============================================================================

/// FCM Service provider (singleton)
final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService();
});

/// FCM Repository provider
final fcmRepositoryProvider = Provider<FCMRepository>((ref) {
  return FCMRepository();
});

// ============================================================================
// TOKEN STATE PROVIDER
// ============================================================================

/// Current FCM token state
///
/// Returns:
/// - AsyncData(String): Token berhasil didapat
/// - AsyncLoading: Loading state
/// - AsyncError: Error getting token
final fcmTokenProvider = FutureProvider<String?>((ref) async {
  debugPrint('🔔 FCMTokenProvider: Getting current token...');

  final fcmService = ref.read(fcmServiceProvider);

  // Initialize service if not yet
  if (fcmService.currentToken == null) {
    await fcmService.initialize();
  }

  return fcmService.currentToken;
});

// ============================================================================
// TOKEN REFRESH NOTIFIER
// ============================================================================

/// Token refresh notifier - listen to token changes
class FcmTokenRefreshNotifier extends StateNotifier<String?> {
  FcmTokenRefreshNotifier(this._fcmService) : super(null) {
    _init();
  }

  final FCMService _fcmService;

  void _init() {
    // Listen to token refresh stream
    _fcmService.onTokenRefresh.listen((newToken) {
      debugPrint('🔄 FcmTokenRefreshNotifier: Token refreshed');
      state = newToken;
    });
  }
}

/// Provider for token refresh notifications
final fcmTokenRefreshProvider =
    StateNotifierProvider<FcmTokenRefreshNotifier, String?>((ref) {
      final fcmService = ref.watch(fcmServiceProvider);
      return FcmTokenRefreshNotifier(fcmService);
    });

// ============================================================================
// PERMISSION STATUS PROVIDER
// ============================================================================

/// Current notification permission status
final fcmPermissionStatusProvider = FutureProvider<AuthorizationStatus>((
  ref,
) async {
  debugPrint('🔔 FCMPermissionProvider: Getting permission status...');

  final fcmService = ref.read(fcmServiceProvider);
  return await fcmService.getPermissionStatus();
});

// ============================================================================
// MESSAGE STREAM PROVIDER
// ============================================================================

/// Stream of foreground messages
final fcmMessageStreamProvider = StreamProvider<RemoteMessage>((ref) {
  debugPrint('📩 FCMMessageStreamProvider: Creating message stream...');

  final fcmService = ref.watch(fcmServiceProvider);
  return fcmService.onMessage;
});

// ============================================================================
// ACTIONS PROVIDER
// ============================================================================

/// Actions provider for FCM operations
class FcmActions {
  FcmActions(this._ref);

  final Ref _ref;

  FCMService get _service => _ref.read(fcmServiceProvider);
  FCMRepository get _repository => _ref.read(fcmRepositoryProvider);

  /// Request notification permission
  Future<bool> requestPermission() async {
    debugPrint('🔔 FcmActions: Requesting permission...');
    return await _service.requestPermission();
  }

  /// Refresh FCM token manually
  Future<String?> refreshToken() async {
    debugPrint('🔄 FcmActions: Manually refreshing token...');

    final newToken = await _service.refreshToken();

    // Invalidate token provider to refetch
    _ref.invalidate(fcmTokenProvider);

    return newToken;
  }

  /// Deactivate current device token (logout)
  Future<void> deactivateCurrentToken() async {
    debugPrint('🗑️ FcmActions: Deactivating current token...');

    final token = _service.currentToken;
    if (token != null) {
      await _repository.deactivateToken(token);
    }
  }

  /// Get emergency contact tokens for a patient
  Future<List<String>> getEmergencyContactTokens(String patientId) async {
    debugPrint('🔍 FcmActions: Getting emergency contact tokens...');
    return await _repository.getEmergencyContactTokens(patientId);
  }

  /// Get family member tokens for a patient
  Future<List<String>> getFamilyMemberTokens(String patientId) async {
    debugPrint('🔍 FcmActions: Getting family member tokens...');
    return await _repository.getFamilyMemberTokens(patientId);
  }
}

/// Provider untuk FCM actions
final fcmActionsProvider = Provider<FcmActions>((ref) {
  return FcmActions(ref);
});
