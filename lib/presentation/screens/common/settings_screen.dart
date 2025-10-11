import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_aivia/core/constants/app_colors.dart';
import 'package:project_aivia/core/constants/app_strings.dart';
import 'package:project_aivia/core/constants/app_dimensions.dart';
import 'package:project_aivia/core/utils/logout_helper.dart';

/// Settings Screen - Halaman pengaturan aplikasi
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        children: [
          // Section: Tampilan
          _buildSectionHeader(context, 'Tampilan'),
          _buildSettingTile(
            context,
            icon: Icons.palette_outlined,
            title: 'Tema Aplikasi',
            subtitle: 'Terang / Gelap (Coming Soon)',
            trailing: Switch(
              value: false, // TODO: Connect to theme provider
              onChanged: null, // Disabled for now
              activeThumbColor: AppColors.primary,
            ),
          ),
          _buildSettingTile(
            context,
            icon: Icons.text_fields,
            title: 'Ukuran Teks',
            subtitle: 'Normal (Coming Soon)',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur ukuran teks akan datang')),
              );
            },
          ),

          const Divider(height: 32),

          // Section: Notifikasi
          _buildSectionHeader(context, 'Notifikasi'),
          _buildSettingTile(
            context,
            icon: Icons.notifications_active_outlined,
            title: 'Notifikasi Aktivitas',
            subtitle: 'Pengingat untuk aktivitas harian',
            trailing: Switch(
              value: true, // TODO: Connect to notification service
              onChanged: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? 'Notifikasi aktivitas diaktifkan'
                          : 'Notifikasi aktivitas dinonaktifkan',
                    ),
                  ),
                );
              },
              activeThumbColor: AppColors.primary,
            ),
          ),
          _buildSettingTile(
            context,
            icon: Icons.alarm,
            title: 'Waktu Pengingat',
            subtitle: '15 menit sebelum aktivitas',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showReminderTimePicker(context);
            },
          ),

          const Divider(height: 32),

          // Section: Privasi & Keamanan
          _buildSectionHeader(context, 'Privasi & Keamanan'),
          _buildSettingTile(
            context,
            icon: Icons.location_on_outlined,
            title: 'Pelacakan Lokasi',
            subtitle: 'Izinkan aplikasi melacak lokasi',
            trailing: Switch(
              value: true, // TODO: Check actual permission status
              onChanged: (value) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      value
                          ? 'Pelacakan lokasi diaktifkan'
                          : 'Pelacakan lokasi dinonaktifkan',
                    ),
                  ),
                );
              },
              activeThumbColor: AppColors.primary,
            ),
          ),
          _buildSettingTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Kebijakan Privasi',
            subtitle: 'Baca kebijakan privasi kami',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showPrivacyPolicyDialog(context);
            },
          ),

          const Divider(height: 32),

          // Section: Tentang
          _buildSectionHeader(context, 'Tentang'),
          _buildSettingTile(
            context,
            icon: Icons.info_outline,
            title: 'Tentang Aplikasi',
            subtitle: 'AIVIA v1.0.0',
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAboutDialog(context),
          ),
          _buildSettingTile(
            context,
            icon: Icons.help_outline,
            title: 'Bantuan & Dukungan',
            subtitle: 'Panduan penggunaan aplikasi',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showHelpDialog(context);
            },
          ),

          const Divider(height: 32),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: ElevatedButton.icon(
              onPressed: () => LogoutHelper.showLogoutConfirmation(
                context: context,
                ref: ref,
              ),
              icon: const Icon(Icons.logout),
              label: const Text(AppStrings.logout),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(AppDimensions.buttonHeightL),
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.paddingXL),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.paddingL,
        AppDimensions.paddingL,
        AppDimensions.paddingL,
        AppDimensions.paddingS,
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingS),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  void _showReminderTimePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih Waktu Pengingat',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppDimensions.paddingL),
              _buildReminderOption(context, '5 menit sebelum'),
              _buildReminderOption(context, '15 menit sebelum', selected: true),
              _buildReminderOption(context, '30 menit sebelum'),
              _buildReminderOption(context, '1 jam sebelum'),
              const SizedBox(height: AppDimensions.paddingL),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReminderOption(
    BuildContext context,
    String text, {
    bool selected = false,
  }) {
    return ListTile(
      title: Text(text),
      trailing: selected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Waktu pengingat: $text')));
      },
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Kebijakan Privasi'),
          content: const SingleChildScrollView(
            child: Text(
              'AIVIA menghormati privasi Anda. Aplikasi ini mengumpulkan data lokasi, '
              'informasi aktivitas, dan foto wajah untuk membantu pengguna dengan Alzheimer.\n\n'
              'Data Anda:\n'
              '• Disimpan dengan aman di server terenkripsi\n'
              '• Tidak dibagikan ke pihak ketiga\n'
              '• Dapat dihapus kapan saja\n\n'
              'Dengan menggunakan aplikasi ini, Anda menyetujui kebijakan privasi kami.',
              style: TextStyle(height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppStrings.appName,
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        ),
        child: const Icon(Icons.favorite, color: Colors.white, size: 32),
      ),
      children: const [
        SizedBox(height: AppDimensions.paddingM),
        Text(
          'AIVIA adalah aplikasi asisten untuk anak-anak penderita Alzheimer, '
          'dirancang untuk membantu mereka mengingat aktivitas harian dan '
          'mengenali orang-orang terdekat.',
          style: TextStyle(height: 1.5),
        ),
        SizedBox(height: AppDimensions.paddingM),
        Text(
          '© 2024 Tim AIVIA. Semua hak dilindungi.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Bantuan & Dukungan'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Fitur Utama:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: AppDimensions.paddingS),
                Text('• Jurnal Aktivitas: Catat dan ingatkan aktivitas harian'),
                Text('• Kenali Wajah: Kenali orang-orang terdekat'),
                Text('• Pelacakan Lokasi: Pantau lokasi secara real-time'),
                Text('• Tombol Darurat: Hubungi kontak darurat'),
                SizedBox(height: AppDimensions.paddingM),
                Text(
                  'Butuh Bantuan?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: AppDimensions.paddingS),
                Text('Email: support@aivia.app'),
                Text('WhatsApp: +62 812-3456-7890'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }
}
