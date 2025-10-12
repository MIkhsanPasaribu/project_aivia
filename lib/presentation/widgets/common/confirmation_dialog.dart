import 'package:flutter/material.dart';
import 'package:project_aivia/core/constants/app_colors.dart';
import 'package:project_aivia/core/constants/app_dimensions.dart';

/// Custom confirmation dialog untuk aksi penting yang memerlukan konfirmasi
///
/// Features:
/// - Title dan description
/// - Confirm dan cancel button
/// - Destructive variant (red color untuk aksi berbahaya)
/// - Custom button text
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String description;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.description,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });

  /// Factory untuk delete confirmation
  factory ConfirmationDialog.delete({
    required String itemName,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return ConfirmationDialog(
      title: 'Hapus $itemName?',
      description:
          'Tindakan ini tidak dapat dibatalkan. Data akan dihapus secara permanen.',
      confirmText: 'Hapus',
      cancelText: 'Batal',
      onConfirm: onConfirm,
      onCancel: onCancel,
      isDestructive: true,
    );
  }

  /// Factory untuk logout confirmation
  factory ConfirmationDialog.logout({
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return ConfirmationDialog(
      title: 'Keluar dari Akun?',
      description: 'Anda akan keluar dari akun dan perlu masuk kembali nanti.',
      confirmText: 'Keluar',
      cancelText: 'Batal',
      onConfirm: onConfirm,
      onCancel: onCancel,
      isDestructive: true,
    );
  }

  /// Factory untuk discard changes
  factory ConfirmationDialog.discardChanges({
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return ConfirmationDialog(
      title: 'Buang Perubahan?',
      description: 'Perubahan yang belum disimpan akan hilang.',
      confirmText: 'Buang',
      cancelText: 'Lanjut Edit',
      onConfirm: onConfirm,
      onCancel: onCancel,
      isDestructive: true,
    );
  }

  /// Factory untuk general confirmation
  factory ConfirmationDialog.general({
    required String title,
    required String description,
    String? confirmText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return ConfirmationDialog(
      title: title,
      description: description,
      confirmText: confirmText ?? 'Ya',
      cancelText: 'Tidak',
      onConfirm: onConfirm,
      onCancel: onCancel,
      isDestructive: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      title: Row(
        children: [
          if (isDestructive)
            Container(
              padding: EdgeInsets.all(AppDimensions.paddingS),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: AppDimensions.iconM,
              ),
            ),
          if (isDestructive) SizedBox(width: AppDimensions.paddingM),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: AppDimensions.fontXL,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        description,
        style: const TextStyle(
          fontSize: AppDimensions.fontM,
          color: AppColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onCancel?.call();
          },
          child: Text(
            cancelText ?? 'Batal',
            style: const TextStyle(
              fontSize: AppDimensions.fontM,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm?.call();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isDestructive
                ? AppColors.error
                : AppColors.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingL,
              vertical: AppDimensions.paddingM,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
          ),
          child: Text(
            confirmText ?? 'Konfirmasi',
            style: const TextStyle(
              fontSize: AppDimensions.fontM,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Show confirmation dialog
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String description,
    String? confirmText,
    String? cancelText,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        description: description,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(context).pop(true),
        onCancel: () => Navigator.of(context).pop(false),
      ),
    );
  }
}
