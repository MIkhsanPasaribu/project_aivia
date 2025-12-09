/// Geofence Form Screen (Family View)
///
/// Form untuk menambah/edit geofence dengan map picker interaktif
///
/// Features:
/// - Mode: Create baru atau Edit existing
/// - Interactive map untuk pilih center point
/// - Form fields: Nama, tipe, radius, alerts, deskripsi
/// - Validasi lengkap
/// - Preview geofence circle di map
/// - Real-time radius adjustment
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/map_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../data/models/geofence.dart';
import '../../../providers/geofence_provider.dart';
import '../../../widgets/common/custom_button.dart';
import '../../../widgets/common/loading_indicator.dart';

/// Geofence Form Screen untuk Create atau Edit
class GeofenceFormScreen extends ConsumerStatefulWidget {
  const GeofenceFormScreen({
    required this.patientId,
    required this.patientName,
    this.geofenceId,
    super.key,
  });

  /// ID pasien
  final String patientId;

  /// Nama pasien untuk display
  final String patientName;

  /// ID geofence (null jika mode create)
  final String? geofenceId;

  @override
  ConsumerState<GeofenceFormScreen> createState() => _GeofenceFormScreenState();
}

class _GeofenceFormScreenState extends ConsumerState<GeofenceFormScreen> {
  // ==================== STATE ====================

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  late MapController _mapController;

  // Form fields
  FenceType _selectedType = FenceType.safe;
  double _radiusMeters = 500.0; // Default 500m
  bool _alertOnEnter = true;
  bool _alertOnExit = true;
  int _priority = 5;

  // Map state
  LatLng _centerPoint = MapConfig.defaultCenter;

  // Loading states
  bool _isLoading = false;
  bool _isLoadingGeofence = false;

  // Edit mode
  bool get isEditMode => widget.geofenceId != null;

  // ==================== LIFECYCLE ====================

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    if (isEditMode) {
      _loadExistingGeofence();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Load data geofence existing untuk edit mode
  Future<void> _loadExistingGeofence() async {
    setState(() => _isLoadingGeofence = true);

    final result = await ref
        .read(geofenceRepositoryProvider)
        .getGeofenceById(widget.geofenceId!);

    result.fold(
      onSuccess: (geofence) {
        setState(() {
          _nameController.text = geofence.name;
          _descriptionController.text = geofence.description ?? '';
          _addressController.text = geofence.address ?? '';
          _selectedType = geofence.fenceType;
          _radiusMeters = geofence.radiusMeters
              .toDouble(); // Safe: radiusMeters is non-null
          _alertOnEnter = geofence.alertOnEnter;
          _alertOnExit = geofence.alertOnExit;
          _priority = geofence.priority;
          _centerPoint = LatLng(geofence.latitude, geofence.longitude);
          _isLoadingGeofence = false;
        });

        // Center map ke lokasi geofence
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(_centerPoint, MapConfig.defaultZoom);
        });
      },
      onFailure: (failure) {
        setState(() => _isLoadingGeofence = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal memuat data: ${failure.message}'),
              backgroundColor: AppColors.error,
            ),
          );
          Navigator.pop(context);
        }
      },
    );
  }

  // ==================== SUBMIT ====================

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validasi alerts
    if (!_alertOnEnter && !_alertOnExit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal satu alert harus aktif (Masuk atau Keluar)'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(geofenceRepositoryProvider);

      if (isEditMode) {
        // Update existing geofence
        final result = await repository.updateGeofence(widget.geofenceId!, {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          'fence_type': _selectedType.toDbString(),
          'center_coordinates':
              'POINT(${_centerPoint.longitude} ${_centerPoint.latitude})',
          'radius_meters': _radiusMeters.toInt(),
          'alert_on_enter': _alertOnEnter,
          'alert_on_exit': _alertOnExit,
          'priority': _priority,
          'address': _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
        });

        result.fold(
          onSuccess: (_) {
            // Invalidate provider to refresh list
            ref.invalidate(geofencesStreamProvider(widget.patientId));

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Zona berhasil diperbarui'),
                  backgroundColor: AppColors.success,
                ),
              );
              Navigator.pop(context);
            }
          },
          onFailure: (failure) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal memperbarui: ${failure.message}'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
        );
      } else {
        // Create new geofence
        final result = await repository.createGeofence(
          patientId: widget.patientId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          fenceType: _selectedType,
          latitude: _centerPoint.latitude,
          longitude: _centerPoint.longitude,
          radiusMeters: _radiusMeters,
          alertOnEnter: _alertOnEnter,
          alertOnExit: _alertOnExit,
          priority: _priority,
          address: _addressController.text.trim().isEmpty
              ? null
              : _addressController.text.trim(),
        );

        result.fold(
          onSuccess: (_) {
            // Invalidate provider to refresh list
            ref.invalidate(geofencesStreamProvider(widget.patientId));

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Zona berhasil dibuat'),
                  backgroundColor: AppColors.success,
                ),
              );
              Navigator.pop(context);
            }
          },
          onFailure: (failure) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal membuat zona: ${failure.message}'),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ==================== BUILD ====================

  @override
  Widget build(BuildContext context) {
    if (_isLoadingGeofence) {
      return Scaffold(
        appBar: AppBar(title: const Text('Memuat Data...')),
        body: const LoadingIndicator(message: 'Memuat data geofence...'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Zona' : 'Tambah Zona Baru'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Map Section (Top Half)
            Expanded(flex: 4, child: _buildMapSection()),

            // Form Section (Bottom Half - Scrollable)
            Expanded(flex: 6, child: _buildFormSection()),
          ],
        ),
      ),
    );
  }

  /// Build map section dengan geofence preview
  Widget _buildMapSection() {
    return Stack(
      children: [
        // Flutter Map
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _centerPoint,
            initialZoom: MapConfig.defaultZoom,
            minZoom: MapConfig.minZoom,
            maxZoom: MapConfig.maxZoom,
            onTap: (tapPosition, point) {
              // Update center point when tapped
              setState(() {
                _centerPoint = point;
              });
            },
          ),
          children: [
            // OSM Tile Layer
            TileLayer(
              urlTemplate: MapConfig.osmTileUrl,
              userAgentPackageName: MapConfig.userAgent,
              maxNativeZoom: MapConfig.maxZoom.toInt(),
            ),

            // Geofence Circle Layer
            CircleLayer(
              circles: [
                CircleMarker(
                  point: _centerPoint,
                  radius: _radiusMeters,
                  useRadiusInMeter: true,
                  color: _getTypeColor().withValues(alpha: 0.15),
                  borderColor: _getTypeColor(),
                  borderStrokeWidth: 2,
                ),
              ],
            ),

            // Center Marker
            MarkerLayer(
              markers: [
                Marker(
                  point: _centerPoint,
                  width: 40,
                  height: 40,
                  child: Icon(_getTypeIcon(), size: 40, color: _getTypeColor()),
                ),
              ],
            ),
          ],
        ),

        // Map instruction overlay
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.touch_app, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ketuk peta untuk memilih lokasi zona',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Zoom controls
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            children: [
              // Zoom in
              FloatingActionButton.small(
                heroTag: 'zoom_in',
                onPressed: () {
                  final currentZoom = _mapController.camera.zoom;
                  _mapController.move(
                    _centerPoint,
                    (currentZoom + 1).clamp(
                      MapConfig.minZoom,
                      MapConfig.maxZoom,
                    ),
                  );
                },
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 8),
              // Zoom out
              FloatingActionButton.small(
                heroTag: 'zoom_out',
                onPressed: () {
                  final currentZoom = _mapController.camera.zoom;
                  _mapController.move(
                    _centerPoint,
                    (currentZoom - 1).clamp(
                      MapConfig.minZoom,
                      MapConfig.maxZoom,
                    ),
                  );
                },
                child: const Icon(Icons.remove),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build form section (scrollable)
  Widget _buildFormSection() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Informasi Zona',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Nama
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Zona *',
                hintText: 'Contoh: Rumah, Sekolah, Rumah Sakit',
                prefixIcon: Icon(Icons.label_outline),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama zona wajib diisi';
                }
                if (value.trim().length < 3) {
                  return 'Nama minimal 3 karakter';
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Tipe
            DropdownButtonFormField<FenceType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipe Zona *',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: FenceType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(_getIconForType(type), size: 20),
                      const SizedBox(width: 8),
                      Text(type.displayName),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Radius Slider
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Radius Zona',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${_radiusMeters.toInt()} meter',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getTypeColor(),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _radiusMeters,
                  min: 50,
                  max: 10000,
                  divisions: 199, // 50 steps
                  label: '${_radiusMeters.toInt()}m',
                  onChanged: (value) {
                    setState(() => _radiusMeters = value);
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('50m', style: Theme.of(context).textTheme.bodySmall),
                    Text('10km', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Alert Settings
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pengaturan Notifikasi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    value: _alertOnEnter,
                    onChanged: (value) {
                      setState(() => _alertOnEnter = value);
                    },
                    title: const Text('Alert Saat Masuk Zona'),
                    subtitle: const Text('Notifikasi saat pasien masuk zona'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    value: _alertOnExit,
                    onChanged: (value) {
                      setState(() => _alertOnExit = value);
                    },
                    title: const Text('Alert Saat Keluar Zona'),
                    subtitle: const Text('Notifikasi saat pasien keluar zona'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Priority
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Prioritas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(10, (index) {
                    final priority = index + 1;
                    final isSelected = _priority == priority;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _priority = priority);
                        },
                        child: Container(
                          height: 40,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.warning
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.warning
                                  : AppColors.divider,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$priority',
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '1 = Tertinggi',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '10 = Terendah',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Alamat (optional)
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Alamat (Opsional)',
                hintText: 'Jl. Example No. 123',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: AppDimensions.paddingM),

            // Deskripsi (optional)
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Deskripsi (Opsional)',
                hintText: 'Catatan tambahan tentang zona ini',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
            const SizedBox(height: AppDimensions.paddingL),

            // Submit Button
            CustomButton(
              onPressed: _isLoading ? null : _handleSubmit,
              text: isEditMode ? 'Simpan Perubahan' : 'Buat Zona',
              isLoading: _isLoading,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPERS ====================

  Color _getTypeColor() {
    switch (_selectedType) {
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

  IconData _getTypeIcon() {
    switch (_selectedType) {
      case FenceType.home:
        return Icons.home;
      case FenceType.hospital:
        return Icons.local_hospital;
      case FenceType.school:
        return Icons.school;
      case FenceType.danger:
        return Icons.warning;
      case FenceType.safe:
        return Icons.shield;
      case FenceType.custom:
        return Icons.location_on;
    }
  }

  IconData _getIconForType(FenceType type) {
    switch (type) {
      case FenceType.home:
        return Icons.home;
      case FenceType.hospital:
        return Icons.local_hospital;
      case FenceType.school:
        return Icons.school;
      case FenceType.danger:
        return Icons.warning;
      case FenceType.safe:
        return Icons.shield;
      case FenceType.custom:
        return Icons.location_on;
    }
  }
}
