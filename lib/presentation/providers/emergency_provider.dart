import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_aivia/data/models/emergency_contact.dart';
import 'package:project_aivia/data/models/emergency_alert.dart';
import 'package:project_aivia/data/repositories/emergency_repository.dart';
import 'package:project_aivia/core/utils/result.dart';

/// Provider untuk EmergencyRepository instance
final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  return EmergencyRepository();
});

// ========================================
// EMERGENCY CONTACTS PROVIDERS
// ========================================

/// Provider untuk emergency contacts stream (real-time updates)
/// Parameter: patientId
final emergencyContactsStreamProvider =
    StreamProvider.family<List<EmergencyContact>, String>((ref, patientId) {
      final emergencyRepository = ref.watch(emergencyRepositoryProvider);
      return emergencyRepository.getContactsStream(patientId);
    });

/// Provider untuk get emergency contacts (one-time fetch)
/// Parameter: patientId
final emergencyContactsProvider =
    FutureProvider.family<List<EmergencyContact>, String>((
      ref,
      patientId,
    ) async {
      final emergencyRepository = ref.watch(emergencyRepositoryProvider);

      final result = await emergencyRepository.getContacts(patientId);

      return result.fold(
        onSuccess: (contacts) => contacts,
        onFailure: (_) => <EmergencyContact>[],
      );
    });

// ========================================
// EMERGENCY ALERTS PROVIDERS
// ========================================

/// Provider untuk active alerts stream (real-time updates)
/// Parameter: patientId
final activeAlertsStreamProvider =
    StreamProvider.family<List<EmergencyAlert>, String>((ref, patientId) {
      final emergencyRepository = ref.watch(emergencyRepositoryProvider);
      return emergencyRepository.getActiveAlertsStream(patientId);
    });

/// Provider untuk get all alerts (one-time fetch)
/// Parameter: (patientId, status, limit)
final alertsProvider =
    FutureProvider.family<
      List<EmergencyAlert>,
      ({String patientId, String? status, int limit})
    >((ref, params) async {
      final emergencyRepository = ref.watch(emergencyRepositoryProvider);

      final result = await emergencyRepository.getAlerts(
        params.patientId,
        status: params.status,
        limit: params.limit,
      );

      return result.fold(
        onSuccess: (alerts) => alerts,
        onFailure: (_) => <EmergencyAlert>[],
      );
    });

/// Provider untuk active alert count
/// Parameter: patientId
final activeAlertCountProvider = FutureProvider.family<int, String>((
  ref,
  patientId,
) async {
  final emergencyRepository = ref.watch(emergencyRepositoryProvider);

  final result = await emergencyRepository.getActiveAlertCount(patientId);

  return result.fold(onSuccess: (count) => count, onFailure: (_) => 0);
});

/// Provider untuk latest alert
/// Parameter: patientId
final latestAlertProvider = FutureProvider.family<EmergencyAlert?, String>((
  ref,
  patientId,
) async {
  final emergencyRepository = ref.watch(emergencyRepositoryProvider);

  final result = await emergencyRepository.getLatestAlert(patientId);

  return result.fold(onSuccess: (alert) => alert, onFailure: (_) => null);
});

// ========================================
// EMERGENCY ACTIONS (AsyncNotifier)
// ========================================

/// State untuk emergency actions
class EmergencyActionsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // No initial state needed
  }

  /// Trigger emergency alert
  Future<Result<EmergencyAlert>> triggerEmergency({
    required String patientId,
    required String alertType,
    double? latitude,
    double? longitude,
    String? message,
    String severity = 'high',
  }) async {
    state = const AsyncLoading();

    final emergencyRepository = ref.read(emergencyRepositoryProvider);

    final result = await emergencyRepository.triggerEmergency(
      patientId: patientId,
      alertType: alertType,
      latitude: latitude,
      longitude: longitude,
      message: message,
      severity: severity,
    );

    result.fold(
      onSuccess: (_) {
        state = const AsyncData(null);
        // Invalidate alert providers untuk refresh
        ref.invalidate(activeAlertsStreamProvider);
        ref.invalidate(activeAlertCountProvider);
      },
      onFailure: (failure) {
        state = AsyncError(failure, StackTrace.current);
      },
    );

    return result;
  }

  /// Acknowledge alert
  Future<Result<EmergencyAlert>> acknowledgeAlert(String alertId) async {
    state = const AsyncLoading();

    final emergencyRepository = ref.read(emergencyRepositoryProvider);

    final result = await emergencyRepository.acknowledgeAlert(alertId);

    result.fold(
      onSuccess: (_) {
        state = const AsyncData(null);
        ref.invalidate(activeAlertsStreamProvider);
      },
      onFailure: (failure) {
        state = AsyncError(failure, StackTrace.current);
      },
    );

    return result;
  }

  /// Resolve alert
  Future<Result<EmergencyAlert>> resolveAlert({
    required String alertId,
    required String resolvedBy,
    String? notes,
    bool isFalseAlarm = false,
  }) async {
    state = const AsyncLoading();

    final emergencyRepository = ref.read(emergencyRepositoryProvider);

    final result = await emergencyRepository.resolveAlert(
      alertId: alertId,
      resolvedBy: resolvedBy,
      notes: notes,
      isFalseAlarm: isFalseAlarm,
    );

    result.fold(
      onSuccess: (_) {
        state = const AsyncData(null);
        // Invalidate alert providers untuk refresh
        ref.invalidate(activeAlertsStreamProvider);
        ref.invalidate(activeAlertCountProvider);
      },
      onFailure: (failure) {
        state = AsyncError(failure, StackTrace.current);
      },
    );

    return result;
  }

  /// Add emergency contact
  Future<Result<EmergencyContact>> addContact({
    required String patientId,
    required String contactId,
    required int priority,
    bool notificationEnabled = true,
  }) async {
    state = const AsyncLoading();

    final emergencyRepository = ref.read(emergencyRepositoryProvider);

    final result = await emergencyRepository.addContact(
      patientId: patientId,
      contactId: contactId,
      priority: priority,
      notificationEnabled: notificationEnabled,
    );

    result.fold(
      onSuccess: (_) {
        state = const AsyncData(null);
        ref.invalidate(emergencyContactsStreamProvider);
      },
      onFailure: (failure) {
        state = AsyncError(failure, StackTrace.current);
      },
    );

    return result;
  }

  /// Delete emergency contact
  Future<Result<void>> deleteContact(String contactId) async {
    state = const AsyncLoading();

    final emergencyRepository = ref.read(emergencyRepositoryProvider);

    final result = await emergencyRepository.deleteContact(contactId);

    result.fold(
      onSuccess: (_) {
        state = const AsyncData(null);
        ref.invalidate(emergencyContactsStreamProvider);
      },
      onFailure: (failure) {
        state = AsyncError(failure, StackTrace.current);
      },
    );

    return result;
  }
}

/// Provider untuk emergency actions notifier
final emergencyActionsProvider =
    AsyncNotifierProvider<EmergencyActionsNotifier, void>(() {
      return EmergencyActionsNotifier();
    });
