import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_aivia/data/models/geofence.dart';
import 'package:project_aivia/data/models/geofence_event.dart';
import 'package:project_aivia/data/repositories/geofence_repository.dart';
import 'package:project_aivia/core/utils/result.dart';

/// Provider untuk GeofenceRepository instance
final geofenceRepositoryProvider = Provider<GeofenceRepository>((ref) {
  return GeofenceRepository();
});

/// Provider untuk geofences stream (real-time updates)
///
/// Mengembalikan stream geofences untuk patient tertentu
/// Otomatis update ketika ada perubahan di database
///
/// Parameter:
/// - [patientId]: ID pasien yang geofences-nya akan dimonitor
final geofencesStreamProvider = StreamProvider.family<List<Geofence>, String>((
  ref,
  patientId,
) {
  final repository = ref.watch(geofenceRepositoryProvider);
  return repository.watchGeofencesForPatient(patientId);
});

/// Provider untuk get active geofences count
///
/// Menghitung jumlah geofences yang aktif untuk patient
///
/// Parameter:
/// - [patientId]: ID pasien
final activeGeofencesCountProvider = FutureProvider.family<int, String>((
  ref,
  patientId,
) async {
  final repository = ref.watch(geofenceRepositoryProvider);
  final result = await repository.getActiveGeofencesCount(patientId);
  return result.fold(onSuccess: (count) => count, onFailure: (_) => 0);
});

/// Provider untuk geofence events stream (real-time)
///
/// Mengembalikan stream event enter/exit untuk patient tertentu
///
/// Parameter:
/// - [patientId]: ID pasien
final geofenceEventsStreamProvider =
    StreamProvider.family<List<GeofenceEvent>, String>((ref, patientId) {
      final repository = ref.watch(geofenceRepositoryProvider);
      return repository.watchGeofenceEvents(patientId);
    });

/// Provider untuk single geofence by ID
///
/// Mengambil detail geofence berdasarkan ID
///
/// Parameter:
/// - [geofenceId]: ID geofence
final geofenceByIdProvider = FutureProvider.family<Geofence, String>((
  ref,
  geofenceId,
) async {
  final repository = ref.watch(geofenceRepositoryProvider);
  final result = await repository.getGeofenceById(geofenceId);
  return result.fold(
    onSuccess: (geofence) => geofence,
    onFailure: (failure) => throw Exception(failure.message),
  );
});

/// Provider untuk geofence events dengan filter
///
/// Mengambil history events dengan opsi filter
///
/// Parameter map:
/// - patientId: String (required)
/// - geofenceId: String? (optional)
/// - limit: int? (optional, default 50)
final geofenceEventsProvider =
    FutureProvider.family<List<GeofenceEvent>, Map<String, dynamic>>((
      ref,
      params,
    ) async {
      final repository = ref.watch(geofenceRepositoryProvider);
      final result = await repository.getGeofenceEvents(
        patientId: params['patientId'] as String,
        geofenceId: params['geofenceId'] as String?,
        limit: params['limit'] as int? ?? 50,
      );
      return result.fold(
        onSuccess: (events) => events,
        onFailure: (_) => <GeofenceEvent>[],
      );
    });

/// Provider untuk geofence controller
///
/// Controller untuk mengelola CRUD operations geofences
final geofenceControllerProvider =
    StateNotifierProvider<GeofenceController, AsyncValue<void>>((ref) {
      return GeofenceController(ref.watch(geofenceRepositoryProvider));
    });

/// Geofence Controller untuk CRUD operations
///
/// Handles create, update, delete, dan toggle status geofences
class GeofenceController extends StateNotifier<AsyncValue<void>> {
  final GeofenceRepository _repository;

  GeofenceController(this._repository) : super(const AsyncValue.data(null));

  /// Create geofence baru
  ///
  /// Returns [Result<Geofence>] dengan geofence yang baru dibuat
  ///
  /// Validasi:
  /// - radius_meters: 50-10000 meter
  /// - priority: 1-10
  /// - minimal satu alert (enter/exit) harus aktif
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
    state = const AsyncValue.loading();

    final result = await _repository.createGeofence(
      patientId: patientId,
      name: name,
      description: description,
      fenceType: fenceType,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      alertOnEnter: alertOnEnter,
      alertOnExit: alertOnExit,
      priority: priority,
      address: address,
    );

    result.fold(
      onSuccess: (_) => state = const AsyncValue.data(null),
      onFailure: (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
    );

    return result;
  }

  /// Update geofence existing
  ///
  /// Parameters:
  /// - [geofenceId]: ID geofence yang akan diupdate
  /// - [updates]: Map dengan field yang akan diupdate
  ///
  /// Example:
  /// ```dart
  /// controller.updateGeofence(
  ///   geofenceId,
  ///   {'name': 'Rumah Baru', 'radius_meters': 600},
  /// );
  /// ```
  Future<Result<Geofence>> updateGeofence(
    String geofenceId,
    Map<String, dynamic> updates,
  ) async {
    state = const AsyncValue.loading();

    final result = await _repository.updateGeofence(geofenceId, updates);

    result.fold(
      onSuccess: (_) => state = const AsyncValue.data(null),
      onFailure: (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
    );

    return result;
  }

  /// Delete geofence
  ///
  /// Menghapus geofence dari database
  /// Events history akan tetap tersimpan (CASCADE behavior)
  Future<Result<void>> deleteGeofence(String geofenceId) async {
    state = const AsyncValue.loading();

    final result = await _repository.deleteGeofence(geofenceId);

    result.fold(
      onSuccess: (_) => state = const AsyncValue.data(null),
      onFailure: (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
    );

    return result;
  }

  /// Toggle status geofence (active/inactive)
  ///
  /// Mengubah status is_active menjadi kebalikannya
  /// Geofence inactive tidak akan dimonitor oleh GeofenceMonitoringService
  Future<Result<Geofence>> toggleGeofenceStatus(String geofenceId) async {
    state = const AsyncValue.loading();

    final result = await _repository.toggleGeofenceStatus(geofenceId);

    result.fold(
      onSuccess: (_) => state = const AsyncValue.data(null),
      onFailure: (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
    );

    return result;
  }

  /// Check if location is inside geofence
  ///
  /// Menggunakan PostGIS function di database untuk perhitungan akurat
  ///
  /// Returns:
  /// - [Result<bool>] true jika location di dalam geofence
  Future<Result<bool>> isLocationInsideGeofence(
    String geofenceId,
    double latitude,
    double longitude,
  ) async {
    return await _repository.isLocationInsideGeofence(
      geofenceId,
      latitude,
      longitude,
    );
  }
}

/// Provider untuk filtered geofences
///
/// Filter geofences by type dan active status
///
/// Parameter map:
/// - patientId: String (required)
/// - fenceType: FenceType? (optional)
/// - isActive: bool? (optional)
final filteredGeofencesProvider =
    FutureProvider.family<List<Geofence>, Map<String, dynamic>>((
      ref,
      params,
    ) async {
      final repository = ref.watch(geofenceRepositoryProvider);
      final result = await repository.getGeofencesForPatient(
        params['patientId'] as String,
        fenceType: params['fenceType'] as FenceType?,
        isActive: params['isActive'] as bool?,
      );
      return result.fold(
        onSuccess: (geofences) => geofences,
        onFailure: (_) => <Geofence>[],
      );
    });
