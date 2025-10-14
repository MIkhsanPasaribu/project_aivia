import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Helper class untuk manajemen permission dengan UI dialogs
///
/// Menyediakan dialog explanation dan handling untuk permission requests
/// sesuai dengan Android guidelines untuk better UX
class PermissionHelper {
  /// Show location permission rationale dialog
  ///
  /// Explains WHY the app needs location permission
  /// Returns true if user wants to proceed dengan permission request
  static Future<bool> showLocationRationale(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Colors.blue),
            SizedBox(width: 12),
            Text('Izin Lokasi Diperlukan'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AIVIA memerlukan akses lokasi untuk:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            _BulletPoint(
              icon: Icons.map,
              text: 'Melacak keberadaan pasien secara real-time',
            ),
            _BulletPoint(
              icon: Icons.history,
              text: 'Menyimpan riwayat lokasi untuk keamanan',
            ),
            _BulletPoint(
              icon: Icons.emergency,
              text: 'Mengirim lokasi saat tombol darurat ditekan',
            ),
            SizedBox(height: 12),
            Text(
              'Data lokasi hanya dibagikan dengan keluarga/wali yang terdaftar.',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tidak Sekarang'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Show background location permission rationale
  ///
  /// Explains WHY the app needs "Allow all the time" permission
  /// MUST be called AFTER foreground permission is granted
  static Future<bool> showBackgroundLocationRationale(
    BuildContext context,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.my_location, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(child: Text('Pelacakan Latar Belakang')),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Untuk melacak lokasi saat aplikasi ditutup, pilih:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            Card(
              color: Color(0xFFFFF3E0),
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '"Izinkan sepanjang waktu"',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12),
            _BulletPoint(
              icon: Icons.nightlight_round,
              text: 'Pelacakan tetap aktif 24/7',
            ),
            _BulletPoint(
              icon: Icons.security,
              text: 'Keamanan maksimal untuk pasien',
            ),
            _BulletPoint(
              icon: Icons.battery_saver,
              text: 'Mode hemat daya tersedia',
            ),
            SizedBox(height: 12),
            Text(
              'Anda dapat mengubah pengaturan ini kapan saja di Pengaturan perangkat.',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Lewati'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Aktifkan Sekarang'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Show permission permanently denied dialog
  ///
  /// Explains how to enable permission from Settings
  /// Offers button to open app settings
  static Future<void> showPermissionDeniedDialog(
    BuildContext context, {
    required String permissionName,
    required String reason,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(child: Text('Izin $permissionName Ditolak')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reason),
            const SizedBox(height: 16),
            const Text(
              'Untuk mengaktifkan:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const _BulletPoint(
              icon: Icons.settings,
              text: 'Buka Pengaturan aplikasi',
            ),
            const _BulletPoint(icon: Icons.vpn_key, text: 'Pilih "Izin"'),
            _BulletPoint(icon: Icons.check, text: 'Aktifkan $permissionName'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            icon: const Icon(Icons.settings),
            label: const Text('Buka Pengaturan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Request location permission with proper flow
  ///
  /// 1. Show rationale dialog
  /// 2. Request permission
  /// 3. Handle result dengan appropriate dialogs
  ///
  /// Returns PermissionStatus
  static Future<PermissionStatus> requestLocationPermission(
    BuildContext context,
  ) async {
    // Check current status
    var status = await Permission.location.status;

    // If already granted, return
    if (status.isGranted) {
      return status;
    }

    // If permanently denied, show dialog
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        // Fire and forget
        showPermissionDeniedDialog(
          context,
          permissionName: 'Lokasi',
          reason:
              'Aplikasi memerlukan akses lokasi untuk melacak '
              'keberadaan pasien dan memberikan keamanan.',
        );
      }
      return status;
    }

    // Show rationale first
    if (!context.mounted) return status;

    final shouldRequest = await showLocationRationale(context);
    if (!shouldRequest || !context.mounted) {
      return status;
    }

    // Request permission
    status = await Permission.location.request();

    // Handle result
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        // Fire and forget - no need to await
        showPermissionDeniedDialog(
          context,
          permissionName: 'Lokasi',
          reason:
              'Anda telah menolak izin lokasi secara permanen. '
              'Silakan aktifkan di Pengaturan.',
        );
      }
    }

    return status;
  }

  /// Request background location permission with proper flow
  ///
  /// MUST be called AFTER foreground permission is granted!
  ///
  /// Returns PermissionStatus
  static Future<PermissionStatus> requestBackgroundLocationPermission(
    BuildContext context,
  ) async {
    // Ensure foreground permission is granted first
    final foregroundStatus = await Permission.location.status;
    if (!foregroundStatus.isGranted) {
      throw StateError(
        'Foreground location permission must be granted before requesting background permission',
      );
    }

    // Check current background status
    var status = await Permission.locationAlways.status;

    // If already granted, return
    if (status.isGranted) {
      return status;
    }

    // If permanently denied, show dialog
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        // Fire and forget
        showPermissionDeniedDialog(
          context,
          permissionName: 'Lokasi Latar Belakang',
          reason:
              'Untuk melacak lokasi saat aplikasi ditutup, '
              'pilih "Izinkan sepanjang waktu" di Pengaturan.',
        );
      }
      return status;
    }

    // Show rationale first
    if (!context.mounted) return status;

    final shouldRequest = await showBackgroundLocationRationale(context);
    if (!shouldRequest || !context.mounted) {
      return status;
    }

    // Request permission
    status = await Permission.locationAlways.request();

    // Handle result
    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        // Fire and forget - no need to await
        showPermissionDeniedDialog(
          context,
          permissionName: 'Lokasi Latar Belakang',
          reason:
              'Anda telah menolak izin lokasi latar belakang. '
              'Silakan pilih "Izinkan sepanjang waktu" di Pengaturan.',
        );
      }
    } else if (status.isDenied) {
      if (context.mounted) {
        // User chose "Only while using the app"
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⚠️ Pelacakan latar belakang tidak aktif. '
              'Lokasi hanya dilacak saat aplikasi dibuka.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }

    return status;
  }
}

/// Widget for bullet point list in dialogs
class _BulletPoint extends StatelessWidget {
  const _BulletPoint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
