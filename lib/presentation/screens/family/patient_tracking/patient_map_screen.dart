/// Patient Map Screen (Family View)
///
/// Menampilkan lokasi real-time pasien dalam peta interaktif.
///
/// Features:
/// - Real-time location tracking via Supabase Realtime
/// - Interactive map dengan OSM tiles
/// - Custom patient marker
/// - Map controls (center, zoom, refresh)
/// - Loading/error/empty states
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/map_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/location.dart' as app_location;
import '../../../providers/location_provider.dart';

class PatientMapScreen extends ConsumerStatefulWidget {
  const PatientMapScreen({required this.patientId, super.key});

  final String patientId;

  @override
  ConsumerState<PatientMapScreen> createState() => _PatientMapScreenState();
}

class _PatientMapScreenState extends ConsumerState<PatientMapScreen> {
  // Map controller untuk programmatic control
  late final MapController _mapController;

  // Track if map has been initially centered
  bool _hasInitiallyCenter = false;

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
    // Watch patient's latest location stream
    final locationStream = ref.watch(
      lastLocationStreamProvider(widget.patientId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi Pasien'),
        centerTitle: true,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh provider
              ref.invalidate(lastLocationStreamProvider(widget.patientId));
            },
            tooltip: 'Muat ulang lokasi',
          ),
        ],
      ),
      body: locationStream.when(
        // Loading state
        loading: () => _buildLoadingState(),

        // Error state
        error: (error, stack) => _buildErrorState(error),

        // Success state
        data: (location) {
          if (location == null) {
            // No location data yet
            return _buildEmptyState();
          }

          // Auto-center map on first load
          if (!_hasInitiallyCenter) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _centerOnLocation(location);
              _hasInitiallyCenter = true;
            });
          }

          return _buildMapView(location);
        },
      ),
    );
  }

  // ==================== BUILD METHODS ====================

  /// Build loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text('Memuat peta...', style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Gagal Memuat Lokasi',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Retry
                ref.invalidate(lastLocationStreamProvider(widget.patientId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state (no location data yet)
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'Tidak Ada Data Lokasi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Lokasi pasien belum tersedia.\n'
              'Pastikan aplikasi pasien telah mengaktifkan pelacakan lokasi.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                // Refresh
                ref.invalidate(lastLocationStreamProvider(widget.patientId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Muat Ulang'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build map view dengan location data
  Widget _buildMapView(app_location.Location location) {
    final center = LatLng(location.latitude, location.longitude);

    return Stack(
      children: [
        // Map widget
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: MapConfig.defaultZoom,
            minZoom: MapConfig.minZoom,
            maxZoom: MapConfig.maxZoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            // Tile layer (OpenStreetMap)
            TileLayer(
              urlTemplate: MapConfig.osmTileUrl,
              userAgentPackageName: MapConfig.userAgent,
              maxZoom: MapConfig.maxZoom,
              // TODO: Add caching in future optimization
            ),

            // Accuracy circle (if accuracy > threshold)
            if (location.accuracy != null &&
                location.accuracy! > MapConfig.accuracyThreshold)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: center,
                    radius: location.accuracy!.clamp(
                      0,
                      MapConfig.maxAccuracyRadius,
                    ),
                    useRadiusInMeter: true,
                    color: AppColors.warning.withValues(alpha: 0.2),
                    borderColor: AppColors.warning,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),

            // Patient marker
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: MapConfig.markerSize,
                  height: MapConfig.markerSize,
                  child: _buildPatientMarker(location),
                ),
              ],
            ),

            // Attribution (required by OSM)
            if (MapConfig.showAttribution)
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    MapConfig.osmAttribution,
                    onTap: () async {
                      // Open OpenStreetMap website for licensing compliance
                      final url = Uri.parse(
                        'https://www.openstreetmap.org/copyright',
                      );
                      if (await canLaunchUrl(url)) {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                  ),
                ],
              ),
          ],
        ),

        // Info card (top)
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: _buildInfoCard(location),
        ),

        // Map controls (bottom-right)
        Positioned(bottom: 24, right: 16, child: _buildMapControls(center)),
      ],
    );
  }

  /// Build patient marker widget
  Widget _buildPatientMarker(app_location.Location location) {
    return GestureDetector(
      onTap: () {
        _showPatientInfo(location);
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.person, color: Colors.white, size: 28),
      ),
    );
  }

  /// Build info card (patient location info)
  Widget _buildInfoCard(app_location.Location location) {
    final now = DateTime.now();
    final diff = now.difference(location.timestamp);
    final lastUpdate = _formatTimeDifference(diff);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Lokasi terakhir: $lastUpdate',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (location.accuracy != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.gps_fixed,
                    size: 16,
                    color: _getAccuracyColor(location.accuracy!),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Akurasi: ${location.accuracy!.round()} meter',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getAccuracyColor(location.accuracy!),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build map controls (zoom, center, refresh)
  Widget _buildMapControls(LatLng center) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Center on patient button
        FloatingActionButton(
          heroTag: 'center',
          mini: true,
          onPressed: () {
            _mapController.move(center, MapConfig.focusZoom);
          },
          tooltip: 'Pusatkan ke Pasien',
          child: const Icon(Icons.my_location),
        ),
        const SizedBox(height: 8),

        // Zoom in
        FloatingActionButton(
          heroTag: 'zoom_in',
          mini: true,
          onPressed: () {
            final currentZoom = _mapController.camera.zoom;
            _mapController.move(
              _mapController.camera.center,
              (currentZoom + 1).clamp(MapConfig.minZoom, MapConfig.maxZoom),
            );
          },
          tooltip: 'Perbesar',
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 8),

        // Zoom out
        FloatingActionButton(
          heroTag: 'zoom_out',
          mini: true,
          onPressed: () {
            final currentZoom = _mapController.camera.zoom;
            _mapController.move(
              _mapController.camera.center,
              (currentZoom - 1).clamp(MapConfig.minZoom, MapConfig.maxZoom),
            );
          },
          tooltip: 'Perkecil',
          child: const Icon(Icons.remove),
        ),
      ],
    );
  }

  // ==================== HELPER METHODS ====================

  /// Center map pada location
  void _centerOnLocation(app_location.Location location) {
    final center = LatLng(location.latitude, location.longitude);

    final zoom = location.accuracy != null
        ? MapConfig.calculateZoomForAccuracy(location.accuracy!)
        : MapConfig.focusZoom;

    _mapController.move(center, zoom);
  }

  /// Show patient info bottom sheet
  void _showPatientInfo(app_location.Location location) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informasi Lokasi',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.access_time,
                'Waktu',
                _formatDateTime(location.timestamp),
              ),
              if (location.accuracy != null)
                _buildInfoRow(
                  Icons.gps_fixed,
                  'Akurasi',
                  '${location.accuracy!.round()} meter',
                ),
              _buildInfoRow(
                Icons.location_on,
                'Koordinat',
                '${location.latitude.toStringAsFixed(6)}, '
                    '${location.longitude.toStringAsFixed(6)}',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO Phase 2.2: Create LocationHistoryScreen dengan:
                    // - List view lokasi dengan timeline
                    // - Date range filter
                    // - Export ke CSV
                    // - Distance traveled statistics
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Fitur "Riwayat Lokasi" akan segera hadir di Phase 2.2',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Lihat Riwayat Lokasi'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build info row untuk bottom sheet
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  /// Format time difference untuk display
  String _formatTimeDifference(Duration diff) {
    if (diff.inMinutes < 1) {
      return 'baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else {
      return '${diff.inDays} hari lalu';
    }
  }

  /// Format DateTime untuk display
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Get color based on accuracy value
  Color _getAccuracyColor(double accuracy) {
    if (accuracy <= 25) return AppColors.success;
    if (accuracy <= 50) return AppColors.warning;
    return AppColors.error;
  }
}
