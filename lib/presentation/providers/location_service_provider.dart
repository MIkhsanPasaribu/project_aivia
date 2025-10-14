import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_aivia/data/services/location_service.dart';
import 'package:project_aivia/data/repositories/location_repository.dart';

/// Provider untuk LocationRepository
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository(supabase: Supabase.instance.client);
});

/// Provider untuk LocationService singleton
final locationServiceProvider = Provider<LocationService>((ref) {
  final locationRepository = ref.watch(locationRepositoryProvider);
  return LocationService(locationRepository);
});

/// Provider untuk tracking state (apakah sedang tracking)
final isTrackingProvider = StateProvider<bool>((ref) => false);

/// Provider untuk current tracking mode
final trackingModeProvider = StateProvider<TrackingMode>((ref) {
  return TrackingMode.balanced;
});
