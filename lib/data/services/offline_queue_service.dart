import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:project_aivia/core/utils/result.dart';
import 'package:project_aivia/core/errors/failures.dart';
import 'package:project_aivia/core/utils/connectivity_helper.dart';
import 'package:project_aivia/data/models/location.dart';
import 'package:project_aivia/data/services/location_queue_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Offline queue service untuk manage location data saat no network
///
/// Features:
/// - Queue locations to local SQLite when offline
/// - Auto-sync when network available
/// - Retry logic (max 5 attempts)
/// - Batch sync untuk performance
///
/// Best Practice: Offline-first architecture
class OfflineQueueService {
  final LocationQueueDatabase _db;
  final SupabaseClient _supabase;
  final ConnectivityHelper _connectivity;

  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _periodicSyncTimer;

  // Statistics
  int _totalQueued = 0;
  int _totalSynced = 0;
  int _totalFailed = 0;

  OfflineQueueService({
    LocationQueueDatabase? database,
    SupabaseClient? supabase,
    ConnectivityHelper? connectivity,
  }) : _db = database ?? LocationQueueDatabase(),
       _supabase = supabase ?? Supabase.instance.client,
       _connectivity = connectivity ?? ConnectivityHelper();

  /// Initialize service
  Future<void> initialize() async {
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      isOnline,
    ) {
      if (isOnline) {
        // Connected - trigger sync
        syncPendingLocations();
      }
    });

    // Periodic sync every 5 minutes (backup untuk jika connectivity event missed)
    _periodicSyncTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => syncPendingLocations(),
    );

    // Initial sync jika online
    if (await _connectivity.isOnline()) {
      await syncPendingLocations();
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
  }

  /// Queue location to local database
  Future<Result<void>> queueLocation(
    Location location, {
    double? altitude,
    double? speed,
    double? heading,
    int? batteryLevel,
    bool isBackground = false,
  }) async {
    try {
      final queuedLocation = QueuedLocation.fromLocation(
        location,
        altitude: altitude,
        speed: speed,
        heading: heading,
        batteryLevel: batteryLevel,
        isBackground: isBackground,
      );

      await _db.insert(queuedLocation);
      _totalQueued++;

      // Try immediate sync if online
      if (await _connectivity.isOnline()) {
        // Fire and forget (tidak await untuk tidak block UI)
        syncPendingLocations();
      }

      return const Success(null);
    } catch (e) {
      return ResultFailure(ServerFailure(e.toString()));
    }
  }

  /// Sync pending locations to Supabase
  Future<Result<SyncResult>> syncPendingLocations() async {
    try {
      // Check network first
      if (!await _connectivity.isOnline()) {
        return const ResultFailure(NetworkFailure());
      }

      // Get unsynced locations
      final locations = await _db.getUnsynced(maxRetries: 5);

      if (locations.isEmpty) {
        return Success(SyncResult(synced: 0, failed: 0, remaining: 0));
      }

      int syncedCount = 0;
      int failedCount = 0;

      // Sync each location
      for (final location in locations) {
        try {
          // Insert to Supabase
          await _supabase.from('locations').insert(location.toSupabaseMap());

          // Mark as synced
          await _db.markSynced(location.id!);
          syncedCount++;
          _totalSynced++;
        } catch (e) {
          // Increment retry count
          await _db.incrementRetry(location.id!);
          failedCount++;
          _totalFailed++;

          // Log error (future: send to Crashlytics)
          debugPrint('Failed to sync location ${location.id}: $e');
        }
      }

      // Cleanup synced records (keep for 1 day for debugging)
      await _db.deleteOlderThan(const Duration(days: 1));

      // Get remaining count
      final stats = await _db.getStats();

      return Success(
        SyncResult(
          synced: syncedCount,
          failed: failedCount,
          remaining: stats.unsynced,
        ),
      );
    } catch (e) {
      return ResultFailure(ServerFailure(e.toString()));
    }
  }

  /// Get current queue statistics
  Future<QueueStats> getStats() async {
    return await _db.getStats();
  }

  /// Get failed locations (exceeded max retries)
  Future<List<QueuedLocation>> getFailedLocations() async {
    return await _db.getFailedLocations();
  }

  /// Retry failed locations (reset retry count)
  Future<Result<void>> retryFailedLocations() async {
    try {
      final failed = await _db.getFailedLocations();

      for (final location in failed) {
        // Reset retry count dan try again
        await _supabase.from('locations').insert(location.toSupabaseMap());

        await _db.markSynced(location.id!);
      }

      return const Success(null);
    } catch (e) {
      return ResultFailure(ServerFailure(e.toString()));
    }
  }

  /// Clear all queue (testing only)
  Future<void> clearQueue() async {
    await _db.clearAll();
    _totalQueued = 0;
    _totalSynced = 0;
    _totalFailed = 0;
  }

  // Getters untuk monitoring
  int get totalQueued => _totalQueued;
  int get totalSynced => _totalSynced;
  int get totalFailed => _totalFailed;
}

/// Result dari sync operation
class SyncResult {
  final int synced;
  final int failed;
  final int remaining;

  SyncResult({
    required this.synced,
    required this.failed,
    required this.remaining,
  });

  bool get hasErrors => failed > 0;
  bool get isComplete => remaining == 0;

  @override
  String toString() {
    return 'SyncResult(synced: $synced, failed: $failed, remaining: $remaining)';
  }
}
