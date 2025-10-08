import 'package:flutter/material.dart';
import 'package:project_aivia/core/constants/app_colors.dart';
import 'package:project_aivia/core/constants/app_strings.dart';
import 'package:project_aivia/core/constants/app_dimensions.dart';
import 'package:project_aivia/core/utils/date_formatter.dart';
import 'package:project_aivia/data/models/activity.dart';

/// Activity List Screen - Tampilan daftar aktivitas untuk Pasien
class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({super.key});

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen> {
  // TODO: Replace with Riverpod provider
  // Dummy data untuk testing
  final List<Activity> _activities = [
    Activity(
      id: '1',
      patientId: '1',
      title: 'Makan Pagi',
      description: 'Sarapan dengan menu yang sudah disiapkan',
      activityTime: DateTime.now().add(const Duration(hours: 1)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Activity(
      id: '2',
      patientId: '1',
      title: 'Minum Obat',
      description: 'Jangan lupa minum obat setelah makan',
      activityTime: DateTime.now().add(const Duration(hours: 2)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    Activity(
      id: '3',
      patientId: '1',
      title: 'Jalan Pagi',
      description: 'Olahraga ringan selama 30 menit',
      activityTime: DateTime.now().add(const Duration(hours: 3)),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.activityTitle),
        automaticallyImplyLeading: false,
      ),
      body: _activities.isEmpty
          ? _buildEmptyState()
          : _buildActivityList(),
    );
  }

  Widget _buildEmptyState() {
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    // Group activities: Today and Upcoming
    final todayActivities = _activities.where((activity) => activity.isToday).toList();
    final upcomingActivities = _activities.where((activity) => !activity.isToday).toList();

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Refresh activities from Supabase
        await Future.delayed(const Duration(seconds: 1));
      },
      child: ListView(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        children: [
          if (todayActivities.isNotEmpty) ...[
            _buildSectionHeader(AppStrings.todayActivities),
            ...todayActivities.map((activity) => _buildActivityCard(activity)),
            const SizedBox(height: AppDimensions.paddingL),
          ],
          if (upcomingActivities.isNotEmpty) ...[
            _buildSectionHeader(AppStrings.upcomingActivities),
            ...upcomingActivities.map((activity) => _buildActivityCard(activity)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
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

  Widget _buildActivityCard(Activity activity) {
    final isPast = activity.isPast;
    final isCompleted = activity.isCompleted;

    return Card(
      elevation: AppDimensions.cardElevation,
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      child: InkWell(
        onTap: () => _showActivityDetail(activity),
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
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.primary.withOpacity(0.1),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                    ),

                    if (activity.description != null) ...[
                      const SizedBox(height: AppDimensions.paddingXS),
                      Text(
                        activity.description!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
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
                          DateFormatter.formatRelativeDateTime(activity.activityTime),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                  backgroundColor: AppColors.success.withOpacity(0.2),
                  labelStyle: const TextStyle(color: AppColors.success),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActivityDetail(Activity activity) {
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
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppDimensions.paddingS),
              Text(
                activity.description!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],

            const SizedBox(height: AppDimensions.paddingL),

            // Mark as Complete Button
            if (!activity.isCompleted)
              ElevatedButton(
                onPressed: () {
                  // TODO: Mark activity as complete
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Aktivitas ditandai selesai'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppDimensions.buttonHeightL),
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tandai Selesai'),
              ),

            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
