import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_aivia/data/models/activity.dart';
import 'package:project_aivia/data/repositories/activity_repository.dart';
import 'package:project_aivia/core/utils/result.dart';
import 'package:project_aivia/data/services/notification_service.dart';

/// Provider untuk ActivityRepository instance
final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository();
});

/// Provider untuk activities stream (real-time updates)
/// Parameter: patientId
final activitiesStreamProvider = StreamProvider.family<List<Activity>, String>((
  ref,
  patientId,
) {
  final activityRepository = ref.watch(activityRepositoryProvider);
  return activityRepository.getActivitiesStream(patientId);
});

/// Provider untuk get today's activities
final todayActivitiesProvider = FutureProvider.family<List<Activity>, String>((
  ref,
  patientId,
) async {
  final activityRepository = ref.watch(activityRepositoryProvider);

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

  final result = await activityRepository.getActivities(
    patientId,
    startDate: startOfDay,
    endDate: endOfDay,
  );

  return result.fold(
    onSuccess: (activities) => activities,
    onFailure: (_) => <Activity>[],
  );
});

/// Provider untuk activity controller
final activityControllerProvider =
    StateNotifierProvider<ActivityController, AsyncValue<void>>((ref) {
      return ActivityController(ref.watch(activityRepositoryProvider));
    });

/// Activity Controller untuk mengelola CRUD operations
class ActivityController extends StateNotifier<AsyncValue<void>> {
  final ActivityRepository _activityRepository;

  ActivityController(this._activityRepository)
    : super(const AsyncValue.data(null));

  /// Create new activity
  Future<Result<Activity>> createActivity({
    required String patientId,
    required String title,
    String? description,
    required DateTime activityTime,
    int reminderMinutesBefore = 15,
    String? createdBy,
  }) async {
    state = const AsyncValue.loading();

    final result = await _activityRepository.createActivity(
      patientId: patientId,
      title: title,
      description: description,
      activityTime: activityTime,
      reminderMinutesBefore: reminderMinutesBefore,
      createdBy: createdBy,
    );

    result.fold(
      onSuccess: (activity) {
        state = const AsyncValue.data(null);

        // 🔔 Schedule notification untuk activity baru
        NotificationService.scheduleActivityReminder(
          activityId: activity.id,
          title: activity.title,
          body: activity.description,
          scheduledTime: activity.activityTime,
          minutesBefore: reminderMinutesBefore,
        );
      },
      onFailure: (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
    );

    return result;
  }

  /// Update existing activity
  Future<Result<Activity>> updateActivity({
    required String activityId,
    String? title,
    String? description,
    DateTime? activityTime,
    int? reminderMinutesBefore,
  }) async {
    state = const AsyncValue.loading();

    final result = await _activityRepository.updateActivity(
      activityId: activityId,
      title: title,
      description: description,
      activityTime: activityTime,
      reminderMinutesBefore: reminderMinutesBefore,
    );

    result.fold(
      onSuccess: (activity) {
        state = const AsyncValue.data(null);

        // 🔔 Cancel old notification dan schedule ulang jika waktu berubah
        if (activityTime != null) {
          NotificationService.cancelActivityReminder(activityId);
          NotificationService.scheduleActivityReminder(
            activityId: activity.id,
            title: activity.title,
            body: activity.description,
            scheduledTime: activity.activityTime,
            minutesBefore: reminderMinutesBefore ?? 15,
          );
        }
      },
      onFailure: (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
    );

    return result;
  }

  /// Delete activity
  Future<Result<void>> deleteActivity(String activityId) async {
    state = const AsyncValue.loading();

    // 🔔 Cancel notification sebelum delete
    await NotificationService.cancelActivityReminder(activityId);

    final result = await _activityRepository.deleteActivity(activityId);

    result.fold(
      onSuccess: (_) => state = const AsyncValue.data(null),
      onFailure: (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
    );

    return result;
  }

  /// Mark activity as completed
  Future<Result<Activity>> completeActivity(String activityId) async {
    state = const AsyncValue.loading();

    final result = await _activityRepository.completeActivity(activityId);

    result.fold(
      onSuccess: (_) => state = const AsyncValue.data(null),
      onFailure: (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
    );

    return result;
  }

  /// Mark activity as incomplete
  Future<Result<Activity>> uncompleteActivity(String activityId) async {
    state = const AsyncValue.loading();

    final result = await _activityRepository.uncompleteActivity(activityId);

    result.fold(
      onSuccess: (_) => state = const AsyncValue.data(null),
      onFailure: (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
    );

    return result;
  }

  /// Get single activity by ID
  Future<Result<Activity>> getActivity(String activityId) async {
    return await _activityRepository.getActivity(activityId);
  }
}
