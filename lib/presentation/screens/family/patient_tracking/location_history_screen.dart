import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_aivia/core/constants/app_colors.dart';
import 'package:project_aivia/core/constants/app_dimensions.dart';
import 'package:project_aivia/core/utils/date_formatter.dart';
import 'package:project_aivia/data/models/location.dart';
import 'package:project_aivia/data/models/user_profile.dart';
import 'package:project_aivia/presentation/providers/location_provider.dart';
import 'package:project_aivia/presentation/widgets/common/empty_state_widget.dart';
import 'dart:math' as math;

/// Calculate distance between two coordinates using Haversine formula
/// Returns distance in meters
double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371000; // meters

  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);

  final lat1Rad = _toRadians(lat1);
  final lat2Rad = _toRadians(lat2);

  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1Rad) *
          math.cos(lat2Rad) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);

  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

  return earthRadius * c;
}

/// Convert degrees to radians
double _toRadians(double degrees) {
  return degrees * math.pi / 180.0;
}

/// Location History Screen - Timeline view historical locations patient
///
/// Features:
/// - Timeline UI dengan chronological sorting
/// - Date range filter
/// - Distance calculation between points
/// - Accuracy indicator
/// - Map preview per location (future)
/// - Export to CSV (optional, future)
class LocationHistoryScreen extends ConsumerStatefulWidget {
  const LocationHistoryScreen({required this.patient, super.key});

  final UserProfile patient;

  @override
  ConsumerState<LocationHistoryScreen> createState() =>
      _LocationHistoryScreenState();
}

class _LocationHistoryScreenState extends ConsumerState<LocationHistoryScreen> {
  // Date range state
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    // Watch location history dengan date filter
    final locationsAsync = ref.watch(
      locationHistoryProvider((
        patientId: widget.patient.id,
        startTime: _dateRange.start,
        endTime: _dateRange.end,
        limit: 100,
      )),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Riwayat Lokasi ${widget.patient.fullName}'),
        actions: [
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
      body: Column(
        children: [
          // Date range info chip
          _buildDateRangeChip(),

          // Location history list
          Expanded(
            child: locationsAsync.when(
              data: (locations) {
                if (locations.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.location_off,
                    title: 'Tidak Ada Riwayat Lokasi',
                    description:
                        'Tidak ada data lokasi pada rentang tanggal yang dipilih.',
                    actionButtonText: 'Ubah Rentang Tanggal',
                    onActionButtonTap: () => _selectDateRange(context),
                  );
                }

                // Calculate statistics
                final stats = _calculateStats(locations);

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(
                      locationHistoryProvider((
                        patientId: widget.patient.id,
                        startTime: _dateRange.start,
                        endTime: _dateRange.end,
                        limit: 100,
                      )),
                    );
                  },
                  child: Column(
                    children: [
                      // Statistics card
                      _buildStatsCard(stats),

                      // Timeline list
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppDimensions.paddingM),
                          itemCount: locations.length,
                          itemBuilder: (context, index) {
                            final location = locations[index];
                            final previousLocation =
                                index < locations.length - 1
                                ? locations[index + 1]
                                : null;

                            return _LocationTimelineItem(
                              location: location,
                              previousLocation: previousLocation,
                              isFirst: index == 0,
                              isLast: index == locations.length - 1,
                            );
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
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppDimensions.paddingM,
                  ),
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
                      'Gagal memuat riwayat lokasi',
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
                        ref.invalidate(
                          locationHistoryProvider((
                            patientId: widget.patient.id,
                            startTime: _dateRange.start,
                            endTime: _dateRange.end,
                            limit: 100,
                          )),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build date range info chip
  Widget _buildDateRangeChip() {
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
            Icons.calendar_today,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppDimensions.paddingS),
          Expanded(
            child: Text(
              '${DateFormatter.formatDate(_dateRange.start)} - ${DateFormatter.formatDate(_dateRange.end)}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            onPressed: () => _selectDateRange(context),
            icon: const Icon(Icons.edit, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Ubah Rentang',
          ),
        ],
      ),
    );
  }

  /// Build statistics card
  Widget _buildStatsCard(Map<String, dynamic> stats) {
    return Container(
      margin: const EdgeInsets.all(AppDimensions.paddingM),
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistik',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppDimensions.paddingM),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.location_on,
                  label: 'Total Lokasi',
                  value: '${stats['totalLocations']}',
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.straighten,
                  label: 'Jarak Tempuh',
                  value: '${stats['totalDistance']} km',
                  color: AppColors.secondary,
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.gps_fixed,
                  label: 'Akurasi Rata-rata',
                  value: '${stats['avgAccuracy']} m',
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Calculate statistics from locations
  Map<String, dynamic> _calculateStats(List<Location> locations) {
    if (locations.isEmpty) {
      return {'totalLocations': 0, 'totalDistance': '0.0', 'avgAccuracy': '0'};
    }

    double totalDistance = 0.0;
    double totalAccuracy = 0.0;

    for (int i = 0; i < locations.length - 1; i++) {
      final current = locations[i];
      final next = locations[i + 1];

      totalDistance += _calculateDistance(
        current.latitude,
        current.longitude,
        next.latitude,
        next.longitude,
      );

      if (current.accuracy != null) {
        totalAccuracy += current.accuracy!;
      }
    }

    // Add last location accuracy
    if (locations.last.accuracy != null) {
      totalAccuracy += locations.last.accuracy!;
    }

    final avgAccuracy = totalAccuracy / locations.length;

    return {
      'totalLocations': locations.length,
      'totalDistance': (totalDistance / 1000).toStringAsFixed(
        2,
      ), // Convert to km
      'avgAccuracy': avgAccuracy.toStringAsFixed(0),
    };
  }

  /// Select date range
  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
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
}

/// Stat item widget
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: AppDimensions.paddingS),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Location timeline item widget
class _LocationTimelineItem extends StatelessWidget {
  const _LocationTimelineItem({
    required this.location,
    required this.previousLocation,
    required this.isFirst,
    required this.isLast,
  });

  final Location location;
  final Location? previousLocation;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate distance from previous location
    final distance = previousLocation != null
        ? _calculateDistance(
            location.latitude,
            location.longitude,
            previousLocation!.latitude,
            previousLocation!.longitude,
          )
        : 0.0;

    // Determine accuracy color
    final accuracyColor = _getAccuracyColor(location.accuracy);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator
          Column(
            children: [
              // Top line
              if (!isFirst)
                Container(width: 2, height: 20, color: theme.dividerColor),

              // Dot
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isFirst ? AppColors.primary : accuracyColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
              ),

              // Bottom line
              if (!isLast)
                Container(width: 2, height: 100, color: theme.dividerColor),
            ],
          ),

          const SizedBox(width: AppDimensions.paddingM),

          // Location card
          Expanded(
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormatter.formatDateTime(location.timestamp),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (isFirst)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Terbaru',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.paddingS),

                    // Coordinates
                    Row(
                      children: [
                        Icon(
                          Icons.place,
                          size: 16,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.paddingS),

                    // Accuracy & Distance
                    Row(
                      children: [
                        // Accuracy
                        if (location.accuracy != null) ...[
                          Icon(Icons.gps_fixed, size: 14, color: accuracyColor),
                          const SizedBox(width: 4),
                          Text(
                            '±${location.accuracy!.toStringAsFixed(0)}m',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: accuracyColor,
                            ),
                          ),
                        ],

                        // Distance from previous
                        if (previousLocation != null && distance > 0) ...[
                          const SizedBox(width: AppDimensions.paddingM),
                          Icon(
                            Icons.straighten,
                            size: 14,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            distance < 1000
                                ? '${distance.toStringAsFixed(0)}m dari sebelumnya'
                                : '${(distance / 1000).toStringAsFixed(2)}km dari sebelumnya',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get accuracy color based on accuracy value
  Color _getAccuracyColor(double? accuracy) {
    if (accuracy == null) return AppColors.textSecondary;

    if (accuracy <= 20) {
      return AppColors.success; // Excellent
    } else if (accuracy <= 50) {
      return AppColors.info; // Good
    } else if (accuracy <= 100) {
      return AppColors.warning; // Fair
    } else {
      return AppColors.error; // Poor
    }
  }
}
