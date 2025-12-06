import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_aivia/core/errors/failures.dart';
import 'package:project_aivia/core/utils/result.dart';
import 'package:project_aivia/data/models/geofence.dart';
import 'package:project_aivia/data/models/geofence_event.dart';

/// Repository untuk manajemen geofences (zona geografis)
class GeofenceRepository {
  final SupabaseClient _supabase;

  GeofenceRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  /// Buat geofence baru
  Future<Result<Geofence>> createGeofence({
    required String patientId,
    required String name,
    String? description,
    required FenceType fenceType,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    bool alertOnEnter = true,
    bool alertOnExit = true,
    int priority = 5,
    String? address,
  }) async {
    try {
      // Validasi
      if (radiusMeters < 50 || radiusMeters > 10000) {
        return const ResultFailure(
          ValidationFailure('Radius harus antara 50-10000 meter'),
        );
      }
      if (priority < 1 || priority > 10) {
        return const ResultFailure(
          ValidationFailure('Prioritas harus antara 1-10'),
        );
      }

      final data = await _supabase
          .from('geofences')
          .insert({
            'patient_id': patientId,
            'name': name,
            'description': description,
            'fence_type': fenceType.toDbString(),
            'center_coordinates': 'POINT($longitude $latitude)',
            'radius_meters': radiusMeters,
            'alert_on_enter': alertOnEnter,
            'alert_on_exit': alertOnExit,
            'priority': priority,
            'address': address,
            'is_active': true,
          })
          .select()
          .single();

      return Success(Geofence.fromJson(data));
    } on PostgrestException catch (e) {
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  /// Get geofences untuk pasien
  Future<Result<List<Geofence>>> getGeofencesForPatient(
    String patientId, {
    bool? isActive,
    FenceType? fenceType,
  }) async {
    try {
      var query = _supabase
          .from('geofences')
          .select()
          .eq('patient_id', patientId);

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }
      if (fenceType != null) {
        query = query.eq('fence_type', fenceType.toDbString());
      }

      final data = await query.order('created_at', ascending: false);
      final geofences = data.map((json) => Geofence.fromJson(json)).toList();
      return Success(geofences);
    } on PostgrestException catch (e) {
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  /// Watch geofences stream (realtime)
  Stream<List<Geofence>> watchGeofencesForPatient(String patientId) {
    return _supabase
        .from('geofences')
        .stream(primaryKey: ['id'])
        .eq('patient_id', patientId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => Geofence.fromJson(json)).toList());
  }

  /// Get single geofence by ID
  Future<Result<Geofence>> getGeofenceById(String geofenceId) async {
    try {
      final data = await _supabase
          .from('geofences')
          .select()
          .eq('id', geofenceId)
          .single();

      return Success(Geofence.fromJson(data));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return const ResultFailure(
          DatabaseFailure('Geofence tidak ditemukan', code: 'not_found'),
        );
      }
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  /// Update geofence
  Future<Result<Geofence>> updateGeofence(
    String geofenceId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final data = await _supabase
          .from('geofences')
          .update(updates)
          .eq('id', geofenceId)
          .select()
          .single();

      return Success(Geofence.fromJson(data));
    } on PostgrestException catch (e) {
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  /// Toggle status active/inactive
  Future<Result<Geofence>> toggleGeofenceStatus(String geofenceId) async {
    try {
      // Get current status first
      final current = await getGeofenceById(geofenceId);
      if (current is ResultFailure) {
        return current;
      }

      final currentGeofence = (current as Success<Geofence>).data;
      final newStatus = !currentGeofence.isActive;

      return await updateGeofence(geofenceId, {'is_active': newStatus});
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  /// Delete geofence
  Future<Result<void>> deleteGeofence(String geofenceId) async {
    try {
      await _supabase.from('geofences').delete().eq('id', geofenceId);
      return const Success(null);
    } on PostgrestException catch (e) {
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  // ========================================
  // GEOFENCE EVENTS
  // ========================================

  /// Get geofence events (enter/exit history)
  Future<Result<List<GeofenceEvent>>> getGeofenceEvents({
    String? patientId,
    String? geofenceId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      var query = _supabase.from('geofence_events').select();

      if (patientId != null) {
        query = query.eq('patient_id', patientId);
      }
      if (geofenceId != null) {
        query = query.eq('geofence_id', geofenceId);
      }
      if (startDate != null) {
        query = query.gte('detected_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('detected_at', endDate.toIso8601String());
      }

      final data = await query
          .order('detected_at', ascending: false)
          .limit(limit);

      final events = data.map((json) => GeofenceEvent.fromJson(json)).toList();
      return Success(events);
    } on PostgrestException catch (e) {
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  /// Watch geofence events stream (realtime)
  Stream<List<GeofenceEvent>> watchGeofenceEvents(String patientId) {
    return _supabase
        .from('geofence_events')
        .stream(primaryKey: ['id'])
        .eq('patient_id', patientId)
        .order('detected_at', ascending: false)
        .map(
          (data) => data.map((json) => GeofenceEvent.fromJson(json)).toList(),
        );
  }

  // ========================================
  // UTILITY
  // ========================================

  /// Check if location is inside geofence (menggunakan PostGIS function)
  Future<Result<bool>> isLocationInsideGeofence(
    String geofenceId,
    double latitude,
    double longitude,
  ) async {
    try {
      final result = await _supabase.rpc(
        'is_location_inside_geofence',
        params: {
          'p_geofence_id': geofenceId,
          'p_latitude': latitude,
          'p_longitude': longitude,
        },
      );

      return Success(result as bool);
    } on PostgrestException catch (e) {
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  /// Get count of active geofences untuk pasien
  Future<Result<int>> getActiveGeofencesCount(String patientId) async {
    try {
      final result = await _supabase
          .from('geofences')
          .select('id')
          .eq('patient_id', patientId)
          .eq('is_active', true)
          .count(CountOption.exact);

      return Success(result.count);
    } on PostgrestException catch (e) {
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }
}
