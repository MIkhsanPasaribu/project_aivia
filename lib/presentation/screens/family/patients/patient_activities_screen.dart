import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_aivia/core/constants/app_colors.dart';
import 'package:project_aivia/core/constants/app_dimensions.dart';
import 'package:project_aivia/core/utils/date_formatter.dart';
import 'package:project_aivia/data/models/activity.dart';
import 'package:project_aivia/data/models/user_profile.dart';
import 'package:project_aivia/presentation/providers/activity_provider.dart';
import 'package:project_aivia/presentation/widgets/common/shimmer_loading.dart';
import 'package:project_aivia/presentation/widgets/common/empty_state_widget.dart';

/// Patient Activities Screen - Family view untuk melihat aktivitas pasien
///
/// Features:
/// - List aktivitas filtered by patientId
/// - Date range filter
/// - Status filter (completed/pending)
/// - Pull-to-refresh
/// - Empty state handling
class PatientActivitiesScreen extends ConsumerStatefulWidget {
  const PatientActivitiesScreen({required this.patient, super.key});

  final UserProfile patient;

  @override
  ConsumerState<PatientActivitiesScreen> createState() =>
      _PatientActivitiesScreenState();
}

class _PatientActivitiesScreenState
    extends ConsumerState<PatientActivitiesScreen> {
  // Filter state
  ActivityFilter _currentFilter = ActivityFilter.all;
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    // Watch activities stream untuk realtime updates
    final activitiesAsync = ref.watch(
      activitiesStreamProvider(widget.patient.id),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Aktivitas ${widget.patient.fullName}'),
        actions: [
          // Filter button
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () => _showFilterBottomSheet(context),
            tooltip: 'Filter Aktivitas',
          ),
          // Date range picker button
          IconButton(
            icon: Icon(
              Icons.date_range,
              color: Theme.of(context).iconTheme.color,
            ),
            onPressed: () => _selectDateRange(context),
            tooltip: 'Pilih Rentang Tanggal',
          ),
        ],
      ),
      body: activitiesAsync.when(
        data: (activities) {
          // Apply filters
          final filteredActivities = _applyFilters(activities);

          if (filteredActivities.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(activitiesStreamProvider(widget.patient.id));
              },
              child: EmptyStateWidget(
                icon: Icons.event_note,
                title: 'Belum Ada Aktivitas',
                description: _getEmptyMessage(),
                actionButtonText:
                    _dateRange != null || _currentFilter != ActivityFilter.all
                    ? 'Hapus Filter'
                    : null,
                onActionButtonTap:
                    _dateRange != null || _currentFilter != ActivityFilter.all
                    ? _clearFilters
                    : null,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(activitiesStreamProvider(widget.patient.id));
            },
            child: Column(
              children: [
                // Filter info chip (if any filter active)
                if (_dateRange != null || _currentFilter != ActivityFilter.all)
                  _buildFilterInfoChip(),

                // Activity list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppDimensions.paddingM),
                    itemCount: filteredActivities.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppDimensions.paddingS),
                    itemBuilder: (context, index) {
                      final activity = filteredActivities[index];
                      return _ActivityCard(activity: activity);
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          itemCount: 5,
          itemBuilder: (context, index) => const Padding(
            padding: EdgeInsets.only(bottom: AppDimensions.paddingS),
            child: ActivityCardSkeleton(),
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: AppDimensions.paddingM),
              Text(
                'Gagal memuat aktivitas',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppDimensions.paddingS),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDimensions.paddingM),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(activitiesStreamProvider(widget.patient.id));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Apply selected filters to activities list
  List<Activity> _applyFilters(List<Activity> activities) {
    var filtered = activities;

    // Filter by status
    switch (_currentFilter) {
      case ActivityFilter.completed:
        filtered = filtered.where((a) => a.isCompleted).toList();
        break;
      case ActivityFilter.pending:
        filtered = filtered.where((a) => !a.isCompleted).toList();
        break;
      case ActivityFilter.today:
        final today = DateTime.now();
        filtered = filtered.where((a) {
          final activityDate = a.activityTime;
          return activityDate.year == today.year &&
              activityDate.month == today.month &&
              activityDate.day == today.day;
        }).toList();
        break;
      case ActivityFilter.all:
        // No filter
        break;
    }

    // Filter by date range
    if (_dateRange != null) {
      filtered = filtered.where((a) {
        final activityDate = a.activityTime;
        return activityDate.isAfter(
              _dateRange!.start.subtract(const Duration(days: 1)),
            ) &&
            activityDate.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Sort by activity time (newest first)
    filtered.sort((a, b) => b.activityTime.compareTo(a.activityTime));

    return filtered;
  }

  /// Show filter bottom sheet
  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Aktivitas',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.paddingM),

              // Filter options
              _buildFilterOption(
                context,
                'Semua',
                ActivityFilter.all,
                Icons.view_list,
                setModalState,
              ),
              _buildFilterOption(
                context,
                'Hari Ini',
                ActivityFilter.today,
                Icons.today,
                setModalState,
              ),
              _buildFilterOption(
                context,
                'Selesai',
                ActivityFilter.completed,
                Icons.check_circle,
                setModalState,
              ),
              _buildFilterOption(
                context,
                'Belum Selesai',
                ActivityFilter.pending,
                Icons.pending,
                setModalState,
              ),

              const SizedBox(height: AppDimensions.paddingM),

              // Apply button
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Terapkan Filter'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build single filter option
  Widget _buildFilterOption(
    BuildContext context,
    String label,
    ActivityFilter filter,
    IconData icon,
    StateSetter setModalState,
  ) {
    final isSelected = _currentFilter == filter;

    return InkWell(
      onTap: () {
        setState(() {
          _currentFilter = filter;
        });
        setModalState(() {});
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingM,
          vertical: AppDimensions.paddingS,
        ),
        margin: const EdgeInsets.only(bottom: AppDimensions.paddingS),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).iconTheme.color,
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
                fontWeight: isSelected ? FontWeight.w600 : null,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }

  /// Select date range
  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(data: Theme.of(context), child: child!);
      },
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  /// Clear all filters
  void _clearFilters() {
    setState(() {
      _currentFilter = ActivityFilter.all;
      _dateRange = null;
    });
  }

  /// Build filter info chip
  Widget _buildFilterInfoChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      margin: const EdgeInsets.fromLTRB(
        AppDimensions.paddingM,
        AppDimensions.paddingS,
        AppDimensions.paddingM,
        0,
      ),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_alt,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppDimensions.paddingS),
          Expanded(
            child: Text(
              _getFilterInfoText(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          IconButton(
            onPressed: _clearFilters,
            icon: const Icon(Icons.close, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Hapus Filter',
          ),
        ],
      ),
    );
  }

  /// Get filter info text
  String _getFilterInfoText() {
    final parts = <String>[];

    // Filter type
    switch (_currentFilter) {
      case ActivityFilter.completed:
        parts.add('Selesai');
        break;
      case ActivityFilter.pending:
        parts.add('Belum Selesai');
        break;
      case ActivityFilter.today:
        parts.add('Hari Ini');
        break;
      case ActivityFilter.all:
        break;
    }

    // Date range
    if (_dateRange != null) {
      parts.add(
        '${DateFormatter.formatDate(_dateRange!.start)} - ${DateFormatter.formatDate(_dateRange!.end)}',
      );
    }

    return 'Filter: ${parts.join(', ')}';
  }

  /// Get empty message based on filters
  String _getEmptyMessage() {
    if (_dateRange != null || _currentFilter != ActivityFilter.all) {
      return 'Tidak ada aktivitas yang sesuai dengan filter yang dipilih.';
    }
    return 'Pasien belum memiliki aktivitas yang terjadwal.';
  }
}

/// Activity filter enum
enum ActivityFilter { all, today, completed, pending }

/// Activity card widget untuk list
class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = activity.isCompleted;
    final isPast = activity.activityTime.isBefore(DateTime.now());

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Show detail dialog
          _showActivityDetail(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  // Status icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.success.withValues(alpha: 0.1)
                          : isPast
                          ? AppColors.error.withValues(alpha: 0.1)
                          : AppColors.info.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.check_circle
                          : isPast
                          ? Icons.cancel
                          : Icons.pending,
                      color: isCompleted
                          ? AppColors.success
                          : isPast
                          ? AppColors.error
                          : AppColors.info,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.paddingM),

                  // Title
                  Expanded(
                    child: Text(
                      activity.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Description (if exists)
              if (activity.description != null &&
                  activity.description!.isNotEmpty) ...[
                const SizedBox(height: AppDimensions.paddingS),
                Text(
                  activity.description!,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: AppDimensions.paddingM),

              // Footer with time and completion info
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormatter.formatDateTime(activity.activityTime),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const Spacer(),
                  if (isCompleted && activity.completedAt != null) ...[
                    Icon(Icons.done, size: 16, color: AppColors.success),
                    const SizedBox(width: 4),
                    Text(
                      'Selesai ${DateFormatter.formatDateTime(activity.completedAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                      ),
                    ),
                  ] else if (isPast && !isCompleted) ...[
                    Icon(
                      Icons.warning_amber,
                      size: 16,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Terlewat',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActivityDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(activity.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (activity.description != null &&
                  activity.description!.isNotEmpty) ...[
                const Text(
                  'Deskripsi:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(activity.description!),
                const SizedBox(height: 16),
              ],
              const Text(
                'Waktu:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(DateFormatter.formatDateTime(activity.activityTime)),
              const SizedBox(height: 16),
              const Text(
                'Status:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(activity.isCompleted ? 'Selesai' : 'Belum Selesai'),
              if (activity.isCompleted && activity.completedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Diselesaikan pada ${DateFormatter.formatDateTime(activity.completedAt!)}',
                  style: TextStyle(color: AppColors.success, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
