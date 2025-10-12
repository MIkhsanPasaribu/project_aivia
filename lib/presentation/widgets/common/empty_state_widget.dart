import 'package:flutter/material.dart';
import 'package:project_aivia/core/constants/app_colors.dart';
import 'package:project_aivia/core/constants/app_dimensions.dart';

/// Custom empty state widget untuk menampilkan state kosong dengan CTA
///
/// Features:
/// - Custom icon
/// - Title dan description
/// - Call-to-action button (optional)
/// - Multiple preset variants
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionButtonText;
  final VoidCallback? onActionButtonTap;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionButtonText,
    this.onActionButtonTap,
  });

  /// Factory untuk empty activities
  factory EmptyStateWidget.activities({VoidCallback? onAdd}) {
    return EmptyStateWidget(
      icon: Icons.event_note,
      title: 'Belum Ada Aktivitas',
      description:
          'Tambahkan aktivitas pertama untuk memulai jurnal harian Anda.',
      actionButtonText: onAdd != null ? 'Tambah Aktivitas' : null,
      onActionButtonTap: onAdd,
    );
  }

  /// Factory untuk empty patients
  factory EmptyStateWidget.patients({VoidCallback? onAdd}) {
    return EmptyStateWidget(
      icon: Icons.person_add_outlined,
      title: 'Belum Ada Pasien',
      description:
          'Hubungkan dengan pasien untuk mulai memantau aktivitas mereka.',
      actionButtonText: onAdd != null ? 'Hubungkan Pasien' : null,
      onActionButtonTap: onAdd,
    );
  }

  /// Factory untuk empty known persons
  factory EmptyStateWidget.knownPersons({VoidCallback? onAdd}) {
    return EmptyStateWidget(
      icon: Icons.face,
      title: 'Belum Ada Orang Dikenal',
      description:
          'Tambahkan foto orang-orang terdekat untuk membantu pengenalan wajah.',
      actionButtonText: onAdd != null ? 'Tambah Orang Dikenal' : null,
      onActionButtonTap: onAdd,
    );
  }

  /// Factory untuk empty notifications
  factory EmptyStateWidget.notifications() {
    return const EmptyStateWidget(
      icon: Icons.notifications_none,
      title: 'Belum Ada Notifikasi',
      description: 'Notifikasi Anda akan muncul di sini.',
    );
  }

  /// Factory untuk search not found
  factory EmptyStateWidget.searchNotFound({required String query}) {
    return EmptyStateWidget(
      icon: Icons.search_off,
      title: 'Tidak Ditemukan',
      description: 'Tidak ada hasil untuk "$query". Coba kata kunci lain.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.paddingXL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(AppDimensions.paddingL),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: AppDimensions.iconXXL,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: AppDimensions.paddingL),
            Text(
              title,
              style: const TextStyle(
                fontSize: AppDimensions.fontXL,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppDimensions.paddingS),
            Text(
              description,
              style: const TextStyle(
                fontSize: AppDimensions.fontM,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionButtonText != null && onActionButtonTap != null) ...[
              SizedBox(height: AppDimensions.paddingL),
              ElevatedButton.icon(
                onPressed: onActionButtonTap,
                icon: const Icon(Icons.add),
                label: Text(actionButtonText!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingL,
                    vertical: AppDimensions.paddingM,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
