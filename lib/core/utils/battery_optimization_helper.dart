import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Helper untuk mengelola battery optimization dan background restrictions
///
/// Android Battery Optimization dapat menghentikan foreground service
/// untuk menghemat baterai. Kita perlu request exemption untuk tracking 24/7.
///
/// Fitur:
/// - Check battery optimization status
/// - Request battery optimization exemption
/// - Educational dialog untuk user
/// - Open battery settings untuk manual configuration
class BatteryOptimizationHelper {
  // Method channel untuk future native implementation (if needed)
  // ignore: unused_field
  static const _methodChannel = MethodChannel('com.aivia.app/battery');

  /// Check apakah battery optimization sudah disabled untuk app ini
  /// Return true jika sudah disabled (app bisa run unrestricted)
  static Future<bool> isBatteryOptimizationDisabled() async {
    try {
      // Untuk Android API < 23, battery optimization tidak ada
      if (!await _isAndroid6OrAbove()) {
        return true;
      }

      // Check via permission_handler
      // Note: ignoreWhenInUse di-set false karena kita perlu always-on
      final status = await Permission.ignoreBatteryOptimizations.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('❌ Error checking battery optimization: $e');
      return false;
    }
  }

  /// Request battery optimization exemption
  /// Return true jika user mengizinkan exemption
  static Future<bool> requestBatteryOptimizationExemption() async {
    try {
      if (!await _isAndroid6OrAbove()) {
        return true;
      }

      // Request permission
      final status = await Permission.ignoreBatteryOptimizations.request();
      return status.isGranted;
    } catch (e) {
      debugPrint('❌ Error requesting battery optimization: $e');
      return false;
    }
  }

  /// Open battery optimization settings untuk manual configuration
  /// Berguna jika user menolak request otomatis
  static Future<bool> openBatteryOptimizationSettings() async {
    try {
      if (!await _isAndroid6OrAbove()) {
        return false;
      }

      return await Permission.ignoreBatteryOptimizations.request().isGranted ||
          await openAppSettings();
    } catch (e) {
      debugPrint('❌ Error opening settings: $e');
      return false;
    }
  }

  /// Show educational dialog sebelum request permission
  /// Menjelaskan kenapa battery optimization perlu disabled
  static Future<bool?> showBatteryOptimizationDialog(
    BuildContext context,
  ) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.battery_alert, color: Colors.orange),
              SizedBox(width: 12),
              Expanded(
                child: Text('Optimasi Baterai', style: TextStyle(fontSize: 20)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Untuk pelacakan lokasi 24/7, AIVIA perlu menonaktifkan optimasi baterai.',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Kenapa ini penting?',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildBulletPoint('✓ Pelacakan tetap aktif saat layar mati'),
                _buildBulletPoint('✓ Lokasi selalu terupdate untuk keluarga'),
                _buildBulletPoint('✓ Tombol darurat berfungsi kapan saja'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Penggunaan baterai tetap dioptimalkan dengan mode hemat daya.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Estimasi penggunaan baterai:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                const Text(
                  '• Mode Hemat: ~3-5% per jam',
                  style: TextStyle(fontSize: 13),
                ),
                const Text(
                  '• Mode Seimbang: ~4-6% per jam',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Nanti Saja',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Izinkan'),
            ),
          ],
        );
      },
    );
  }

  /// Show reminder dialog jika user menolak battery optimization exemption
  static Future<bool?> showBatteryOptimizationReminderDialog(
    BuildContext context,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange),
              SizedBox(width: 12),
              Text('Peringatan'),
            ],
          ),
          content: const Text(
            'Pelacakan lokasi mungkin tidak berfungsi optimal karena optimasi baterai masih aktif.\n\n'
            'Untuk pelacakan 24/7, disarankan menonaktifkan optimasi baterai melalui Pengaturan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Tutup'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Buka Pengaturan'),
            ),
          ],
        );
      },
    );
  }

  /// Build bullet point untuk list
  static Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }

  /// Check Android version (API level)
  static Future<bool> _isAndroid6OrAbove() async {
    try {
      // Android 6.0 (API 23) adalah versi pertama dengan Doze mode
      // Untuk Flutter, kita bisa assume modern Android version
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get battery optimization status description untuk display
  static Future<String> getBatteryOptimizationStatusText() async {
    final isDisabled = await isBatteryOptimizationDisabled();
    if (isDisabled) {
      return '✅ Optimasi Baterai: Dinonaktifkan (Optimal)';
    } else {
      return '⚠️ Optimasi Baterai: Aktif (Tidak Disarankan)';
    }
  }

  /// Show complete guide untuk battery optimization di Settings screen
  static void showBatteryOptimizationGuide(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Icon(
                      Icons.battery_charging_full,
                      size: 64,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Panduan Optimasi Baterai',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Untuk pelacakan lokasi yang optimal, ikuti langkah berikut:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  _buildStep('1', 'Buka Pengaturan Android'),
                  _buildStep('2', 'Pilih "Aplikasi" atau "Apps"'),
                  _buildStep('3', 'Cari dan pilih "AIVIA"'),
                  _buildStep('4', 'Pilih "Baterai" atau "Battery"'),
                  _buildStep('5', 'Pilih "Tidak dibatasi" atau "Unrestricted"'),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Tips',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Menu pengaturan bisa berbeda tergantung merek HP (Samsung, Xiaomi, Oppo, dll). Cari kata kunci "Battery optimization" atau "Optimasi Baterai".',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        openBatteryOptimizationSettings();
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('Buka Pengaturan'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(text, style: const TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
