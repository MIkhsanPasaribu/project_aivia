import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_aivia/core/constants/app_colors.dart';
import 'package:project_aivia/data/models/geofence.dart';
import 'package:project_aivia/presentation/providers/geofence_provider.dart';
import 'package:project_aivia/presentation/widgets/geofence/geofence_card.dart';
import 'package:project_aivia/presentation/widgets/common/loading_indicator.dart';
import 'package:project_aivia/presentation/widgets/common/empty_state_widget.dart';
import 'package:project_aivia/presentation/widgets/common/confirmation_dialog.dart';
import 'geofence_form_screen.dart';
import 'geofence_detail_screen.dart';

/// Screen untuk menampilkan daftar geofences (Zona Geografis)
///
/// Features:
/// - List semua geofences untuk pasien tertentu
/// - Filter by fence type (Safe, Danger, Home, etc)
/// - Search by name/description/address
/// - Pull-to-refresh
/// - Tambah geofence baru (FAB)
/// - Edit/Delete/Toggle status per geofence
/// - Empty state ketika belum ada geofence
class GeofenceListScreen extends ConsumerStatefulWidget {
  final String patientId;
  final String? patientName;

  const GeofenceListScreen({
    super.key,
    required this.patientId,
    this.patientName,
  });

  @override
  ConsumerState<GeofenceListScreen> createState() => _GeofenceListScreenState();
}

class _GeofenceListScreenState extends ConsumerState<GeofenceListScreen> {
  final TextEditingController _searchController = TextEditingController();
  FenceType? _selectedFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch geofences stream
    final geofencesAsync = ref.watch(geofencesStreamProvider(widget.patientId));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Zona Geografis'),
            if (widget.patientName != null)
              Text(
                widget.patientName!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
          ],
        ),
        actions: [
          // Active count badge
          geofencesAsync.when(
            data: (geofences) {
              final activeCount = geofences.where((g) => g.isActive).length;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$activeCount Aktif',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: geofencesAsync.when(
        data: (allGeofences) {
          // Apply filters locally
          var filteredGeofences = allGeofences;

          // Filter by type
          if (_selectedFilter != null) {
            filteredGeofences = filteredGeofences
                .where((g) => g.fenceType == _selectedFilter)
                .toList();
          }

          // Filter by search
          if (_searchController.text.isNotEmpty) {
            final query = _searchController.text.toLowerCase();
            filteredGeofences = filteredGeofences.where((g) {
              return g.name.toLowerCase().contains(query) ||
                  (g.description?.toLowerCase().contains(query) ?? false) ||
                  (g.address?.toLowerCase().contains(query) ?? false);
            }).toList();
          }

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari zona geografis...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),

              // Filter Chips
              SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // All filter
                    _FilterChip(
                      label: 'Semua',
                      count: allGeofences.length,
                      isSelected: _selectedFilter == null,
                      onTap: () {
                        setState(() => _selectedFilter = null);
                      },
                    ),
                    const SizedBox(width: 8),

                    // Safe
                    _FilterChip(
                      label: FenceType.safe.displayName,
                      count: allGeofences
                          .where((g) => g.fenceType == FenceType.safe)
                          .length,
                      isSelected: _selectedFilter == FenceType.safe,
                      color: AppColors.success,
                      icon: Icons.shield_outlined,
                      onTap: () {
                        setState(() => _selectedFilter = FenceType.safe);
                      },
                    ),
                    const SizedBox(width: 8),

                    // Danger
                    _FilterChip(
                      label: FenceType.danger.displayName,
                      count: allGeofences
                          .where((g) => g.fenceType == FenceType.danger)
                          .length,
                      isSelected: _selectedFilter == FenceType.danger,
                      color: AppColors.error,
                      icon: Icons.warning_amber_outlined,
                      onTap: () {
                        setState(() => _selectedFilter = FenceType.danger);
                      },
                    ),
                    const SizedBox(width: 8),

                    // Home
                    _FilterChip(
                      label: FenceType.home.displayName,
                      count: allGeofences
                          .where((g) => g.fenceType == FenceType.home)
                          .length,
                      isSelected: _selectedFilter == FenceType.home,
                      color: AppColors.primary,
                      icon: Icons.home_outlined,
                      onTap: () {
                        setState(() => _selectedFilter = FenceType.home);
                      },
                    ),
                    const SizedBox(width: 8),

                    // Hospital
                    _FilterChip(
                      label: FenceType.hospital.displayName,
                      count: allGeofences
                          .where((g) => g.fenceType == FenceType.hospital)
                          .length,
                      isSelected: _selectedFilter == FenceType.hospital,
                      color: AppColors.info,
                      icon: Icons.local_hospital_outlined,
                      onTap: () {
                        setState(() => _selectedFilter = FenceType.hospital);
                      },
                    ),
                    const SizedBox(width: 8),

                    // School
                    _FilterChip(
                      label: FenceType.school.displayName,
                      count: allGeofences
                          .where((g) => g.fenceType == FenceType.school)
                          .length,
                      isSelected: _selectedFilter == FenceType.school,
                      color: AppColors.warning,
                      icon: Icons.school_outlined,
                      onTap: () {
                        setState(() => _selectedFilter = FenceType.school);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // List
              Expanded(
                child: filteredGeofences.isEmpty
                    ? EmptyStateWidget(
                        icon:
                            _selectedFilter != null ||
                                _searchController.text.isNotEmpty
                            ? Icons.search_off
                            : Icons.location_off,
                        title:
                            _selectedFilter != null ||
                                _searchController.text.isNotEmpty
                            ? 'Tidak Ada Hasil'
                            : 'Belum Ada Zona Geografis',
                        description:
                            _selectedFilter != null ||
                                _searchController.text.isNotEmpty
                            ? 'Coba kata kunci atau filter yang berbeda'
                            : 'Tambahkan zona geografis untuk memantau lokasi pasien',
                        actionButtonText:
                            _selectedFilter == null &&
                                _searchController.text.isEmpty
                            ? 'Tambah Zona'
                            : null,
                        onActionButtonTap:
                            _selectedFilter == null &&
                                _searchController.text.isEmpty
                            ? () => _navigateToAddGeofence(context)
                            : null,
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(geofencesStreamProvider);
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: filteredGeofences.length,
                          itemBuilder: (context, index) {
                            final geofence = filteredGeofences[index];
                            return GeofenceCard(
                              geofence: geofence,
                              onTap: () =>
                                  _navigateToDetail(context, geofence.id),
                              onEdit: () =>
                                  _navigateToEdit(context, geofence.id),
                              onToggleStatus: () =>
                                  _handleToggleStatus(context, geofence),
                              onDelete: () => _handleDelete(context, geofence),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Terjadi Kesalahan',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(geofencesStreamProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddGeofence(context),
        icon: const Icon(Icons.add_location),
        label: const Text('Tambah Zona'),
      ),
    );
  }

  /// Navigate to add geofence screen
  void _navigateToAddGeofence(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GeofenceFormScreen(
          patientId: widget.patientId,
          patientName: widget.patientName ?? 'Pasien',
        ),
      ),
    );
  }

  /// Navigate to edit geofence screen
  void _navigateToEdit(BuildContext context, String geofenceId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GeofenceFormScreen(
          patientId: widget.patientId,
          patientName: widget.patientName ?? 'Pasien',
          geofenceId: geofenceId,
        ),
      ),
    );
  }

  /// Navigate to detail screen
  void _navigateToDetail(BuildContext context, String geofenceId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GeofenceDetailScreen(
          geofenceId: geofenceId,
          patientId: widget.patientId,
          patientName: widget.patientName ?? 'Pasien',
        ),
      ),
    );
  }

  /// Handle toggle status
  Future<void> _handleToggleStatus(
    BuildContext context,
    Geofence geofence,
  ) async {
    final repository = ref.read(geofenceRepositoryProvider);
    final result = await repository.toggleGeofenceStatus(geofence.id);

    if (!context.mounted) return;

    result.fold(
      onSuccess: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              geofence.isActive
                  ? 'Zona "${geofence.name}" dinonaktifkan'
                  : 'Zona "${geofence.name}" diaktifkan',
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

  /// Handle delete geofence
  Future<void> _handleDelete(BuildContext context, Geofence geofence) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Hapus Zona Geografis?',
        description:
            'Zona "${geofence.name}" akan dihapus secara permanen. Tindakan ini tidak dapat dibatalkan.',
        confirmText: 'Hapus',
        cancelText: 'Batal',
        isDestructive: true,
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final repository = ref.read(geofenceRepositoryProvider);
    final result = await repository.deleteGeofence(geofence.id);

    if (!context.mounted) return;

    result.fold(
      onSuccess: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Zona "${geofence.name}" berhasil dihapus'),
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
}

/// Filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color? color;
  final IconData? icon;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    this.color,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: isSelected ? Colors.white : chipColor),
            const SizedBox(width: 4),
          ],
          Text(label),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.3)
                  : chipColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : chipColor,
              ),
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: chipColor,
      backgroundColor: chipColor.withValues(alpha: 0.1),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : chipColor,
        fontWeight: FontWeight.w600,
      ),
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? chipColor : chipColor.withValues(alpha: 0.3),
        width: 1,
      ),
    );
  }
}
