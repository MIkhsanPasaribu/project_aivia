import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_aivia/core/constants/app_strings.dart';
import 'package:project_aivia/presentation/providers/auth_provider.dart';
import 'package:project_aivia/presentation/providers/location_service_provider.dart';

/// Helper class untuk optimasi logout process
/// Mengatasi masalah logout yang lambat dengan:
/// 1. Timeout handling
/// 2. Clear providers
/// 3. Single loading indicator
/// 4. ✅ Stop location tracking
class LogoutHelper {
  /// Logout dengan timeout dan error handling
  static Future<void> performLogout({
    required BuildContext context,
    required WidgetRef ref,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Keluar dari akun...', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    try {
      // ✅ STEP 1: Stop location tracking sebelum logout
      try {
        final locationService = ref.read(locationServiceProvider);
        await locationService.stopTracking();
        ref.read(isTrackingProvider.notifier).state = false;
        debugPrint('✅ Location tracking stopped before logout');
      } catch (e) {
        debugPrint('⚠️ Error stopping location tracking: $e');
        // Continue with logout even if stop tracking fails
      }

      // STEP 2: Call logout dengan timeout
      final authRepository = ref.read(authRepositoryProvider);
      final result = await authRepository.signOut().timeout(
        timeout,
        onTimeout: () {
          // Force logout secara lokal jika timeout
          return authRepository.forceSignOut();
        },
      );

      if (!context.mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      result.fold(
        onSuccess: (_) {
          // Clear all providers
          ref.invalidate(currentUserProfileProvider);
          ref.invalidate(authStateChangesProvider);
          ref.invalidate(isTrackingProvider);

          // Navigate to login
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil('/login', (route) => false);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(AppStrings.successLogout),
              backgroundColor: Theme.of(context).colorScheme.tertiary,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        onFailure: (failure) {
          // Show error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 3),
            ),
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal logout: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Show logout confirmation dialog
  static Future<void> showLogoutConfirmation({
    required BuildContext context,
    required WidgetRef ref,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text(AppStrings.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.no),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text(AppStrings.yes),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await performLogout(context: context, ref: ref);
    }
  }
}
