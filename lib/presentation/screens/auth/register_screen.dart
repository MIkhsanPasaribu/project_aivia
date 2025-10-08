import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_aivia/core/constants/app_colors.dart';
import 'package:project_aivia/core/constants/app_strings.dart';
import 'package:project_aivia/core/constants/app_dimensions.dart';
import 'package:project_aivia/core/utils/validators.dart';
import 'package:project_aivia/data/models/user_profile.dart';
import 'package:project_aivia/presentation/providers/auth_provider.dart';

/// Register Screen - Halaman pendaftaran akun
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  UserRole _selectedRole = UserRole.patient;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Call AuthRepository via Provider
      final result = await ref
          .read(authRepositoryProvider)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            role: _selectedRole,
          );

      if (!mounted) return;

      result.fold(
        onSuccess: (userProfile) {
          // Auto login setelah register sukses
          _autoLoginAfterRegister();
        },
        onFailure: (failure) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: AppColors.error,
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _autoLoginAfterRegister() async {
    // Login otomatis setelah register
    final result = await ref
        .read(authRepositoryProvider)
        .signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    result.fold(
      onSuccess: (userProfile) {
        // Navigate based on user role
        final route = userProfile.userRole == UserRole.patient
            ? '/patient/home'
            : '/family/home';

        Navigator.of(context).pushReplacementNamed(route);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selamat datang, ${userProfile.fullName}!'),
            backgroundColor: AppColors.success,
          ),
        );
      },
      onFailure: (failure) {
        setState(() => _isLoading = false);
        // Jika auto-login gagal, arahkan ke login screen
        Navigator.of(context).pushReplacementNamed('/login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registrasi berhasil! Silakan login.'),
            backgroundColor: AppColors.success,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.paddingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title
                Text(
                  AppStrings.registerTitle,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: AppDimensions.paddingXL),

                // Full Name Field
                TextFormField(
                  controller: _fullNameController,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: AppStrings.fullName,
                    hintText: 'Masukkan nama lengkap',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  validator: Validators.validateName,
                ),

                const SizedBox(height: AppDimensions.paddingM),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  decoration: const InputDecoration(
                    labelText: AppStrings.email,
                    hintText: 'contoh@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: Validators.validateEmail,
                ),

                const SizedBox(height: AppDimensions.paddingM),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: AppStrings.password,
                    hintText: 'Minimal 8 karakter',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: Validators.validatePassword,
                ),

                const SizedBox(height: AppDimensions.paddingM),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: AppStrings.confirmPassword,
                    hintText: 'Masukkan ulang kata sandi',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) => Validators.validateConfirmPassword(
                    value,
                    _passwordController.text,
                  ),
                ),

                const SizedBox(height: AppDimensions.paddingL),

                // User Role Selection
                Container(
                  padding: const EdgeInsets.all(AppDimensions.paddingM),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.userRole,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: AppDimensions.paddingS),
                      // Custom radio buttons without deprecated widgets
                      _buildRoleOption(
                        UserRole.patient,
                        AppStrings.rolePatient,
                        Icons.person,
                      ),
                      const SizedBox(height: 8),
                      _buildRoleOption(
                        UserRole.family,
                        AppStrings.roleFamily,
                        Icons.family_restroom,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppDimensions.paddingL),

                // Register Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(
                      AppDimensions.buttonHeightL,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textPrimary,
                            ),
                          ),
                        )
                      : const Text(AppStrings.registerButton),
                ),

                const SizedBox(height: AppDimensions.paddingM),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.haveAccount,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(width: AppDimensions.paddingS),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text(AppStrings.loginHere),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build custom role selection option (tanpa deprecated Radio widget)
  Widget _buildRoleOption(UserRole role, String label, IconData icon) {
    final isSelected = _selectedRole == role;
    return InkWell(
      onTap: _isLoading
          ? null
          : () {
              setState(() {
                _selectedRole = role;
              });
            },
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Custom radio indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textTertiary,
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: AppDimensions.paddingM),
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppDimensions.paddingS),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
