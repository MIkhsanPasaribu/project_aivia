import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/activity.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../providers/activity_provider.dart';
import '../../../widgets/common/empty_state_widget.dart';
import '../../../widgets/common/error_widget.dart';
import '../../../widgets/common/loading_indicator.dart';
import '../../../widgets/common/confirmation_dialog.dart';
import 'add_activity_screen.dart';
import 'edit_activity_screen.dart';

/// Screen untuk mengelola aktivitas pasien (Family View)
///
/// Features:
/// - List view aktivitas pasien
/// - Filter berdasarkan status (upcoming, completed, all)
/// - Search functionality
/// - Pull to refresh
/// - Add FAB
/// - Edit on tap
/// - Delete dengan confirmation
/// - Mark as complete
class ManageActivitiesScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String patientName;

  const ManageActivitiesScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  ConsumerState<ManageActivitiesScreen> createState() =>
      _ManageActivitiesScreenState();
}

class _ManageActivitiesScreenState
    extends ConsumerState<ManageActivitiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  ActivityFilter _currentFilter = ActivityFilter.upcoming;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activitiesAsync = ref.watch(
      activitiesStreamProvider(widget.patientId),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kelola Aktivitas'),
            Text(
              widget.patientName,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          // Filter menu
          PopupMenuButton<ActivityFilter>(
            icon: Icon(
              Icons.filter_list,
              color: Theme.of(context).colorScheme.primary,
            ),
            onSelected: (filter) {
              setState(() {
                _currentFilter = filter;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ActivityFilter.upcoming,
                child: Row(
                  children: [
                    Icon(
                      Icons.upcoming,
                      color: _currentFilter == ActivityFilter.upcoming
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Akan Datang',
                      style: TextStyle(
                        color: _currentFilter == ActivityFilter.upcoming
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ActivityFilter.completed,
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: _currentFilter == ActivityFilter.completed
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Selesai',
                      style: TextStyle(
                        color: _currentFilter == ActivityFilter.completed
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ActivityFilter.all,
                child: Row(
                  children: [
                    Icon(
                      Icons.list,
                      color: _currentFilter == ActivityFilter.all
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Semua',
                      style: TextStyle(
                        color: _currentFilter == ActivityFilter.all
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(AppDimensions.paddingMedium),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari aktivitas...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? Colors.grey[850]
                    : AppColors.background.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.borderRadiusMedium,
                  ),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingMedium,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Activities list
          Expanded(
            child: activitiesAsync.when(
              data: (activities) {
                // Filter berdasarkan filter aktif
                var filteredActivities = activities.where((activity) {
                  switch (_currentFilter) {
                    case ActivityFilter.upcoming:
                      return !activity.isCompleted &&
                          activity.activityTime.isAfter(DateTime.now());
                    case ActivityFilter.completed:
                      return activity.isCompleted;
                    case ActivityFilter.all:
                      return true;
                  }
                }).toList();

                // Filter berdasarkan search query
                if (_searchQuery.isNotEmpty) {
                  filteredActivities = filteredActivities.where((activity) {
                    final title = activity.title.toLowerCase();
                    final description =
                        activity.description?.toLowerCase() ?? '';
                    return title.contains(_searchQuery) ||
                        description.contains(_searchQuery);
                  }).toList();
                }

                if (filteredActivities.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.event_busy,
                    title: _searchQuery.isNotEmpty
                        ? 'Tidak Ada Hasil'
                        : 'Belum Ada Aktivitas',
                    description: _searchQuery.isNotEmpty
                        ? 'Tidak ada aktivitas yang cocok dengan pencarian'
                        : 'Tambahkan aktivitas untuk pasien ini',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(activitiesStreamProvider(widget.patientId));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppDimensions.paddingMedium),
                    itemCount: filteredActivities.length,
                    itemBuilder: (context, index) {
                      final activity = filteredActivities[index];
                      return _ActivityCard(
                        activity: activity,
                        onTap: () => _navigateToEdit(activity),
                        onDelete: () => _confirmDelete(activity),
                        onToggleComplete: () => _toggleComplete(activity),
                      );
                    },
                  ),
                );
              },
              loading: () =>
                  const LoadingIndicator(message: 'Memuat aktivitas...'),
              error: (error, stack) => CustomErrorWidget(
                message: 'Gagal memuat aktivitas',
                onRetry: () {
                  ref.invalidate(activitiesStreamProvider(widget.patientId));
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAdd(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Aktivitas'),
      ),
    );
  }

  void _navigateToAdd() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddActivityScreen(
          patientId: widget.patientId,
          patientName: widget.patientName,
        ),
      ),
    );
  }

  void _navigateToEdit(Activity activity) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditActivityScreen(
          activity: activity,
          patientName: widget.patientName,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Activity activity) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Hapus Aktivitas',
      description:
          'Apakah Anda yakin ingin menghapus aktivitas "${activity.title}"?',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      isDestructive: true,
    );

    if (confirmed == true) {
      await _deleteActivity(activity);
    }
  }

  Future<void> _deleteActivity(Activity activity) async {
    final controller = ref.read(activityControllerProvider.notifier);
    await controller.deleteActivity(activity.id);

    if (!mounted) return;

    final state = ref.read(activityControllerProvider);
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aktivitas berhasil dihapus'),
            backgroundColor: AppColors.success,
          ),
        );
      },
      loading: () {},
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus aktivitas: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );
  }

  Future<void> _toggleComplete(Activity activity) async {
    final controller = ref.read(activityControllerProvider.notifier);

    if (activity.isCompleted) {
      await controller.uncompleteActivity(activity.id);
    } else {
      await controller.completeActivity(activity.id);
    }

    if (!mounted) return;

    final state = ref.read(activityControllerProvider);
    state.when(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              activity.isCompleted
                  ? 'Aktivitas ditandai belum selesai'
                  : 'Aktivitas ditandai selesai',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      },
      loading: () {},
      error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengupdate aktivitas: $error'),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );
  }
}

/// Activity Card Widget
class _ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleComplete;

  const _ActivityCard({
    required this.activity,
    required this.onTap,
    required this.onDelete,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverdue =
        !activity.isCompleted && activity.activityTime.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMedium),
      elevation: isDark ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        side: BorderSide(
          color: isOverdue
              ? AppColors.error.withValues(alpha: 0.3)
              : activity.isCompleted
              ? AppColors.success.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingMedium),
          child: Row(
            children: [
              // Checkbox
              GestureDetector(
                onTap: onToggleComplete,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: activity.isCompleted
                          ? AppColors.success
                          : AppColors.textTertiary,
                      width: 2,
                    ),
                    color: activity.isCompleted
                        ? AppColors.success
                        : Colors.transparent,
                  ),
                  child: activity.isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: activity.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: activity.isCompleted
                            ? AppColors.textSecondary
                            : null,
                      ),
                    ),
                    if (activity.description != null &&
                        activity.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        activity.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          decoration: activity.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: isOverdue
                              ? AppColors.error
                              : AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateTime(activity.activityTime),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isOverdue
                                    ? AppColors.error
                                    : AppColors.textSecondary,
                              ),
                        ),
                        if (isOverdue) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'TERLAMBAT',
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Delete button
              IconButton(
                onPressed: onDelete,
                icon: Icon(Icons.delete_outline, color: AppColors.error),
                tooltip: 'Hapus',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final activityDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final timeFormat = DateFormat('HH:mm');

    if (activityDate == today) {
      return 'Hari ini, ${timeFormat.format(dateTime)}';
    } else if (activityDate == tomorrow) {
      return 'Besok, ${timeFormat.format(dateTime)}';
    } else {
      return DateFormat('d MMM yyyy, HH:mm').format(dateTime);
    }
  }
}

enum ActivityFilter { upcoming, completed, all }
