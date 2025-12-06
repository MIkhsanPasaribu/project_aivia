import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/result.dart';
import '../../providers/emergency_provider.dart';
import '../../providers/location_service_provider.dart';
import '../../providers/profile_provider.dart';
import '../../../data/repositories/fcm_repository.dart';
import '../../../data/repositories/emergency_repository.dart';

/// Emergency Button Widget - FAB untuk trigger emergency alert
///
/// Features:
/// - Large red FAB dengan icon warning
/// - Long press atau tap dengan confirmation dialog
/// - Auto-capture current location
/// - Create emergency alert di database
/// - Show loading state
/// - Success/error feedback
///
/// Usage:
/// ```dart
/// Scaffold(
///   floatingActionButton: EmergencyButton(patientId: currentUserId),
/// )
/// ```
class EmergencyButton extends ConsumerStatefulWidget {
  final String patientId;
  final VoidCallback? onAlertCreated;
  final bool requireConfirmation;

  const EmergencyButton({
    super.key,
    required this.patientId,
    this.onAlertCreated,
    this.requireConfirmation = true,
  });

  @override
  ConsumerState<EmergencyButton> createState() => _EmergencyButtonState();
}

class _EmergencyButtonState extends ConsumerState<EmergencyButton>
    with SingleTickerProviderStateMixin {
  bool _isProcessing = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Setup pulse animation untuk visual cue
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleEmergencyPress() async {
    if (_isProcessing) return;

    // Show confirmation dialog if required
    if (widget.requireConfirmation) {
      final confirmed = await _showConfirmationDialog();
      if (!confirmed) return;
    }

    setState(() => _isProcessing = true);

    try {
      // Step 1: Get current location
      final locationService = ref.read(locationServiceProvider);
      final positionResult = await locationService.getCurrentPosition();

      Position? position;
      if (positionResult is Success<Position>) {
        position = positionResult.data;
      }

      // Step 2: Create emergency alert
      final notifier = ref.read(emergencyActionsProvider.notifier);
      final result = await notifier.triggerEmergency(
        patientId: widget.patientId,
        alertType: 'panic_button',
        latitude: position?.latitude,
        longitude: position?.longitude,
        message: 'Tombol darurat ditekan oleh pasien',
        severity: 'critical',
      );

      if (!mounted) return;

      result.fold(
        onSuccess: (alert) async {
          // ✨ Queue notifications untuk emergency contacts
          try {
            final fcmRepository = FCMRepository();
            final emergencyRepo = EmergencyRepository();

            // Get emergency contacts
            final contactsResult = await emergencyRepo.getContacts(
              widget.patientId,
            );

            if (contactsResult is Success) {
              final contacts = contactsResult.data;

              // Get patient profile untuk nama
              final profileAsync = ref.read(currentUserProfileStreamProvider);
              final patientName = profileAsync.whenData(
                (profile) => profile?.fullName ?? 'Pasien',
              );

              // Queue notification untuk setiap contact
              for (final contact in contacts) {
                try {
                  await fcmRepository.queueNotification(
                    recipientUserId: contact.contactId,
                    notificationType: 'emergency',
                    title: 'PERINGATAN DARURAT!',
                    body:
                        '${patientName.value ?? "Pasien"} membutuhkan bantuan segera!',
                    data: {
                      'type': 'emergency_alert',
                      'patient_id': widget.patientId,
                      'alert_id': alert.id,
                      'latitude': position?.latitude.toString(),
                      'longitude': position?.longitude.toString(),
                    },
                    priority: 10, // Max priority untuk emergency
                  );
                } catch (e) {
                  debugPrint('⚠️ Failed to queue notification for contact: $e');
                }
              }

              debugPrint(
                '✅ Emergency notifications queued for ${contacts.length} contacts',
              );
            }
          } catch (e) {
            debugPrint('⚠️ Error queueing emergency notifications: $e');
            // Don't fail the whole process if notification queueing fails
          }

          // Show success message
          _showSuccessSnackBar();
          widget.onAlertCreated?.call();
        },
        onFailure: (failure) {
          _showErrorSnackBar('Gagal membuat alert darurat: $failure');
        },
      );
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<bool> _showConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: AppColors.emergency,
                  size: 32,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Tombol Darurat',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Apakah Anda yakin ingin mengirim peringatan darurat?',
                  style: TextStyle(fontSize: 16, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.emergency.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Semua kontak darurat Anda akan menerima notifikasi beserta lokasi Anda saat ini.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emergency,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Ya, Kirim',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Peringatan darurat terkirim!\nKontak darurat akan segera dihubungi.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: FloatingActionButton.large(
        onPressed: _isProcessing ? null : _handleEmergencyPress,
        backgroundColor: AppColors.emergency,
        foregroundColor: Colors.white,
        elevation: 8,
        heroTag: 'emergency_button',
        child: _isProcessing
            ? const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.emergency, size: 40),
      ),
    );
  }
}
