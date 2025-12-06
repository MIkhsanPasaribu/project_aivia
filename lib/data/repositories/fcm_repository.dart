import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// **FCMRepository - FCM Token Management Repository**
///
/// Handles all database operations untuk FCM tokens:
/// - ✅ Save/update FCM tokens
/// - ✅ Get tokens by user ID
/// - ✅ Get tokens for emergency contacts
/// - ✅ Delete old/inactive tokens
/// - ✅ Query token by device
///
/// **Database Table**: `fcm_tokens`
/// **FREE TIER**: Supabase PostgreSQL (500MB limit)
class FCMRepository {
  final SupabaseClient _supabase;

  FCMRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  /// Save or update FCM token
  ///
  /// Menggunakan UPSERT untuk handle token yang sudah ada
  /// Conflict resolution: (user_id, token) unique constraint
  Future<void> saveToken({
    required String userId,
    required String token,
    required String deviceType,
    Map<String, dynamic>? deviceInfo,
  }) async {
    try {
      debugPrint('💾 FCMRepository: Saving token for user $userId...');

      await _supabase.from('fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'device_type': deviceType,
        'device_info': deviceInfo,
        'is_active': true,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,token');

      debugPrint('✅ FCMRepository: Token saved successfully');
    } catch (e) {
      debugPrint('❌ FCMRepository: Save token error: $e');
      rethrow;
    }
  }

  /// Get all active tokens for a user
  ///
  /// Returns list of FCM tokens (untuk multi-device support)
  Future<List<Map<String, dynamic>>> getTokensByUserId(String userId) async {
    try {
      debugPrint('🔍 FCMRepository: Getting tokens for user $userId...');

      final response = await _supabase
          .from('fcm_tokens')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('updated_at', ascending: false);

      debugPrint('✅ FCMRepository: Found ${response.length} token(s)');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ FCMRepository: Get tokens error: $e');
      return [];
    }
  }

  /// Get FCM tokens for emergency contacts of a patient
  ///
  /// Used untuk send emergency notifications ke family members
  /// Joins: fcm_tokens ← emergency_contacts → profiles
  Future<List<String>> getEmergencyContactTokens(String patientId) async {
    try {
      debugPrint(
        '🔍 FCMRepository: Getting emergency contact tokens for patient $patientId...',
      );

      // Query emergency contacts
      final contactsResponse = await _supabase
          .from('emergency_contacts')
          .select('contact_id')
          .eq('patient_id', patientId)
          .order('priority', ascending: true); // Higher priority first

      if (contactsResponse.isEmpty) {
        debugPrint('⚠️ FCMRepository: No emergency contacts found');
        return [];
      }

      // Extract contact IDs
      final contactIds = contactsResponse
          .map((c) => c['contact_id'] as String)
          .toList();

      // Query FCM tokens for those contacts
      final tokensResponse = await _supabase
          .from('fcm_tokens')
          .select('token')
          .inFilter('user_id', contactIds)
          .eq('is_active', true);

      final tokens = tokensResponse.map((t) => t['token'] as String).toList();

      debugPrint(
        '✅ FCMRepository: Found ${tokens.length} emergency contact token(s)',
      );
      return tokens;
    } catch (e) {
      debugPrint('❌ FCMRepository: Get emergency contact tokens error: $e');
      return [];
    }
  }

  /// Get FCM tokens for all family members linked to a patient
  ///
  /// Used untuk general notifications (non-emergency)
  /// Joins: fcm_tokens ← patient_family_links → profiles
  Future<List<String>> getFamilyMemberTokens(String patientId) async {
    try {
      debugPrint(
        '🔍 FCMRepository: Getting family member tokens for patient $patientId...',
      );

      // Query family links
      final linksResponse = await _supabase
          .from('patient_family_links')
          .select('family_member_id')
          .eq('patient_id', patientId);

      if (linksResponse.isEmpty) {
        debugPrint('⚠️ FCMRepository: No family members found');
        return [];
      }

      // Extract family member IDs
      final familyIds = linksResponse
          .map((l) => l['family_member_id'] as String)
          .toList();

      // Query FCM tokens
      final tokensResponse = await _supabase
          .from('fcm_tokens')
          .select('token')
          .inFilter('user_id', familyIds)
          .eq('is_active', true);

      final tokens = tokensResponse.map((t) => t['token'] as String).toList();

      debugPrint(
        '✅ FCMRepository: Found ${tokens.length} family member token(s)',
      );
      return tokens;
    } catch (e) {
      debugPrint('❌ FCMRepository: Get family member tokens error: $e');
      return [];
    }
  }

  /// Deactivate a token (soft delete)
  ///
  /// Used when user logs out or uninstalls app
  Future<void> deactivateToken(String token) async {
    try {
      debugPrint('🗑️ FCMRepository: Deactivating token...');

      await _supabase
          .from('fcm_tokens')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('token', token);

      debugPrint('✅ FCMRepository: Token deactivated');
    } catch (e) {
      debugPrint('❌ FCMRepository: Deactivate token error: $e');
      rethrow;
    }
  }

  /// Deactivate all tokens for a user
  ///
  /// Used saat user logout dari semua devices
  Future<void> deactivateAllUserTokens(String userId) async {
    try {
      debugPrint(
        '🗑️ FCMRepository: Deactivating all tokens for user $userId...',
      );

      await _supabase
          .from('fcm_tokens')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);

      debugPrint('✅ FCMRepository: All user tokens deactivated');
    } catch (e) {
      debugPrint('❌ FCMRepository: Deactivate all tokens error: $e');
      rethrow;
    }
  }

  /// Delete old inactive tokens (cleanup)
  ///
  /// Recommended: Run daily via cron job
  /// Deletes tokens inactive for > 90 days
  Future<int> deleteOldTokens({int daysInactive = 90}) async {
    try {
      debugPrint(
        '🧹 FCMRepository: Deleting tokens inactive for >$daysInactive days...',
      );

      final cutoffDate = DateTime.now().subtract(Duration(days: daysInactive));

      final response = await _supabase
          .from('fcm_tokens')
          .delete()
          .eq('is_active', false)
          .lt('updated_at', cutoffDate.toIso8601String());

      final deletedCount = response.length;
      debugPrint('✅ FCMRepository: Deleted $deletedCount old token(s)');

      return deletedCount;
    } catch (e) {
      debugPrint('❌ FCMRepository: Delete old tokens error: $e');
      return 0;
    }
  }

  /// Check if a token exists and is active
  Future<bool> isTokenActive(String token) async {
    try {
      final response = await _supabase
          .from('fcm_tokens')
          .select('id')
          .eq('token', token)
          .eq('is_active', true)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('❌ FCMRepository: Check token active error: $e');
      return false;
    }
  }

  /// Queue notification untuk dikirim via Edge Function
  ///
  /// Notification akan diambil oleh cron job dan dikirim via FCM
  ///
  /// Parameters:
  /// - [recipientUserId]: User ID penerima notifikasi
  /// - [notificationType]: 'emergency', 'geofence', 'activity', 'reminder', 'system'
  /// - [title]: Judul notifikasi
  /// - [body]: Isi notifikasi
  /// - [data]: Data tambahan untuk navigation & actions (JSON)
  /// - [priority]: Priority level 1-10 (10 = tertinggi, default: 5)
  ///
  /// Returns:
  /// - Notification ID jika berhasil
  /// - Throws exception jika gagal
  Future<String> queueNotification({
    required String recipientUserId,
    required String notificationType,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    int priority = 5,
  }) async {
    try {
      debugPrint(
        '📮 FCMRepository: Queueing notification for user $recipientUserId...',
      );
      debugPrint('Type: $notificationType, Priority: $priority');

      final response = await _supabase
          .from('pending_notifications')
          .insert({
            'recipient_user_id': recipientUserId,
            'notification_type': notificationType,
            'title': title,
            'body': body,
            'data': data ?? {},
            'status': 'pending',
            'scheduled_at': DateTime.now().toIso8601String(),
            'priority': priority,
          })
          .select('id')
          .single();

      final notificationId = response['id'] as String;

      debugPrint('✅ FCMRepository: Notification queued: $notificationId');

      return notificationId;
    } catch (e) {
      debugPrint('❌ FCMRepository: Queue notification error: $e');
      rethrow;
    }
  }

  /// Get total active tokens count (for monitoring)
  Future<int> getActiveTokensCount() async {
    try {
      final response = await _supabase
          .from('fcm_tokens')
          .select('id')
          .eq('is_active', true)
          .count();

      return response.count;
    } catch (e) {
      debugPrint('❌ FCMRepository: Get active tokens count error: $e');
      return 0;
    }
  }
}
