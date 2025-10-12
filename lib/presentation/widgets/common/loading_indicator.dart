import 'package:flutter/material.dart';
import 'package:project_aivia/core/constants/app_colors.dart';

/// Custom loading indicator widget dengan support untuk overlay dan custom message
///
/// Features:
/// - Circular loading indicator
/// - Overlay mode (fullscreen dengan barrier)
/// - Custom message
/// - Custom color
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final bool withOverlay;
  final Color? color;
  final double size;

  const LoadingIndicator({
    super.key,
    this.message,
    this.withOverlay = false,
    this.color,
    this.size = 40,
  });

  /// Factory untuk loading overlay fullscreen
  static Widget overlay({String? message}) {
    return const LoadingIndicator(
      withOverlay: true,
      message: null, // Will use default or parameter message
    );
  }

  @override
  Widget build(BuildContext context) {
    final loadingWidget = _buildLoadingContent();

    if (withOverlay) {
      return Container(
        color: Theme.of(context).shadowColor.withValues(alpha: 0.5),
        child: Center(child: loadingWidget),
      );
    }

    return Center(child: loadingWidget);
  }

  Widget _buildLoadingContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppColors.primary,
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// Show loading dialog
  static void showLoadingDialog(
    BuildContext context, {
    String? message,
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => PopScope(
        canPop: barrierDismissible,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: LoadingIndicator(message: message),
          ),
        ),
      ),
    );
  }

  /// Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
