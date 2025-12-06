import 'package:flutter/material.dart';
import 'package:project_aivia/data/models/geofence.dart';
import 'package:project_aivia/core/constants/app_colors.dart';
import 'package:project_aivia/core/utils/date_formatter.dart';

/// Widget kartu untuk menampilkan geofence di list
///
/// Features:
/// - Color-coded by fence type
/// - Icon per fence type
/// - Status badge (aktif/nonaktif)
/// - Alert indicators
/// - Priority visualization (bintang)
/// - Action buttons (edit, delete, toggle)
/// - Swipe-to-delete support (via Dismissible)
/// - Dark mode support
class GeofenceCard extends StatelessWidget {
  /// Geofence data yang akan ditampilkan
  final Geofence geofence;

  /// Callback ketika card di-tap
  final VoidCallback? onTap;

  /// Callback ketika tombol edit ditekan
  final VoidCallback? onEdit;

  /// Callback ketika tombol delete ditekan
  final VoidCallback? onDelete;

  /// Callback ketika toggle status
  final VoidCallback? onToggleStatus;

  /// Enable swipe-to-delete gesture
  final bool enableDismissible;

  const GeofenceCard({
    super.key,
    required this.geofence,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleStatus,
    this.enableDismissible = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    Widget cardContent = Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Icon, Nama, Status Badge
              Row(
                children: [
                  // Icon dengan background color
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _getFenceTypeColor(
                        isDarkMode,
                      ).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getFenceTypeIcon(),
                      color: _getFenceTypeColor(isDarkMode),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nama geofence
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          geofence.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${geofence.fenceType.displayName} • ${geofence.radiusMeters.toInt()}m',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
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
                          geofence.isActive ? Icons.check_circle : Icons.cancel,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          geofence.isActive ? 'Aktif' : 'Nonaktif',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description (jika ada)
              if (geofence.description != null) ...[
                Text(
                  geofence.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],

              // Alert & Priority Info
              Row(
                children: [
                  // Alert indicators
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_active_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          geofence.alertOnEnter && geofence.alertOnExit
                              ? 'Masuk & Keluar'
                              : geofence.alertOnEnter
                              ? 'Masuk Zona'
                              : 'Keluar Zona',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Priority stars
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 16, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          '${geofence.priority}/10',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Footer: Created date & Actions
              Row(
                children: [
                  // Created date
                  Expanded(
                    child: Text(
                      'Dibuat ${DateFormatter.formatDate(geofence.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  // Action buttons
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: onEdit,
                      tooltip: 'Edit',
                      color: AppColors.primary,
                    ),
                  if (onToggleStatus != null)
                    IconButton(
                      icon: Icon(
                        geofence.isActive
                            ? Icons.visibility_off
                            : Icons.visibility,
                        size: 20,
                      ),
                      onPressed: onToggleStatus,
                      tooltip: geofence.isActive ? 'Nonaktifkan' : 'Aktifkan',
                      color: AppColors.textSecondary,
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: onDelete,
                      tooltip: 'Hapus',
                      color: AppColors.error,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    // Wrap dengan Dismissible jika enabled
    if (enableDismissible && onDelete != null) {
      return Dismissible(
        key: Key(geofence.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          // Show confirmation dialog
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Hapus Zona?'),
              content: Text(
                'Apakah Anda yakin ingin menghapus zona "${geofence.name}"? Tindakan ini tidak dapat dibatalkan.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Hapus'),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) => onDelete?.call(),
        background: Container(
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete_forever, color: Colors.white, size: 32),
              SizedBox(height: 4),
              Text(
                'Hapus',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        child: cardContent,
      );
    }

    return cardContent;
  }

  /// Get color berdasarkan fence type
  Color _getFenceTypeColor(bool isDarkMode) {
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
  IconData _getFenceTypeIcon() {
    switch (geofence.fenceType) {
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
        return Icons.location_on;
    }
  }
}
