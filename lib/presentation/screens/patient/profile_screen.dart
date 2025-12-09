import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_aivia/core/constants/app_colors.dart';
import 'package:project_aivia/core/constants/app_strings.dart';
import 'package:project_aivia/core/constants/app_dimensions.dart';
import 'package:project_aivia/core/utils/logout_helper.dart';
import 'package:project_aivia/presentation/providers/auth_provider.dart';
import 'package:project_aivia/presentation/providers/location_service_provider.dart';
import 'package:project_aivia/data/services/location_service.dart';
import 'package:project_aivia/presentation/screens/patient/profile/edit_profile_screen.dart';
import 'package:project_aivia/presentation/screens/common/settings_screen.dart';
import 'package:project_aivia/presentation/screens/common/help_screen.dart';

/// Profile Screen - Halaman profil pengguna
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get user data from provider
    final currentUserAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        automaticallyImplyLeading: false,
      ),
      body: currentUserAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User tidak ditemukan'));
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppDimensions.paddingXL),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(AppDimensions.radiusXL),
                      bottomRight: Radius.circular(AppDimensions.radiusXL),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.surface,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).shadowColor.withValues(alpha: 0.3),
                              blurRadius: AppDimensions.elevationM,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: user.avatarUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  user.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.person,
                                      size: AppDimensions.iconXXL,
                                      color: AppColors.primary,
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: AppDimensions.iconXXL,
                                color: AppColors.primary,
                              ),
                      ),

                      const SizedBox(height: AppDimensions.paddingM),

                      // Name
                      Text(
                        user.fullName,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                      ),

                      const SizedBox(height: AppDimensions.paddingXS),

                      // Email
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: AppDimensions.paddingS),

                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.paddingM,
                          vertical: AppDimensions.paddingS,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusCircle,
                          ),
                        ),
                        child: Text(
                          user.userRole.displayName,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.paddingL),

                // ✅ Location Tracking Status Indicator
                _buildTrackingStatusCard(context, ref),

                const SizedBox(height: AppDimensions.paddingM),

                // Menu Items
                _buildMenuItem(
                  context,
                  icon: Icons.edit_outlined,
                  title: 'Edit Profil',
                  subtitle: 'Ubah informasi pribadi Anda',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                ),

                _buildMenuItem(
                  context,
                  icon: Icons.notifications_outlined,
                  title: 'Notifikasi',
                  subtitle: 'Atur pengingat aktivitas',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),

                _buildMenuItem(
                  context,
                  icon: Icons.settings_outlined,
                  title: 'Pengaturan',
                  subtitle: 'Preferensi & konfigurasi aplikasi',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),

                _buildMenuItem(
                  context,
                  icon: Icons.help_outline,
                  title: 'Bantuan',
                  subtitle: 'Panduan penggunaan aplikasi',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpScreen(),
                      ),
                    );
                  },
                ),

                _buildMenuItem(
                  context,
                  icon: Icons.info_outline,
                  title: 'Tentang Aplikasi',
                  subtitle: 'Informasi AIVIA',
                  onTap: () => _showAboutDialog(context),
                ),

                const SizedBox(height: AppDimensions.paddingL),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.paddingL,
                  ),
                  child: ElevatedButton(
                    onPressed: () => LogoutHelper.showLogoutConfirmation(
                      context: context,
                      ref: ref,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                      minimumSize: const Size.fromHeight(
                        AppDimensions.buttonHeightL,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.logout),
                        SizedBox(width: AppDimensions.paddingS),
                        Text(AppStrings.logout),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppDimensions.paddingXL),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: AppDimensions.paddingL),
              Text('Error: ${error.toString()}'),
            ],
          ),
        ),
      ),
    );
  }

  /// Build tracking status indicator card
  Widget _buildTrackingStatusCard(BuildContext context, WidgetRef ref) {
    final isTracking = ref.watch(isTrackingProvider);
    final trackingMode = ref.watch(trackingModeProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isTracking
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.textTertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Icon(
                isTracking ? Icons.location_on : Icons.location_off,
                color: isTracking ? AppColors.success : AppColors.textTertiary,
                size: AppDimensions.iconL,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pelacakan Lokasi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isTracking
                        ? 'Aktif - Mode: ${trackingMode.displayName}'
                        : 'Tidak Aktif',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isTracking
                          ? AppColors.success
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isTracking ? AppColors.success : AppColors.textTertiary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingL,
        vertical: AppDimensions.paddingS,
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: AppDimensions.iconL,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textTertiary,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Image.asset(
                'assets/images/logo_noname.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            const Text(AppStrings.appName),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              AppStrings.appTagline,
              style: TextStyle(fontSize: AppDimensions.fontL),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            const Text('Versi: 0.1.0'),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              'AIVIA adalah aplikasi asisten untuk membantu anak-anak penderita Alzheimer dalam aktivitas sehari-hari.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.ok),
          ),
        ],
      ),
    );
  }
}
