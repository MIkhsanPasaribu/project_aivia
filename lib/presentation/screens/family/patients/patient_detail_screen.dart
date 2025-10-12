import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_aivia/core/constants/app_colors.dart';
import 'package:project_aivia/core/constants/app_dimensions.dart';
import 'package:project_aivia/data/models/user_profile.dart';
import 'package:project_aivia/data/models/activity.dart';
import 'package:project_aivia/presentation/providers/activity_provider.dart';
import 'package:project_aivia/presentation/widgets/common/loading_indicator.dart';
import 'package:project_aivia/presentation/widgets/common/error_widget.dart';
import 'package:intl/intl.dart';

/// Patient Detail Screen - Halaman detail pasien untuk keluarga
///
/// Features:
/// - Patient header card (foto, nama, info dasar)
/// - Quick stats (aktivitas hari ini, minggu ini)
/// - Recent activities list
/// - Emergency contact info
/// - Action buttons (call, message, navigate)
class PatientDetailScreen extends ConsumerWidget {
  final UserProfile patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar dengan gradient
          _buildSliverAppBar(context),

          // Content
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Patient Info Card
                _buildPatientInfoCard(context),

                SizedBox(height: AppDimensions.paddingL),

                // Quick Stats
                _buildQuickStats(context, ref),

                SizedBox(height: AppDimensions.paddingL),

                // Recent Activities
                _buildRecentActivities(context, ref),

                SizedBox(height: AppDimensions.paddingL),

                // Emergency Actions
                _buildEmergencyActions(context),

                SizedBox(height: AppDimensions.paddingXL),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Detail Pasien',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientInfoCard(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(AppDimensions.paddingM),
      padding: EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            backgroundImage: patient.avatarUrl != null
                ? NetworkImage(patient.avatarUrl!)
                : null,
            child: patient.avatarUrl == null
                ? Icon(Icons.person, size: 50, color: AppColors.primary)
                : null,
          ),

          SizedBox(height: AppDimensions.paddingM),

          // Name
          Text(
            patient.fullName,
            style: const TextStyle(
              fontSize: AppDimensions.fontXXL,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: AppDimensions.paddingS),

          // Email
          Text(
            patient.email,
            style: const TextStyle(
              fontSize: AppDimensions.fontM,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: AppDimensions.paddingM),

          // Status Badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
              vertical: AppDimensions.paddingS,
            ),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: AppDimensions.paddingS),
                const Text(
                  'Terhubung',
                  style: TextStyle(
                    fontSize: AppDimensions.fontS,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesStreamProvider(patient.id));

    return activitiesAsync.when(
      loading: () => const LoadingIndicator(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (activities) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final weekAgo = today.subtract(const Duration(days: 7));

        final todayActivities = activities.where((a) {
          final activityDate = DateTime(
            a.activityTime.year,
            a.activityTime.month,
            a.activityTime.day,
          );
          return activityDate.isAtSameMomentAs(today);
        }).length;

        final weekActivities = activities.where((a) {
          return a.activityTime.isAfter(weekAgo);
        }).length;

        final completedToday = activities.where((a) {
          final activityDate = DateTime(
            a.activityTime.year,
            a.activityTime.month,
            a.activityTime.day,
          );
          return activityDate.isAtSameMomentAs(today) && a.isCompleted;
        }).length;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.today,
                  value: '$todayActivities',
                  label: 'Aktivitas Hari Ini',
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.check_circle,
                  value: '$completedToday',
                  label: 'Selesai Hari Ini',
                  color: AppColors.success,
                ),
              ),
              SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: _buildStatCard(
                  context,
                  icon: Icons.calendar_today,
                  value: '$weekActivities',
                  label: 'Minggu Ini',
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: AppDimensions.iconM),
          SizedBox(height: AppDimensions.paddingS),
          Text(
            value,
            style: TextStyle(
              fontSize: AppDimensions.fontXXL,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: AppDimensions.paddingXS),
          Text(
            label,
            style: const TextStyle(
              fontSize: AppDimensions.fontXS,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(activitiesStreamProvider(patient.id));

    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
      padding: EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Aktivitas Terbaru',
                style: TextStyle(
                  fontSize: AppDimensions.fontL,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to full activities list
                },
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          SizedBox(height: AppDimensions.paddingM),
          activitiesAsync.when(
            loading: () => const LoadingIndicator(),
            error: (error, stack) =>
                CustomErrorWidget.general(message: error.toString()),
            data: (activities) {
              if (activities.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Text(
                      'Belum ada aktivitas',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                );
              }

              // Show only last 5 activities
              final recentActivities = activities.take(5).toList();

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentActivities.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final activity = recentActivities[index];
                  return _buildActivityItem(context, activity);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, Activity activity) {
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('dd MMM yyyy');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: EdgeInsets.all(AppDimensions.paddingS),
        decoration: BoxDecoration(
          color: activity.isCompleted
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: Icon(
          activity.isCompleted ? Icons.check_circle : Icons.schedule,
          color: activity.isCompleted ? AppColors.success : AppColors.primary,
        ),
      ),
      title: Text(
        activity.title,
        style: const TextStyle(
          fontSize: AppDimensions.fontM,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        '${timeFormat.format(activity.activityTime)} • ${dateFormat.format(activity.activityTime)}',
        style: const TextStyle(
          fontSize: AppDimensions.fontS,
          color: AppColors.textSecondary,
        ),
      ),
      trailing: activity.isCompleted
          ? Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingS,
                vertical: AppDimensions.paddingXS,
              ),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
              ),
              child: const Text(
                'Selesai',
                style: TextStyle(
                  fontSize: AppDimensions.fontXS,
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmergencyActions(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppDimensions.paddingM),
      padding: EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aksi Cepat',
            style: TextStyle(
              fontSize: AppDimensions.fontL,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppDimensions.paddingM),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.phone,
                  label: 'Telepon',
                  color: AppColors.success,
                  onTap: () {
                    // TODO: Implement call functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur telepon akan segera hadir'),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.message,
                  label: 'Pesan',
                  color: AppColors.primary,
                  onTap: () {
                    // TODO: Implement message functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur pesan akan segera hadir'),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: AppDimensions.paddingM),
              Expanded(
                child: _buildActionButton(
                  context,
                  icon: Icons.location_on,
                  label: 'Lokasi',
                  color: AppColors.error,
                  onTap: () {
                    // TODO: Navigate to map screen (Phase 2)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur peta akan tersedia di Phase 2'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: AppDimensions.iconL),
            SizedBox(height: AppDimensions.paddingS),
            Text(
              label,
              style: TextStyle(
                fontSize: AppDimensions.fontS,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
