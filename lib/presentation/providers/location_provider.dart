import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_aivia/data/models/location.dart';
import 'package:project_aivia/data/repositories/location_repository.dart';

/// Provider untuk LocationRepository instance
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository();
});

/// Provider untuk last location stream (real-time updates)
/// Parameter: patientId
final lastLocationStreamProvider = StreamProvider.family<Location?, String>((
  ref,
  patientId,
) {
  final locationRepository = ref.watch(locationRepositoryProvider);
  return locationRepository.getLastLocationStream(patientId);
});

/// Provider untuk get last location (one-time fetch)
/// Parameter: patientId
final lastLocationProvider = FutureProvider.family<Location?, String>((
  ref,
  patientId,
) async {
  final locationRepository = ref.watch(locationRepositoryProvider);

  final result = await locationRepository.getLastLocation(patientId);

  return result.fold(onSuccess: (location) => location, onFailure: (_) => null);
});

/// Provider untuk location history dengan time range
/// Parameter: (patientId, startTime, limit)
final locationHistoryProvider =
    FutureProvider.family<
      List<Location>,
      ({String patientId, DateTime? startTime, DateTime? endTime, int limit})
    >((ref, params) async {
      final locationRepository = ref.watch(locationRepositoryProvider);

      final result = await locationRepository.getLocationHistory(
        params.patientId,
        startTime: params.startTime,
        endTime: params.endTime,
        limit: params.limit,
      );

      return result.fold(
        onSuccess: (locations) => locations,
        onFailure: (_) => <Location>[],
      );
    });

/// Provider untuk recent locations (last 24 hours)
final recentLocationsProvider = FutureProvider.family<List<Location>, String>((
  ref,
  patientId,
) async {
  final locationRepository = ref.watch(locationRepositoryProvider);

  final startTime = DateTime.now().subtract(const Duration(hours: 24));

  final result = await locationRepository.getLocationHistory(
    patientId,
    startTime: startTime,
    limit: 100,
  );

  return result.fold(
    onSuccess: (locations) => locations,
    onFailure: (_) => <Location>[],
  );
});

/// Formatted last location untuk UI
/// Returns "lat, lng" atau "Unknown" jika null
final formattedLastLocationProvider = FutureProvider.family<String, String>((
  ref,
  patientId,
) async {
  final lastLocation = await ref.watch(lastLocationProvider(patientId).future);

  if (lastLocation == null) {
    return 'Unknown';
  }

  return lastLocation.formattedLocation;
});
