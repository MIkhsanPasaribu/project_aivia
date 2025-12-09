import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:project_aivia/core/constants/app_colors.dart';
import 'package:project_aivia/core/constants/app_strings.dart';
import 'package:project_aivia/core/constants/app_dimensions.dart';
import 'package:project_aivia/core/utils/logout_helper.dart';
import 'package:project_aivia/core/utils/permission_helper.dart';
import 'package:project_aivia/presentation/screens/common/help_screen.dart';
import 'package:project_aivia/presentation/providers/notification_settings_provider.dart';
import 'package:project_aivia/presentation/providers/theme_provider.dart';
import 'package:project_aivia/presentation/providers/location_service_provider.dart';
import 'package:project_aivia/presentation/providers/location_provider.dart';
import 'package:project_aivia/presentation/providers/auth_provider.dart';
import 'package:intl/intl.dart';

/// Settings Screen - Halaman pengaturan aplikasi
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  bool _isLocationPermissionGranted = false;
  bool _isLoadingPermission = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLocationPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh permission status when app resumes
    if (state == AppLifecycleState.resumed) {
      _checkLocationPermission();
    }
  }

  Future<void> _checkLocationPermission() async {
    try {
      // Check foreground permission
      final foregroundStatus = await Permission.location.status;

      // Check background permission (Android 10+)
      final backgroundStatus = await Permission.locationAlways.status;

      // Check if location service is actually enabled on device
      final locationService = ref.read(locationServiceProvider);
      final isTracking = locationService.isTracking;

      if (mounted) {
        setState(() {
          // Consider granted only if foreground permission is given
          // Background is optional but tracking requires it for full functionality
          _isLocationPermissionGranted = foregroundStatus.isGranted;
          _isLoadingPermission = false;
        });

        // Log detailed status for debugging
        debugPrint('📍 Permission Status:');
        debugPrint('   Foreground: ${foregroundStatus.name}');
        debugPrint('   Background: ${backgroundStatus.name}');
        debugPrint('   Tracking: $isTracking');
      }
    } catch (e) {
      debugPrint('❌ Error checking location permission: $e');
      if (mounted) {
        setState(() {
          _isLoadingPermission = false;
        });
      }
    }
  }

  Future<void> _handleLocationPermissionToggle(bool value) async {
    if (value) {
      // Request permission
      if (!mounted) return;
      final status = await PermissionHelper.requestLocationPermission(context);
      if (mounted) {
        setState(() {
          _isLocationPermissionGranted = status.isGranted;
        });
        if (status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pelacakan lokasi diaktifkan')),
          );
        }
      }
    } else {
      // Show guidance to disable in settings
      if (!mounted) return;
      await PermissionHelper.showPermissionDeniedDialog(
        context,
        permissionName: 'Lokasi',
        reason:
            'Untuk menonaktifkan pelacakan lokasi, silakan ubah pengaturan di sistem Android.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        children: [
          // Section: Tampilan
          _buildSectionHeader(context, 'Tampilan'),
          _buildThemeModeTile(context, ref),
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
              value: ref.watch(notificationEnabledProvider),
              onChanged: (value) {
                ref
                    .read(notificationEnabledProvider.notifier)
                    .setEnabled(value);
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
            trailing: _isLoadingPermission
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Switch(
                    value: _isLocationPermissionGranted,
                    onChanged: _handleLocationPermissionToggle,
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

          // Section: Lokasi Saya (for Patient users)
          _buildSectionHeader(context, 'Lokasi Saya'),
          _buildCurrentLocationCard(context, ref),

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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpScreen()),
              );
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
                foregroundColor: Theme.of(context).colorScheme.onError,
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
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.5),
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
        child: Icon(
          Icons.favorite,
          color: Theme.of(context).colorScheme.onPrimary,
          size: 32,
        ),
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

  /// Build theme mode selector tile dengan visual preview
  Widget _buildThemeModeTile(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(currentThemeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    String getThemeModeLabel() {
      switch (themeMode) {
        case ThemeMode.light:
          return 'Terang';
        case ThemeMode.dark:
          return 'Gelap';
        case ThemeMode.system:
          return 'Ikuti Sistem';
      }
    }

    return _buildSettingTile(
      context,
      icon: isDark ? Icons.dark_mode : Icons.light_mode,
      title: 'Tema Aplikasi',
      subtitle: getThemeModeLabel(),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeDialog(context, ref),
    );
  }

  /// Dialog untuk memilih theme mode
  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final currentThemeMode = ref.read(currentThemeModeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Pilih Tema',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              context,
              ref,
              icon: Icons.light_mode,
              title: 'Tema Terang',
              description: 'Cocok untuk siang hari',
              themeMode: ThemeMode.light,
              isSelected: currentThemeMode == ThemeMode.light,
            ),
            const SizedBox(height: AppDimensions.paddingM),
            _buildThemeOption(
              context,
              ref,
              icon: Icons.dark_mode,
              title: 'Tema Gelap',
              description: 'Lebih nyaman di malam hari',
              themeMode: ThemeMode.dark,
              isSelected: currentThemeMode == ThemeMode.dark,
            ),
            const SizedBox(height: AppDimensions.paddingM),
            _buildThemeOption(
              context,
              ref,
              icon: Icons.brightness_auto,
              title: 'Otomatis',
              description: 'Ikuti pengaturan sistem',
              themeMode: ThemeMode.system,
              isSelected: currentThemeMode == ThemeMode.system,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  /// Build theme option card
  Widget _buildThemeOption(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String title,
    required String description,
    required ThemeMode themeMode,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () async {
        await ref.read(themeModeProvider.notifier).setThemeMode(themeMode);
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tema berhasil diubah ke $title'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingS),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.divider,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  /// Build current location display card
  Widget _buildCurrentLocationCard(BuildContext context, WidgetRef ref) {
    // Get current user ID
    final currentUserAsync = ref.watch(authStateChangesProvider);

    return currentUserAsync.when(
      data: (user) {
        if (user == null) {
          return const SizedBox.shrink();
        }

        // Watch last location for current user
        final lastLocationAsync = ref.watch(lastLocationProvider(user.id));

        return lastLocationAsync.when(
          data: (location) {
            if (location == null) {
              return _buildNoLocationCard(context);
            }

            // Format timestamp
            final timeAgo = _formatTimeAgo(location.timestamp);
            final formattedDate = DateFormat(
              'dd MMM yyyy, HH:mm',
            ).format(location.timestamp);

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingM,
                vertical: AppDimensions.paddingS,
              ),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppDimensions.paddingS),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusM,
                            ),
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: AppColors.secondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.paddingM),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Lokasi Terakhir',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                timeAgo,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Copy button
                        IconButton(
                          onPressed: () => _copyLocationToClipboard(
                            context,
                            location.formattedLocation,
                          ),
                          icon: const Icon(Icons.copy, size: 20),
                          tooltip: 'Salin koordinat',
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.paddingM),
                    const Divider(height: 1),
                    const SizedBox(height: AppDimensions.paddingM),

                    // Coordinates
                    _buildLocationInfoRow(
                      context,
                      icon: Icons.place,
                      label: 'Koordinat',
                      value: location.formattedLocation,
                    ),
                    const SizedBox(height: AppDimensions.paddingS),

                    // Accuracy
                    _buildLocationInfoRow(
                      context,
                      icon: Icons.gps_fixed,
                      label: 'Akurasi',
                      value: location.accuracyLabel,
                    ),
                    const SizedBox(height: AppDimensions.paddingS),

                    // Timestamp
                    _buildLocationInfoRow(
                      context,
                      icon: Icons.access_time,
                      label: 'Waktu',
                      value: formattedDate,
                    ),

                    // Info message
                    const SizedBox(height: AppDimensions.paddingM),
                    Container(
                      padding: const EdgeInsets.all(AppDimensions.paddingS),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusM,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: AppDimensions.paddingS),
                          Expanded(
                            child: Text(
                              'Lokasi ini dapat digunakan keluarga untuk menemukan Anda jika pelacakan bermasalah',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => Card(
            margin: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
              vertical: AppDimensions.paddingS,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: AppDimensions.paddingM),
                    Text(
                      'Memuat lokasi...',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          error: (error, stack) => Card(
            margin: const EdgeInsets.symmetric(
              horizontal: AppDimensions.paddingM,
              vertical: AppDimensions.paddingS,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.error),
                  const SizedBox(width: AppDimensions.paddingM),
                  Expanded(
                    child: Text(
                      'Gagal memuat lokasi',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  /// Build no location card
  Widget _buildNoLocationCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingM,
        vertical: AppDimensions.paddingS,
      ),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          children: [
            Icon(
              Icons.location_off,
              size: 48,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            const Text(
              'Belum Ada Data Lokasi',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppDimensions.paddingS),
            Text(
              'Lokasi Anda akan muncul di sini setelah pelacakan diaktifkan',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build location info row
  Widget _buildLocationInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppDimensions.paddingS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Format time ago
  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Baru saja';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit yang lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam yang lalu';
    } else if (diff.inDays == 1) {
      return 'Kemarin';
    } else {
      return '${diff.inDays} hari yang lalu';
    }
  }

  /// Copy location to clipboard
  void _copyLocationToClipboard(BuildContext context, String coordinates) {
    Clipboard.setData(ClipboardData(text: coordinates));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Koordinat disalin ke clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
