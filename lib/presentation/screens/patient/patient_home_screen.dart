import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_aivia/core/constants/app_strings.dart';
import 'package:project_aivia/core/constants/app_dimensions.dart';
import 'package:project_aivia/core/constants/app_colors.dart';
import 'package:project_aivia/presentation/screens/patient/activity/activity_list_screen.dart';
import 'package:project_aivia/presentation/screens/patient/profile_screen.dart';
import 'package:project_aivia/presentation/screens/patient/face_recognition/recognize_face_screen.dart';
import 'package:project_aivia/presentation/widgets/emergency/draggable_emergency_button.dart';
import 'package:project_aivia/presentation/providers/auth_provider.dart';
import 'package:project_aivia/presentation/providers/location_service_provider.dart';
import 'package:project_aivia/data/services/location_service.dart';
import 'package:project_aivia/core/utils/battery_optimization_helper.dart';

/// Patient Home Screen dengan Bottom Navigation
class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen>
    with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _isInitializingTracking = false;
  bool _trackingWasActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize location tracking setelah build pertama
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLocationTracking();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Stop tracking saat screen di-dispose
    // FIXED: Cek init status untuk prevent race condition
    if (!_isInitializingTracking) {
      _stopLocationTracking();
    } else {
      debugPrint('⚠️ Cannot stop tracking while initializing');
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final locationService = ref.read(locationServiceProvider);

    if (state == AppLifecycleState.paused) {
      // Save tracking state when app goes to background
      _trackingWasActive = locationService.isTracking;
      debugPrint('📍 App paused. Tracking was: $_trackingWasActive');
    } else if (state == AppLifecycleState.resumed) {
      // Resume tracking if it was active before
      debugPrint('📍 App resumed. Checking tracking status...');

      if (_trackingWasActive && !locationService.isTracking) {
        debugPrint('🔄 Auto-resuming location tracking...');
        _initializeLocationTracking();
      } else if (locationService.isTracking) {
        debugPrint('✅ Tracking still active');
      } else {
        debugPrint('ℹ️ Tracking was not active');
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Initialize dan start location tracking
  Future<void> _initializeLocationTracking() async {
    if (_isInitializingTracking) return;

    setState(() {
      _isInitializingTracking = true;
    });

    try {
      final userId = ref.read(currentUserProfileProvider).value?.id;
      if (userId == null) {
        debugPrint('⚠️ User ID tidak tersedia, skip location tracking');
        return;
      }

      final locationService = ref.read(locationServiceProvider);

      // STEP 1: Initialize location service
      debugPrint('📍 Initializing location service...');
      final initResult = await locationService.initialize();
      if (initResult.isFailure) {
        debugPrint('❌ Failed to init location: ${initResult.failure}');
        return;
      }
      debugPrint('✅ Location service initialized');

      // STEP 2: Request foreground location permission
      debugPrint('📍 Requesting location permission...');
      final permResult = await locationService.requestLocationPermission();
      if (permResult.isFailure) {
        debugPrint('⚠️ Location permission denied');
        // Tampilkan dialog penjelasan
        if (mounted) {
          _showPermissionDialog();
        }
        return;
      }
      debugPrint('✅ Location permission granted');

      // STEP 3: Request background permission (optional)
      debugPrint('📍 Requesting background permission...');
      final bgPermResult = await locationService.requestBackgroundPermission();
      bgPermResult.fold(
        onSuccess: (granted) {
          if (granted) {
            debugPrint('✅ Background location permission granted');
          } else {
            debugPrint(
              '⚠️ Background location permission denied (app will track only in foreground)',
            );
          }
        },
        onFailure: (_) {
          debugPrint(
            '⚠️ Background location permission denied (app will track only in foreground)',
          );
        },
      );

      // STEP 3.5: Check battery optimization status (NEW)
      debugPrint('🔋 Checking battery optimization...');
      final isBatteryOptimized =
          await BatteryOptimizationHelper.isBatteryOptimizationDisabled();

      if (!isBatteryOptimized && mounted) {
        debugPrint('⚠️ Battery optimization is enabled');
        // Show educational dialog
        final shouldRequest =
            await BatteryOptimizationHelper.showBatteryOptimizationDialog(
              // ignore: use_build_context_synchronously
              context,
            ) ??
            false;

        if (shouldRequest) {
          final granted =
              await BatteryOptimizationHelper.requestBatteryOptimizationExemption();
          if (granted) {
            debugPrint('✅ Battery optimization exemption granted');
          } else {
            debugPrint('⚠️ Battery optimization exemption denied');
            // Show reminder
            if (mounted) {
              final shouldOpenSettings =
                  await BatteryOptimizationHelper.showBatteryOptimizationReminderDialog(
                    // ignore: use_build_context_synchronously
                    context,
                  ) ??
                  false;
              if (shouldOpenSettings) {
                await BatteryOptimizationHelper.openBatteryOptimizationSettings();
              }
            }
          }
        }
      } else {
        debugPrint('✅ Battery optimization already disabled');
      }

      // STEP 4: Start tracking dengan balanced mode
      debugPrint('📍 Starting location tracking...');

      // Check if already tracking to avoid duplicate streams
      if (locationService.isTracking) {
        debugPrint('ℹ️ Location tracking already active');
        ref.read(isTrackingProvider.notifier).state = true;
        return;
      }

      final trackResult = await locationService.startTracking(
        userId,
        mode: TrackingMode.balanced,
      );

      if (trackResult.isSuccess) {
        debugPrint('✅ Location tracking started successfully');
        debugPrint('   User ID: $userId');
        debugPrint('   Mode: ${TrackingMode.balanced.displayName}');

        ref.read(isTrackingProvider.notifier).state = true;
        _trackingWasActive = true; // Mark as active for lifecycle management

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📍 Pelacakan lokasi aktif'),
              duration: Duration(seconds: 2),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        debugPrint('❌ Failed to start tracking: ${trackResult.failure}');
        _trackingWasActive = false;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Gagal memulai pelacakan lokasi'),
              duration: Duration(seconds: 3),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error initializing location tracking: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializingTracking = false;
        });
      }
    }
  }

  /// Stop location tracking
  Future<void> _stopLocationTracking() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      await locationService.stopTracking();
      ref.read(isTrackingProvider.notifier).state = false;
      debugPrint('🛑 Location tracking stopped');
    } catch (e) {
      debugPrint('❌ Error stopping location tracking: $e');
    }
  }

  /// Tampilkan dialog penjelasan permission
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_on, color: AppColors.warning),
            SizedBox(width: 8),
            Text('Izin Lokasi Diperlukan'),
          ],
        ),
        content: const Text(
          'AIVIA memerlukan akses lokasi untuk:\n\n'
          '• Membantu keluarga menemukan Anda jika tersesat\n'
          '• Memberikan bantuan darurat dengan cepat\n'
          '• Melacak aktivitas harian Anda\n\n'
          'Data lokasi Anda aman dan hanya dibagikan kepada keluarga yang terdaftar.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nanti Saja'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final locationService = ref.read(locationServiceProvider);
              await locationService.openAppSettings();
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get current user ID for emergency button and recognize face
    final currentUserAsync = ref.watch(currentUserProfileProvider);
    final userId = currentUserAsync.value?.id ?? '';

    // List of screens untuk bottom navigation
    final List<Widget> screens = [
      const ActivityListScreen(),
      userId.isNotEmpty
          ? RecognizeFaceScreen(patientId: userId)
          : const Center(
              child: Text('Loading...', textAlign: TextAlign.center),
            ),
      const ProfileScreen(),
    ];

    return Stack(
      children: [
        // Main scaffold dengan bottom navigation
        Scaffold(
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: IndexedStack(
              key: ValueKey<int>(_selectedIndex),
              index: _selectedIndex,
              children: screens,
            ),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                  blurRadius: AppDimensions.elevationM,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined, size: AppDimensions.iconL),
                  activeIcon: Icon(Icons.home, size: AppDimensions.iconL),
                  label: AppStrings.navHome,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.face_outlined, size: AppDimensions.iconL),
                  activeIcon: Icon(Icons.face, size: AppDimensions.iconL),
                  label: AppStrings.navRecognizeFace,
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outlined, size: AppDimensions.iconL),
                  activeIcon: Icon(Icons.person, size: AppDimensions.iconL),
                  label: AppStrings.navProfile,
                ),
              ],
            ),
          ),
        ),

        // Draggable Emergency FAB - overlays above everything
        if (userId.isNotEmpty)
          DraggableEmergencyButton(
            patientId: userId,
            onAlertCreated: () {
              // Optional: Navigate to specific screen after alert created
              // atau refresh data jika diperlukan
            },
          ),
      ],
    );
  }
}
