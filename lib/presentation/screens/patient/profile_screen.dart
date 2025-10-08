import 'package:flutter/material.dart';
import 'package:project_aivia/core/constants/app_colors.dart';
import 'package:project_aivia/core/constants/app_strings.dart';
import 'package:project_aivia/core/constants/app_dimensions.dart';

/// Profile Screen - Halaman profil pengguna
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Get user data from Riverpod provider
    // Dummy data untuk testing
    const userName = 'Budi Santoso';
    const userEmail = 'budi@example.com';
    const userRole = 'Pasien';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
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
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surface,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: AppDimensions.elevationM,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      size: AppDimensions.iconXXL,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: AppDimensions.paddingM),

                  // Name
                  Text(
                    userName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),

                  const SizedBox(height: AppDimensions.paddingXS),

                  // Email
                  Text(
                    userEmail,
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
                      borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
                    ),
                    child: Text(
                      userRole,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppDimensions.paddingL),

            // Menu Items
            _buildMenuItem(
              context,
              icon: Icons.edit_outlined,
              title: 'Edit Profil',
              subtitle: 'Ubah informasi pribadi Anda',
              onTap: () {
                // TODO: Navigate to edit profile
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur Edit Profil (Coming Soon)')),
                );
              },
            ),

            _buildMenuItem(
              context,
              icon: Icons.notifications_outlined,
              title: 'Notifikasi',
              subtitle: 'Atur pengingat aktivitas',
              onTap: () {
                // TODO: Navigate to notification settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pengaturan Notifikasi (Coming Soon)')),
                );
              },
            ),

            _buildMenuItem(
              context,
              icon: Icons.help_outline,
              title: 'Bantuan',
              subtitle: 'Panduan penggunaan aplikasi',
              onTap: () {
                // TODO: Navigate to help
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bantuan (Coming Soon)')),
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
              padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingL),
              child: ElevatedButton(
                onPressed: () => _handleLogout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(AppDimensions.buttonHeightL),
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
            color: AppColors.primary.withOpacity(0.1),
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
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
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

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text(AppStrings.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.no),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement logout with Supabase
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(AppStrings.successLogout),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text(AppStrings.yes),
          ),
        ],
      ),
    );
  }
}
