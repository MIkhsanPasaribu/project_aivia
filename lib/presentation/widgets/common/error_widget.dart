import 'package:flutter/material.dart';
import 'package:project_aivia/core/constants/app_colors.dart';
import 'package:project_aivia/core/constants/app_dimensions.dart';

/// Custom error widget dengan support untuk retry action
///
/// Features:
/// - Error icon
/// - Error message
/// - Retry button (optional)
/// - Custom icon dan message
class CustomErrorWidget extends StatelessWidget {
  final String message;
  final String? title;
  final IconData icon;
  final VoidCallback? onRetry;
  final String? retryButtonText;

  const CustomErrorWidget({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.error_outline,
    this.onRetry,
    this.retryButtonText,
  });

  /// Factory untuk network error
  factory CustomErrorWidget.network({VoidCallback? onRetry}) {
    return CustomErrorWidget(
      title: 'Koneksi Bermasalah',
      message:
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      icon: Icons.wifi_off,
      onRetry: onRetry,
      retryButtonText: 'Coba Lagi',
    );
  }

  /// Factory untuk not found error
  factory CustomErrorWidget.notFound({String? message}) {
    return CustomErrorWidget(
      title: 'Tidak Ditemukan',
      message: message ?? 'Data yang Anda cari tidak ditemukan.',
      icon: Icons.search_off,
    );
  }

  /// Factory untuk unauthorized error
  factory CustomErrorWidget.unauthorized({VoidCallback? onRetry}) {
    return CustomErrorWidget(
      title: 'Sesi Berakhir',
      message: 'Sesi Anda telah berakhir. Silakan masuk kembali.',
      icon: Icons.lock_outline,
      onRetry: onRetry,
      retryButtonText: 'Masuk Kembali',
    );
  }

  /// Factory untuk general error
  factory CustomErrorWidget.general({String? message, VoidCallback? onRetry}) {
    return CustomErrorWidget(
      title: 'Terjadi Kesalahan',
      message:
          message ?? 'Terjadi kesalahan yang tidak terduga. Silakan coba lagi.',
      icon: Icons.error_outline,
      onRetry: onRetry,
      retryButtonText: 'Coba Lagi',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: AppDimensions.iconXXL, color: AppColors.error),
            SizedBox(height: AppDimensions.paddingL),
            if (title != null) ...[
              Text(
                title!,
                style: const TextStyle(
                  fontSize: AppDimensions.fontXL,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDimensions.paddingS),
            ],
            Text(
              message,
              style: const TextStyle(
                fontSize: AppDimensions.fontM,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: AppDimensions.paddingL),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryButtonText ?? 'Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
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
