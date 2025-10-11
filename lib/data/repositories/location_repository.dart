import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_aivia/core/errors/failures.dart';
import 'package:project_aivia/core/utils/result.dart';
import 'package:project_aivia/data/models/location.dart';

/// Repository untuk manajemen lokasi tracking pasien
/// Menggunakan PostGIS untuk geospatial queries
class LocationRepository {
  final SupabaseClient _supabase;

  LocationRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  /// Get lokasi terbaru pasien (last known location)
  ///
  /// Returns lokasi terakhir yang tercatat dalam database
  Future<Result<Location?>> getLastLocation(String patientId) async {
    try {
      final data = await _supabase
          .from('locations')
          .select()
          .eq('patient_id', patientId)
          .order('timestamp', ascending: false)
          .limit(1)
          .maybeSingle();

      if (data == null) {
        return const Success(null);
      }

      final location = Location.fromJson(data);
      return Success(location);
    } on PostgrestException catch (e) {
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  /// Get history lokasi pasien dengan time range
  ///
  /// [startTime] dan [endTime] untuk filter range waktu
  /// [limit] untuk membatasi jumlah record (default 100)
  Future<Result<List<Location>>> getLocationHistory(
    String patientId, {
    DateTime? startTime,
    DateTime? endTime,
    int limit = 100,
  }) async {
    try {
      var query = _supabase
          .from('locations')
          .select()
          .eq('patient_id', patientId);

      // Filter by time range
      if (startTime != null) {
        query = query.gte('timestamp', startTime.toIso8601String());
      }
      if (endTime != null) {
        query = query.lte('timestamp', endTime.toIso8601String());
      }

      final data = await query
          .order('timestamp', ascending: false)
          .limit(limit);

      final locations = data.map((json) => Location.fromJson(json)).toList();
      return Success(locations);
    } on PostgrestException catch (e) {
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  /// Get lokasi stream untuk realtime updates
  ///
  /// Stream akan emit data baru setiap kali ada insert lokasi baru
  /// Hanya emit lokasi terbaru (1 record)
  Stream<Location?> getLastLocationStream(String patientId) {
    return _supabase
        .from('locations')
        .stream(primaryKey: ['id'])
        .eq('patient_id', patientId)
        .order('timestamp', ascending: false)
        .limit(1)
        .map((data) {
          if (data.isEmpty) return null;
          return Location.fromJson(data.first);
        });
  }

  /// Insert lokasi baru
  ///
  /// [patientId] ID pasien
  /// [latitude] Koordinat latitude
  /// [longitude] Koordinat longitude
  /// [accuracy] Akurasi dalam meter (opsional)
  Future<Result<Location>> insertLocation({
    required String patientId,
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    try {
      // Format PostGIS POINT
      final locationPoint = 'POINT($longitude $latitude)';

      final data = await _supabase
          .from('locations')
          .insert({
            'patient_id': patientId,
            'coordinates': locationPoint,
            'accuracy': accuracy,
            'timestamp': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final location = Location.fromJson(data);
      return Success(location);
    } on PostgrestException catch (e) {
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  /// Bulk insert multiple locations
  ///
  /// Untuk insert batch locations (misalnya sync offline data)
  Future<Result<List<Location>>> insertLocations(
    List<Map<String, dynamic>> locationData,
  ) async {
    try {
      final data = await _supabase
          .from('locations')
          .insert(locationData)
          .select();

      final locations = data.map((json) => Location.fromJson(json)).toList();
      return Success(locations);
    } on PostgrestException catch (e) {
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  /// Delete lokasi lama untuk cleanup
  ///
  /// Hapus lokasi yang lebih tua dari [olderThan] days
  /// Default 30 hari
  Future<Result<void>> deleteOldLocations({
    String? patientId,
    int olderThanDays = 30,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));

      var query = _supabase
          .from('locations')
          .delete()
          .lt('timestamp', cutoffDate.toIso8601String());

      // Filter by patient jika disediakan
      if (patientId != null) {
        query = query.eq('patient_id', patientId);
      }

      await query;

      return const Success(null);
    } on PostgrestException catch (e) {
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(UnknownFailure(e.toString()));
    }
  }

  /// Calculate distance between two coordinates (Haversine formula)
  ///
  /// Returns distance in meters
  /// Useful untuk client-side geofencing atau proximity checks
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371000.0; // meters

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }
}
