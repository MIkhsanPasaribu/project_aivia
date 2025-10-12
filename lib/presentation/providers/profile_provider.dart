import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_aivia/data/models/user_profile.dart';
import 'package:project_aivia/data/repositories/profile_repository.dart';
import 'package:project_aivia/core/utils/result.dart';
import 'package:project_aivia/core/errors/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provider untuk ProfileRepository instance
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

/// Provider untuk current user profile dengan auto-refresh
/// Menggunakan StreamProvider untuk real-time updates via Supabase Realtime
final currentUserProfileStreamProvider = StreamProvider<UserProfile?>((
  ref,
) async* {
  final profileRepository = ref.watch(profileRepositoryProvider);
  final user = Supabase.instance.client.auth.currentUser;

  if (user == null) {
    yield null;
    return;
  }

  // Get initial profile
  final result = await profileRepository.getCurrentUserProfile();

  if (result is Success<UserProfile>) {
    yield result.data;

    // Realtime subscription untuk auto-update
    final stream = Supabase.instance.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .map((data) {
          if (data.isEmpty) return null;
          return UserProfile.fromJson(data.first);
        });

    yield* stream;
  } else {
    yield null;
  }
});

/// Provider untuk get profile by ID
/// Useful untuk family members melihat patient profile
final profileByIdProvider = FutureProvider.family<UserProfile?, String>((
  ref,
  userId,
) async {
  final profileRepository = ref.watch(profileRepositoryProvider);
  final result = await profileRepository.getProfile(userId);
  return result.fold(onSuccess: (profile) => profile, onFailure: (_) => null);
});

/// Provider untuk profile controller
/// Menyediakan methods untuk update profile, upload/delete avatar
final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<UserProfile?>>((ref) {
      return ProfileController(ref.watch(profileRepositoryProvider));
    });

/// Profile Controller untuk mengelola state profile operations
class ProfileController extends StateNotifier<AsyncValue<UserProfile?>> {
  final ProfileRepository _profileRepository;

  ProfileController(this._profileRepository)
    : super(const AsyncValue.loading()) {
    // Load initial profile
    _loadProfile();
  }

  /// Load current user profile
  Future<void> _loadProfile() async {
    state = const AsyncValue.loading();

    final result = await _profileRepository.getCurrentUserProfile();

    state = result.fold(
      onSuccess: (profile) => AsyncValue.data(profile),
      onFailure: (failure) =>
          AsyncValue.error(failure.message, StackTrace.current),
    );
  }

  /// Refresh profile data
  Future<void> refreshProfile() async {
    await _loadProfile();
  }

  /// Update profile fields (without avatar)
  Future<Result<UserProfile>> updateProfile({
    String? fullName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? address,
  }) async {
    // Get current user ID
    final currentProfile = state.value;
    if (currentProfile == null) {
      return ResultFailure(ValidationFailure('Profile tidak ditemukan'));
    }

    // Validate data
    final validationError = _profileRepository.validateProfileData(
      fullName: fullName,
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
    );

    if (validationError != null) {
      return ResultFailure(ValidationFailure(validationError));
    }

    // Set loading state
    state = const AsyncValue.loading();

    // Update profile
    final result = await _profileRepository.updateProfile(
      userId: currentProfile.id,
      fullName: fullName,
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
      address: address,
    );

    // Update state based on result
    state = result.fold(
      onSuccess: (updatedProfile) => AsyncValue.data(updatedProfile),
      onFailure: (failure) =>
          AsyncValue.error(failure.message, StackTrace.current),
    );

    return result;
  }

  /// Upload/Update avatar
  Future<Result<String>> uploadAvatar({required ImageSource source}) async {
    // Get current user ID
    final currentProfile = state.value;
    if (currentProfile == null) {
      return ResultFailure(ValidationFailure('Profile tidak ditemukan'));
    }

    // Set loading state (keep current data)
    state = AsyncValue.data(currentProfile);

    // Upload avatar
    final result = await _profileRepository.uploadAvatar(
      userId: currentProfile.id,
      source: source,
    );

    // Refresh profile after upload
    if (result is Success) {
      await _loadProfile();
    }

    return result;
  }

  /// Delete avatar
  Future<Result<void>> deleteAvatar() async {
    // Get current user ID
    final currentProfile = state.value;
    if (currentProfile == null) {
      return ResultFailure(ValidationFailure('Profile tidak ditemukan'));
    }

    // Set loading state (keep current data)
    state = AsyncValue.data(currentProfile);

    // Delete avatar
    final result = await _profileRepository.deleteAvatar(currentProfile.id);

    // Refresh profile after delete
    if (result is Success) {
      await _loadProfile();
    }

    return result;
  }

  /// Update profile with avatar in one call
  /// Convenience method untuk update semua sekaligus
  Future<Result<UserProfile>> updateProfileWithAvatar({
    String? fullName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? address,
    ImageSource? avatarSource,
  }) async {
    // Get current user ID
    final currentProfile = state.value;
    if (currentProfile == null) {
      return ResultFailure(ValidationFailure('Profile tidak ditemukan'));
    }

    // Validate data
    final validationError = _profileRepository.validateProfileData(
      fullName: fullName,
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
    );

    if (validationError != null) {
      return ResultFailure(ValidationFailure(validationError));
    }

    // Set loading state
    state = const AsyncValue.loading();

    // Update profile with avatar
    final result = await _profileRepository.updateProfileWithAvatar(
      userId: currentProfile.id,
      fullName: fullName,
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
      address: address,
      avatarSource: avatarSource,
    );

    // Update state based on result
    state = result.fold(
      onSuccess: (updatedProfile) => AsyncValue.data(updatedProfile),
      onFailure: (failure) =>
          AsyncValue.error(failure.message, StackTrace.current),
    );

    return result;
  }
}

/// Helper extension untuk validation
extension ProfileValidationExtension on ProfileController {
  /// Validate full name
  String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama lengkap tidak boleh kosong';
    }
    if (value.trim().length < 3) {
      return 'Nama lengkap minimal 3 karakter';
    }
    return null;
  }

  /// Validate phone number (Indonesia format)
  String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }

    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length < 10 || digitsOnly.length > 13) {
      return 'Nomor telepon harus 10-13 digit';
    }

    if (!digitsOnly.startsWith('0') && !digitsOnly.startsWith('62')) {
      return 'Nomor telepon harus diawali 0 atau 62';
    }

    return null;
  }

  /// Validate date of birth
  String? validateDateOfBirth(DateTime? value) {
    if (value == null) {
      return null; // Optional field
    }

    final now = DateTime.now();
    final age = now.year - value.year;

    if (value.isAfter(now)) {
      return 'Tanggal lahir tidak valid';
    }

    if (age < 5) {
      return 'Umur minimal 5 tahun';
    }

    if (age > 120) {
      return 'Tanggal lahir tidak valid';
    }

    return null;
  }
}
