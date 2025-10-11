import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_aivia/core/errors/failures.dart';
import 'package:project_aivia/core/utils/result.dart';
import 'package:project_aivia/data/models/emergency_contact.dart';
import 'package:project_aivia/data/models/emergency_alert.dart';

/// Repository untuk manajemen emergency contacts dan alerts
class EmergencyRepository {
  final SupabaseClient _supabase;

  EmergencyRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  // ========================================
  // EMERGENCY CONTACTS
  // ========================================

  /// Get semua emergency contacts untuk pasien
  ///
  /// Diurutkan berdasarkan priority (1 = highest)
  Future<Result<List<EmergencyContact>>> getContacts(String patientId) async {
    try {
      final data = await _supabase
          .from('emergency_contacts')
          .select()
          .eq('patient_id', patientId)
          .order('priority', ascending: true);

      final contacts = data
          .map((json) => EmergencyContact.fromJson(json))
          .toList();
      return Success(contacts);
    } on PostgrestException catch (e) {
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  /// Get emergency contacts stream untuk realtime updates
  Stream<List<EmergencyContact>> getContactsStream(String patientId) {
    return _supabase
        .from('emergency_contacts')
        .stream(primaryKey: ['id'])
        .eq('patient_id', patientId)
        .order('priority', ascending: true)
        .map(
          (data) =>
              data.map((json) => EmergencyContact.fromJson(json)).toList(),
        );
  }

  /// Tambah emergency contact baru
  Future<Result<EmergencyContact>> addContact({
    required String patientId,
    required String contactId,
    required int priority,
    bool notificationEnabled = true,
  }) async {
    try {
      final data = await _supabase
          .from('emergency_contacts')
          .insert({
            'patient_id': patientId,
            'contact_id': contactId,
            'priority': priority,
            'notification_enabled': notificationEnabled,
          })
          .select()
          .single();

      final contact = EmergencyContact.fromJson(data);
      return Success(contact);
    } on PostgrestException catch (e) {
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  /// Update emergency contact
  Future<Result<EmergencyContact>> updateContact(
    String contactId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final data = await _supabase
          .from('emergency_contacts')
          .update(updates)
          .eq('id', contactId)
          .select()
          .single();

      final contact = EmergencyContact.fromJson(data);
      return Success(contact);
    } on PostgrestException catch (e) {
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  /// Hapus emergency contact
  Future<Result<void>> deleteContact(String contactId) async {
    try {
      await _supabase.from('emergency_contacts').delete().eq('id', contactId);

      return const Success(null);
    } on PostgrestException catch (e) {
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  // ========================================
  // EMERGENCY ALERTS
  // ========================================

  /// Get semua emergency alerts untuk pasien
  ///
  /// [status] filter by status (active, acknowledged, resolved, false_alarm)
  /// [limit] maksimal record yang diambil
  Future<Result<List<EmergencyAlert>>> getAlerts(
    String patientId, {
    String? status,
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from('emergency_alerts')
          .select()
          .eq('patient_id', patientId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final data = await query
          .order('created_at', ascending: false)
          .limit(limit);

      final alerts = data.map((json) => EmergencyAlert.fromJson(json)).toList();
      return Success(alerts);
    } on PostgrestException catch (e) {
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  /// Get emergency alerts stream untuk realtime updates
  ///
  /// Hanya untuk active alerts
  Stream<List<EmergencyAlert>> getActiveAlertsStream(String patientId) {
    return _supabase
        .from('emergency_alerts')
        .stream(primaryKey: ['id'])
        .eq('patient_id', patientId)
        .order('created_at', ascending: false)
        .map((data) {
          // Filter active alerts di client side
          return data
              .where((json) => json['status'] == 'active')
              .map((json) => EmergencyAlert.fromJson(json))
              .toList();
        });
  }

  /// Trigger emergency alert
  ///
  /// Dipanggil ketika pasien menekan tombol panic atau sistem mendeteksi emergency
  Future<Result<EmergencyAlert>> triggerEmergency({
    required String patientId,
    required String
    alertType, // panic_button, fall_detection, geofence_exit, no_activity
    double? latitude,
    double? longitude,
    String? message,
    String severity = 'high',
  }) async {
    try {
      // Format PostGIS POINT jika ada koordinat
      String? locationPoint;
      if (latitude != null && longitude != null) {
        locationPoint = 'POINT($longitude $latitude)';
      }

      final data = await _supabase
          .from('emergency_alerts')
          .insert({
            'patient_id': patientId,
            'alert_type': alertType,
            'location': locationPoint,
            'message': message ?? 'Peringatan Darurat!',
            'severity': severity,
            'status': 'active',
          })
          .select()
          .single();

      final alert = EmergencyAlert.fromJson(data);
      return Success(alert);
    } on PostgrestException catch (e) {
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  /// Acknowledge emergency alert
  ///
  /// Dipanggil ketika family member melihat alert
  Future<Result<EmergencyAlert>> acknowledgeAlert(String alertId) async {
    try {
      final data = await _supabase
          .from('emergency_alerts')
          .update({
            'status': 'acknowledged',
            'acknowledged_at': DateTime.now().toIso8601String(),
          })
          .eq('id', alertId)
          .select()
          .single();

      final alert = EmergencyAlert.fromJson(data);
      return Success(alert);
    } on PostgrestException catch (e) {
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  /// Resolve emergency alert
  ///
  /// Dipanggil ketika family member menyelesaikan alert
  Future<Result<EmergencyAlert>> resolveAlert({
    required String alertId,
    required String resolvedBy,
    String? notes,
    bool isFalseAlarm = false,
  }) async {
    try {
      final data = await _supabase
          .from('emergency_alerts')
          .update({
            'status': isFalseAlarm ? 'false_alarm' : 'resolved',
            'resolved_by': resolvedBy,
            'resolved_at': DateTime.now().toIso8601String(),
            'notes': notes,
          })
          .eq('id', alertId)
          .select()
          .single();

      final alert = EmergencyAlert.fromJson(data);
      return Success(alert);
    } on PostgrestException catch (e) {
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  /// Get jumlah active alerts untuk pasien
  ///
  /// Useful untuk badge notification count
  Future<Result<int>> getActiveAlertCount(String patientId) async {
    try {
      final data = await _supabase
          .from('emergency_alerts')
          .select()
          .eq('patient_id', patientId)
          .eq('status', 'active');

      return Success(data.length);
    } on PostgrestException catch (e) {
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  /// Get latest alert untuk pasien
  ///
  /// Returns alert terbaru (bisa active atau resolved)
  Future<Result<EmergencyAlert?>> getLatestAlert(String patientId) async {
    try {
      final data = await _supabase
          .from('emergency_alerts')
          .select()
          .eq('patient_id', patientId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data == null) {
        return const Success(null);
      }

      final alert = EmergencyAlert.fromJson(data);
      return Success(alert);
    } on PostgrestException catch (e) {
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }
}
