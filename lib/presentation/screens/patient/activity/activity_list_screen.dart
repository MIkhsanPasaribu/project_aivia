import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_aivia/core/constants/app_colors.dart';
import 'package:project_aivia/core/constants/app_strings.dart';
import 'package:project_aivia/core/constants/app_dimensions.dart';
import 'package:project_aivia/core/utils/date_formatter.dart';
import 'package:project_aivia/data/models/activity.dart';
import 'package:project_aivia/presentation/providers/activity_provider.dart';
import 'package:project_aivia/presentation/providers/auth_provider.dart';
import 'package:project_aivia/presentation/screens/patient/activity/activity_form_dialog.dart';

/// Activity List Screen - Tampilan daftar aktivitas untuk Pasien dengan CRUD lengkap
class ActivityListScreen extends ConsumerWidget {
  const ActivityListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current user
    final currentUserAsync = ref.watch(currentUserProfileProvider);

    return currentUserAsync.when(
      data: (user) {
        if (user == null) {
          return const Scaffold(
            body: Center(child: Text('User tidak ditemukan')),
          );
        }

        // Watch activities stream untuk realtime updates
        final activitiesAsync = ref.watch(activitiesStreamProvider(user.id));

        return activitiesAsync.when(
          data: (activities) =>
              _buildActivityList(context, ref, user.id, activities),
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, stack) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  Text(
                    'Error: ${error.toString()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: AppDimensions.paddingL),
                  ElevatedButton(
                    onPressed: () {
                      ref.invalidate(activitiesStreamProvider);
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) =>
          Scaffold(body: Center(child: Text('Error: ${error.toString()}'))),
    );
  }

  Widget _buildActivityList(
    BuildContext context,
    WidgetRef ref,
    String patientId,
    List<Activity> activities,
  ) {
    if (activities.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(AppStrings.activityTitle),
          automaticallyImplyLeading: false,
        ),
        body: _buildEmptyState(context),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddActivityDialog(context, patientId),
          icon: const Icon(Icons.add),
          label: const Text('Tambah Aktivitas'),
          backgroundColor: AppColors.primary,
        ),
      );
    }

    // Group activities: Today and Upcoming
    final todayActivities = activities
        .where((activity) => activity.isToday)
        .toList();
    final upcomingActivities = activities
        .where((activity) => !activity.isToday)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.activityTitle),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh akan otomatis via realtime stream
          ref.invalidate(activitiesStreamProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          children: [
            if (todayActivities.isNotEmpty) ...[
              _buildSectionHeader(context, AppStrings.todayActivities),
              ...todayActivities.map(
                (activity) =>
                    _buildActivityCard(context, ref, patientId, activity),
              ),
              const SizedBox(height: AppDimensions.paddingL),
            ],
            if (upcomingActivities.isNotEmpty) ...[
              _buildSectionHeader(context, AppStrings.upcomingActivities),
              ...upcomingActivities.map(
                (activity) =>
                    _buildActivityCard(context, ref, patientId, activity),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddActivityDialog(context, patientId),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Aktivitas'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showAddActivityDialog(BuildContext context, String patientId) {
    showDialog(
      context: context,
      builder: (context) => ActivityFormDialog(patientId: patientId),
    );
  }

  void _showEditActivityDialog(
    BuildContext context,
    String patientId,
    Activity activity,
  ) {
    showDialog(
      context: context,
      builder: (context) =>
          ActivityFormDialog(patientId: patientId, activity: activity),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note_outlined,
            size: AppDimensions.iconXXL * 2,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: AppDimensions.paddingL),
          Text(
            AppStrings.noActivities,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimensions.paddingS,
        bottom: AppDimensions.paddingM,
        top: AppDimensions.paddingS,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    WidgetRef ref,
    String patientId,
    Activity activity,
  ) {
    final isPast = activity.isPast;
    final isCompleted = activity.isCompleted;

    return Dismissible(
      key: Key(activity.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppDimensions.paddingL),
        margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hapus Aktivitas'),
            content: Text(
              'Apakah Anda yakin ingin menghapus "${activity.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) async {
        final repository = ref.read(activityRepositoryProvider);
        final result = await repository.deleteActivity(activity.id);

        if (!context.mounted) return;

        result.fold(
          onSuccess: (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Aktivitas berhasil dihapus'),
                backgroundColor: AppColors.success,
              ),
            );
          },
          onFailure: (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message),
                backgroundColor: AppColors.error,
              ),
            );
          },
        );
      },
      child: Card(
        elevation: AppDimensions.cardElevation,
        margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
        child: InkWell(
          onTap: () => _showActivityDetail(context, ref, patientId, activity),
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle : Icons.access_time,
                    color: isCompleted ? AppColors.success : AppColors.primary,
                    size: AppDimensions.iconL,
                  ),
                ),

                const SizedBox(width: AppDimensions.paddingM),

                // Activity Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        activity.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                      ),

                      if (activity.description != null) ...[
                        const SizedBox(height: AppDimensions.paddingXS),
                        Text(
                          activity.description!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: AppDimensions.paddingS),

                      // Time
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: AppDimensions.iconS,
                            color: isPast && !isCompleted
                                ? AppColors.error
                                : AppColors.textTertiary,
                          ),
                          const SizedBox(width: AppDimensions.paddingXS),
                          Text(
                            DateFormatter.formatRelativeDateTime(
                              activity.activityTime,
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: isPast && !isCompleted
                                      ? AppColors.error
                                      : AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status Badge
                if (isCompleted)
                  Chip(
                    label: const Text(
                      AppStrings.activityCompleted,
                      style: TextStyle(fontSize: AppDimensions.fontXS),
                    ),
                    backgroundColor: AppColors.success.withValues(alpha: 0.2),
                    labelStyle: const TextStyle(color: AppColors.success),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showActivityDetail(
    BuildContext context,
    WidgetRef ref,
    String patientId,
    Activity activity,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppDimensions.radiusXL),
            topRight: Radius.circular(AppDimensions.radiusXL),
          ),
        ),
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.paddingL),

            // Title
            Text(
              activity.title,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: AppDimensions.paddingM),

            // Time
            Row(
              children: [
                const Icon(Icons.access_time, color: AppColors.primary),
                const SizedBox(width: AppDimensions.paddingS),
                Text(
                  DateFormatter.formatDateTimeLong(activity.activityTime),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),

            if (activity.description != null) ...[
              const SizedBox(height: AppDimensions.paddingM),
              const Divider(),
              const SizedBox(height: AppDimensions.paddingM),
              Text(
                'Deskripsi:',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppDimensions.paddingS),
              Text(
                activity.description!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],

            const SizedBox(height: AppDimensions.paddingL),

            // Action Buttons
            Row(
              children: [
                // Edit Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditActivityDialog(context, patientId, activity);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(
                        AppDimensions.buttonHeightL,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: AppDimensions.paddingM),

                // Complete/Completed Button
                Expanded(
                  child: activity.isCompleted
                      ? ElevatedButton.icon(
                          onPressed: null,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Selesai'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                              AppDimensions.buttonHeightL,
                            ),
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            final repository = ref.read(
                              activityRepositoryProvider,
                            );
                            final result = await repository.completeActivity(
                              activity.id,
                            );

                            if (!context.mounted) return;

                            result.fold(
                              onSuccess: (_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Aktivitas ditandai selesai'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              },
                              onFailure: (failure) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(failure.message),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              },
                            );
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Selesai'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(
                              AppDimensions.buttonHeightL,
                            ),
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                        ),
                ),
              ],
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
