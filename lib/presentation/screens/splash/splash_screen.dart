import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_aivia/core/constants/app_colors.dart';
import 'package:project_aivia/core/constants/app_strings.dart';
import 'package:project_aivia/core/constants/app_dimensions.dart';
import 'package:project_aivia/presentation/providers/auth_provider.dart';
import 'package:project_aivia/presentation/providers/profile_provider.dart';
import 'package:project_aivia/data/models/user_profile.dart';

/// Splash Screen - Tampilan awal aplikasi
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateAfterDelay();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _navigateAfterDelay() async {
    // Delay 2.5 detik
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // Cek status autentikasi
    final authState = ref.read(authStateChangesProvider);

    authState.when(
      data: (user) {
        if (user != null) {
          // User sudah login, ambil profile untuk cek role
          ref.read(currentUserProfileStreamProvider).whenData((profile) {
            if (!mounted) return;

            if (profile != null) {
              // Navigate berdasarkan role
              if (profile.userRole == UserRole.patient) {
                Navigator.of(context).pushReplacementNamed('/patient/home');
              } else if (profile.userRole == UserRole.family) {
                Navigator.of(context).pushReplacementNamed('/family/home');
              } else {
                // Default ke login jika role tidak dikenali
                Navigator.of(context).pushReplacementNamed('/login');
              }
            } else {
              // Profile tidak ditemukan, arahkan ke login
              Navigator.of(context).pushReplacementNamed('/login');
            }
          });
        } else {
          // User belum login
          Navigator.of(context).pushReplacementNamed('/login');
        }
      },
      loading: () {
        // Masih loading, tunggu sebentar lalu ke login
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/login');
          }
        });
      },
      error: (error, _) {
        // Error, arahkan ke login
        Navigator.of(context).pushReplacementNamed('/login');
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: brightness == Brightness.dark
                ? [AppColors.primaryDarkerDM, AppColors.backgroundDarkDM]
                : [AppColors.primaryLight, AppColors.background],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo dengan animasi
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Hero(
                    tag: 'app_logo',
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusXXL,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (brightness == Brightness.dark
                                        ? AppColors.primaryDarkDM
                                        : AppColors.primary)
                                    .withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(AppDimensions.paddingL),
                      child: Image.asset(
                        'assets/images/logo_noname-removebg.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.paddingXL),

              // App Name
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  AppStrings.appName,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.paddingS),

              // Tagline
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  AppStrings.appTagline,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: AppDimensions.paddingXXL),

              // Loading indicator
              FadeTransition(
                opacity: _fadeAnimation,
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
