/// Geofence Detail Screen (Family View)
///
/// Layar detail geofence dengan map dan timeline event history
///
/// Features:
/// - Top: Map dengan geofence circle dan patient location
/// - Bottom: Timeline event (enter/exit history)
/// - Actions: Edit, Delete, Toggle active
/// - Real-time updates dari stream
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/map_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../data/models/geofence.dart';
import '../../../../data/models/geofence_event.dart';
import '../../../providers/geofence_provider.dart';
import '../../../widgets/common/confirmation_dialog.dart';
import '../../../widgets/common/loading_indicator.dart';
import 'geofence_form_screen.dart';

/// Geofence Detail Screen
class GeofenceDetailScreen extends ConsumerStatefulWidget {
  const GeofenceDetailScreen({
    required this.geofenceId,
    required this.patientId,
    required this.patientName,
    super.key,
  });

  final String geofenceId;
  final String patientId;
  final String patientName;

  @override
  ConsumerState<GeofenceDetailScreen> createState() =>
      _GeofenceDetailScreenState();
}

class _GeofenceDetailScreenState extends ConsumerState<GeofenceDetailScreen> {
  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch geofence data
    final geofenceAsync = ref.watch(geofenceByIdProvider(widget.geofenceId));

    // Watch events stream
    final eventsAsync = ref.watch(
      geofenceEventsStreamProvider(widget.geofenceId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Zona'),
        actions: [
          geofenceAsync.when(
            data: (geofence) => PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _navigateToEdit(context, geofence);
                    break;
                  case 'toggle':
                    _handleToggleStatus(geofence);
                    break;
                  case 'delete':
                    _handleDelete(geofence);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        geofence.isActive
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      const SizedBox(width: 8),
                      Text(geofence.isActive ? 'Nonaktifkan' : 'Aktifkan'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Hapus', style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: geofenceAsync.when(
        data: (geofence) => Column(
          children: [
            // Top: Map section (40% height)
            Expanded(flex: 4, child: _buildMapSection(geofence)),

            // Bottom: Event timeline (60% height)
            Expanded(flex: 6, child: _buildEventTimeline(eventsAsync)),
          ],
        ),
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Gagal memuat data',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build map section dengan geofence circle
  Widget _buildMapSection(Geofence geofence) {
    final centerPoint = LatLng(geofence.latitude, geofence.longitude);

    // Center map saat pertama kali
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(centerPoint, MapConfig.focusZoom);
    });

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: centerPoint,
            initialZoom: MapConfig.focusZoom,
            minZoom: MapConfig.minZoom,
            maxZoom: MapConfig.maxZoom,
          ),
          children: [
            // OSM Tile Layer
            TileLayer(
              urlTemplate: MapConfig.osmTileUrl,
              userAgentPackageName: MapConfig.userAgent,
              maxNativeZoom: MapConfig.maxZoom.toInt(),
            ),

            // Geofence Circle
            CircleLayer(
              circles: [
                CircleMarker(
                  point: centerPoint,
                  radius: geofence.radiusMeters
                      .toDouble(), // Safe: radiusMeters is non-null
                  useRadiusInMeter: true,
                  color: _getCircleColor(geofence).withValues(alpha: 0.2),
                  borderColor: _getCircleColor(geofence),
                  borderStrokeWidth: 2,
                ),
              ],
            ),

            // Center marker
            MarkerLayer(
              markers: [
                Marker(
                  point: centerPoint,
                  child: Icon(
                    _getIconForType(geofence.fenceType),
                    color: _getCircleColor(geofence),
                    size: 32,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Info overlay
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getCircleColor(
                            geofence,
                          ).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getIconForType(geofence.fenceType),
                          color: _getCircleColor(geofence),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              geofence.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${geofence.fenceType.displayName} • ${geofence.radiusMeters.toInt()}m',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: geofence.isActive
                              ? AppColors.success
                              : AppColors.disabled,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              geofence.isActive
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              geofence.isActive ? 'Aktif' : 'Nonaktif',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (geofence.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      geofence.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_active_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        geofence.alertOnEnter && geofence.alertOnExit
                            ? 'Alert: Masuk & Keluar'
                            : geofence.alertOnEnter
                            ? 'Alert: Masuk Zona'
                            : 'Alert: Keluar Zona',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.star, size: 16, color: AppColors.warning),
                      const SizedBox(width: 4),
                      Text(
                        'Prioritas: ${geofence.priority}/10',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build event timeline section
  Widget _buildEventTimeline(AsyncValue<List<GeofenceEvent>> eventsAsync) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingM),
            child: Row(
              children: [
                const Icon(Icons.history, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Riwayat Event',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                eventsAsync.when(
                  data: (events) => Text(
                    '${events.length} event',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: eventsAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_note_outlined,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum Ada Event',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Event akan muncul ketika pasien\nmasuk atau keluar zona ini',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  itemCount: events.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return _buildEventCard(event);
                  },
                );
              },
              loading: () => const Center(child: LoadingIndicator()),
              error: (error, _) => Center(
                child: Text(
                  'Gagal memuat riwayat: $error',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build single event card
  Widget _buildEventCard(GeofenceEvent event) {
    final isEnter = event.eventType == GeofenceEventType.enter;
    final color = isEnter ? AppColors.success : AppColors.warning;
    final icon = isEnter ? Icons.login : Icons.logout;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEnter ? 'Masuk Zona' : 'Keluar Zona',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormatter.formatDateTime(event.detectedAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (event.distanceFromCenter != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Jarak: ${event.distanceFromCenter!.toStringAsFixed(0)}m dari pusat',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Notification status
            if (event.notified)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 14,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Notified',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule, size: 14, color: AppColors.warning),
                    SizedBox(width: 4),
                    Text(
                      'Pending',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Navigate to edit screen
  void _navigateToEdit(BuildContext context, Geofence geofence) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GeofenceFormScreen(
          patientId: widget.patientId,
          patientName: widget.patientName,
          geofenceId: geofence.id,
        ),
      ),
    );
  }

  /// Handle toggle status
  Future<void> _handleToggleStatus(Geofence geofence) async {
    final repo = ref.read(geofenceRepositoryProvider);
    final result = await repo.toggleGeofenceStatus(geofence.id);

    if (!mounted) return;

    result.fold(
      onSuccess: (_) {
        ref.invalidate(geofenceByIdProvider(widget.geofenceId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              geofence.isActive ? 'Zona dinonaktifkan' : 'Zona diaktifkan',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      },
      onFailure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${failure.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );
  }

  /// Handle delete
  Future<void> _handleDelete(Geofence geofence) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Hapus Zona?',
        description:
            'Apakah Anda yakin ingin menghapus zona "${geofence.name}"? '
            'Tindakan ini tidak dapat dibatalkan.',
        confirmText: 'Hapus',
        isDestructive: true,
      ),
    );

    if (confirmed != true || !mounted) return;

    final repo = ref.read(geofenceRepositoryProvider);
    final result = await repo.deleteGeofence(geofence.id);

    if (!mounted) return;

    result.fold(
      onSuccess: (_) {
        Navigator.pop(context); // Back to list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Zona berhasil dihapus'),
            backgroundColor: AppColors.success,
          ),
        );
      },
      onFailure: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: ${failure.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      },
    );
  }

  /// Get circle color berdasarkan fence type
  Color _getCircleColor(Geofence geofence) {
    switch (geofence.fenceType) {
      case FenceType.safe:
      case FenceType.home:
      case FenceType.hospital:
      case FenceType.school:
        return AppColors.success;
      case FenceType.danger:
        return AppColors.error;
      case FenceType.custom:
        return AppColors.info;
    }
  }

  /// Get icon berdasarkan fence type
  IconData _getIconForType(FenceType type) {
    switch (type) {
      case FenceType.home:
        return Icons.home;
      case FenceType.hospital:
        return Icons.local_hospital;
      case FenceType.school:
        return Icons.school;
      case FenceType.safe:
        return Icons.shield;
      case FenceType.danger:
        return Icons.warning;
      case FenceType.custom:
        return Icons.place;
    }
  }
}
