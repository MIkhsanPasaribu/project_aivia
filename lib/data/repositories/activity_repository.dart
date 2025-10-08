import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_aivia/core/errors/failures.dart';
import 'package:project_aivia/core/utils/result.dart';
import 'package:project_aivia/data/models/activity.dart';

/// Repository untuk manajemen aktivitas harian pasien
/// Menggunakan Supabase Realtime untuk live updates
class ActivityRepository {
  final SupabaseClient _supabase;

  ActivityRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  /// Get activities stream untuk realtime updates
  ///
  /// Stream akan emit data baru setiap kali ada perubahan di database
  /// Cocok untuk UI yang perlu real-time updates
  Stream<List<Activity>> getActivitiesStream(String patientId) {
    return _supabase
        .from('activities')
        .stream(primaryKey: ['id'])
        .eq('patient_id', patientId)
        .order('activity_time', ascending: true)
        .map((data) => data.map((json) => Activity.fromJson(json)).toList());
  }

  /// Get activities (one-time fetch)
  ///
  /// Untuk kasus yang tidak butuh realtime, lebih efisien
  Future<Result<List<Activity>>> getActivities(
    String patientId, {
    DateTime? startDate,
    DateTime? endDate,
    bool? isCompleted,
  }) async {
    try {
      var query = _supabase
          .from('activities')
          .select()
          .eq('patient_id', patientId);

      // Filter by date range
      if (startDate != null) {
        query = query.gte('activity_time', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('activity_time', endDate.toIso8601String());
      }

      // Filter by completion status
      if (isCompleted != null) {
        query = query.eq('is_completed', isCompleted);
      }

      final data = await query.order('activity_time', ascending: true);
      final activities = data.map((json) => Activity.fromJson(json)).toList();

      return Success(activities);
    } on PostgrestException catch (e) {
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(
        UnknownFailure('Gagal mengambil aktivitas: ${e.toString()}'),
      );
    }
  }

  /// Get single activity by ID
  Future<Result<Activity>> getActivity(String activityId) async {
    try {
      final data = await _supabase
          .from('activities')
          .select()
          .eq('id', activityId)
          .single();

      final activity = Activity.fromJson(data);
      return Success(activity);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return const ResultFailure(
          DatabaseFailure('Aktivitas tidak ditemukan', code: 'not_found'),
        );
      }
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(
        UnknownFailure('Gagal mengambil aktivitas: ${e.toString()}'),
      );
    }
  }

  /// Create new activity
  ///
  /// Akan trigger notification otomatis via database trigger
  Future<Result<Activity>> createActivity({
    required String patientId,
    required String title,
    String? description,
    required DateTime activityTime,
    int reminderMinutesBefore = 15,
    String? createdBy,
  }) async {
    try {
      final now = DateTime.now();

      final activityData = {
        'patient_id': patientId,
        'title': title,
        'description': description,
        'activity_time': activityTime.toIso8601String(),
        'reminder_minutes_before': reminderMinutesBefore,
        'is_completed': false,
        'created_by': createdBy,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final data = await _supabase
          .from('activities')
          .insert(activityData)
          .select()
          .single();

      final activity = Activity.fromJson(data);
      return Success(activity);
    } on PostgrestException catch (e) {
      if (e.code == '23514') {
        // Check constraint violation (activity_time_check)
        return const ResultFailure(
          ValidationFailure('Waktu aktivitas tidak valid. Harus di masa depan'),
        );
      } else if (e.code == '42501') {
        // Permission denied
        return const ResultFailure(
          DatabaseFailure(
            'Anda tidak memiliki izin',
            code: 'permission_denied',
          ),
        );
      }
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(
        UnknownFailure('Gagal membuat aktivitas: ${e.toString()}'),
      );
    }
  }

  /// Update existing activity
  Future<Result<Activity>> updateActivity({
    required String activityId,
    String? title,
    String? description,
    DateTime? activityTime,
    int? reminderMinutesBefore,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (activityTime != null) {
        updates['activity_time'] = activityTime.toIso8601String();
      }
      if (reminderMinutesBefore != null) {
        updates['reminder_minutes_before'] = reminderMinutesBefore;
      }

      final data = await _supabase
          .from('activities')
          .update(updates)
          .eq('id', activityId)
          .select()
          .single();

      final activity = Activity.fromJson(data);
      return Success(activity);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return const ResultFailure(
          DatabaseFailure('Aktivitas tidak ditemukan', code: 'not_found'),
        );
      } else if (e.code == '42501') {
        return const ResultFailure(
          DatabaseFailure(
            'Anda tidak memiliki izin',
            code: 'permission_denied',
          ),
        );
      }
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(
        UnknownFailure('Gagal update aktivitas: ${e.toString()}'),
      );
    }
  }

  /// Delete activity
  Future<Result<void>> deleteActivity(String activityId) async {
    try {
      await _supabase.from('activities').delete().eq('id', activityId);
      return const Success(null);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return const ResultFailure(
          DatabaseFailure('Aktivitas tidak ditemukan', code: 'not_found'),
        );
      } else if (e.code == '42501') {
        return const ResultFailure(
          DatabaseFailure(
            'Anda tidak memiliki izin',
            code: 'permission_denied',
          ),
        );
      }
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(
        UnknownFailure('Gagal menghapus aktivitas: ${e.toString()}'),
      );
    }
  }

  /// Mark activity as completed
  Future<Result<Activity>> completeActivity(String activityId) async {
    try {
      final data = await _supabase
          .from('activities')
          .update({
            'is_completed': true,
            'completed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', activityId)
          .select()
          .single();

      final activity = Activity.fromJson(data);
      return Success(activity);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return const ResultFailure(
          DatabaseFailure('Aktivitas tidak ditemukan', code: 'not_found'),
        );
      }
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(
        UnknownFailure('Gagal menandai selesai: ${e.toString()}'),
      );
    }
  }

  /// Mark activity as incomplete
  Future<Result<Activity>> uncompleteActivity(String activityId) async {
    try {
      final data = await _supabase
          .from('activities')
          .update({
            'is_completed': false,
            'completed_at': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', activityId)
          .select()
          .single();

      final activity = Activity.fromJson(data);
      return Success(activity);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return const ResultFailure(
          DatabaseFailure('Aktivitas tidak ditemukan', code: 'not_found'),
        );
      }
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(
        UnknownFailure('Gagal mengubah status: ${e.toString()}'),
      );
    }
  }

  /// Get today's activities
  Future<Result<List<Activity>>> getTodayActivities(String patientId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getActivities(patientId, startDate: startOfDay, endDate: endOfDay);
  }

  /// Get pending activities (not completed yet)
  Future<Result<List<Activity>>> getPendingActivities(String patientId) async {
    return getActivities(patientId, isCompleted: false);
  }

  /// Get completed activities
  Future<Result<List<Activity>>> getCompletedActivities(
    String patientId,
  ) async {
    return getActivities(patientId, isCompleted: true);
  }

  /// Get activity statistics
  Future<Result<Map<String, dynamic>>> getActivityStats(
    String patientId, {
    int daysBack = 7,
  }) async {
    try {
      final result = await _supabase
          .rpc(
            'get_activity_stats',
            params: {'patient_id_param': patientId, 'days_back': daysBack},
          )
          .single();

      return Success(result);
    } on PostgrestException catch (e) {
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(
        UnknownFailure('Gagal mengambil statistik: ${e.toString()}'),
      );
    }
  }
}
