import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_aivia/core/utils/result.dart';
import 'package:project_aivia/core/errors/failures.dart';
import 'package:project_aivia/data/models/user_profile.dart';
import 'package:project_aivia/data/services/image_upload_service.dart';
import 'package:image_picker/image_picker.dart';

/// Repository untuk manage user profile data
/// Handles CRUD operations untuk profiles table di Supabase
class ProfileRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImageUploadService _imageUploadService = ImageUploadService();

  /// Get profile by user ID
  Future<Result<UserProfile>> getProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      final profile = UserProfile.fromJson(response);
      return Success(profile);
    } on PostgrestException catch (e) {
      return ResultFailure(
        DatabaseFailure('Gagal mengambil profil: ${e.message}'),
      );
    } catch (e) {
      return ResultFailure(
        UnknownFailure('Gagal mengambil profil: ${e.toString()}'),
      );
    }
  }

  /// Get current user's profile
  Future<Result<UserProfile>> getCurrentUserProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return const ResultFailure(
          AuthFailure('User belum login'),
        );
      }

      return await getProfile(user.id);
    } catch (e) {
      return ResultFailure(
        UnknownFailure('Gagal mengambil profil: ${e.toString()}'),
      );
    }
  }

  /// Update profile data (without avatar)
  /// Updates: full_name, phone_number, date_of_birth, address
  Future<Result<UserProfile>> updateProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? address,
  }) async {
    try {
      // Validate at least one field is being updated
      if (fullName == null &&
          phoneNumber == null &&
          dateOfBirth == null &&
          address == null) {
        return const ResultFailure(
          ValidationFailure('Tidak ada data yang diubah'),
        );
      }

      // Build update map (only include non-null values)
      final Map<String, dynamic> updates = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updates['full_name'] = fullName;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (dateOfBirth != null) {
        updates['date_of_birth'] = dateOfBirth.toIso8601String().split('T')[0];
      }
      if (address != null) updates['address'] = address;

      // Update database
      final response = await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      final updatedProfile = UserProfile.fromJson(response);
      return Success(updatedProfile);
    } on PostgrestException catch (e) {
      return ResultFailure(
        DatabaseFailure('Gagal update profil: ${e.message}'),
      );
    } catch (e) {
      return ResultFailure(
        UnknownFailure('Gagal update profil: ${e.toString()}'),
      );
    }
  }

  /// Upload/Update avatar with complete flow
  /// Picks image, crops, resizes, uploads, and updates profile
  Future<Result<String>> uploadAvatar({
    required String userId,
    required ImageSource source,
  }) async {
    try {
      // Use ImageUploadService untuk full flow
      final uploadResult = await _imageUploadService.pickCropAndUpload(
        userId: userId,
        source: source,
      );

      if (uploadResult is ResultFailure) {
        return uploadResult;
      }

      final avatarUrl = (uploadResult as Success<String>).data;

      // Update profile dengan avatar URL
      await _supabase
          .from('profiles')
          .update({
            'avatar_url': avatarUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      return Success(avatarUrl);
    } on PostgrestException catch (e) {
      return ResultFailure(
        DatabaseFailure('Gagal update avatar: ${e.message}'),
      );
    } catch (e) {
      return ResultFailure(
        UnknownFailure('Gagal upload avatar: ${e.toString()}'),
      );
    }
  }

  /// Delete avatar
  Future<Result<void>> deleteAvatar(String userId) async {
    try {
      // Delete dari storage
      final deleteResult = await _imageUploadService.deleteFromStorage(userId);

      if (deleteResult is ResultFailure) {
        return deleteResult;
      }

      // Update profile (set avatar_url to null)
      await _supabase
          .from('profiles')
          .update({
            'avatar_url': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      return const Success(null);
    } on PostgrestException catch (e) {
      return ResultFailure(
        DatabaseFailure('Gagal hapus avatar: ${e.message}'),
      );
    } catch (e) {
      return ResultFailure(
        UnknownFailure('Gagal hapus avatar: ${e.toString()}'),
      );
    }
  }

  /// Update profile dengan avatar dalam satu call
  /// Convenience method untuk update profile + avatar sekaligus
  Future<Result<UserProfile>> updateProfileWithAvatar({
    required String userId,
    String? fullName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? address,
    ImageSource? avatarSource,
  }) async {
    try {
      // 1. Update avatar jika ada
      String? newAvatarUrl;
      if (avatarSource != null) {
        final avatarResult = await uploadAvatar(
          userId: userId,
          source: avatarSource,
        );

        if (avatarResult is ResultFailure) {
          return ResultFailure(avatarResult.failure);
        }
        newAvatarUrl = (avatarResult as Success<String>).data;
      }

      // 2. Update profile fields
      final Map<String, dynamic> updates = {
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (fullName != null) updates['full_name'] = fullName;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (dateOfBirth != null) {
        updates['date_of_birth'] = dateOfBirth.toIso8601String().split('T')[0];
      }
      if (address != null) updates['address'] = address;
      if (newAvatarUrl != null) updates['avatar_url'] = newAvatarUrl;

      final response = await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      final updatedProfile = UserProfile.fromJson(response);
      return Success(updatedProfile);
    } on PostgrestException catch (e) {
      return ResultFailure(
        DatabaseFailure('Gagal update profil: ${e.message}'),
      );
    } catch (e) {
      return ResultFailure(
        UnknownFailure('Gagal update profil: ${e.toString()}'),
      );
    }
  }

  /// Validate profile data
  /// Returns error message jika ada validation error, null jika valid
  String? validateProfileData({
    String? fullName,
    String? phoneNumber,
    DateTime? dateOfBirth,
  }) {
    // Validate full name
    if (fullName != null) {
      if (fullName.trim().isEmpty) {
        return 'Nama lengkap tidak boleh kosong';
      }
      if (fullName.trim().length < 3) {
        return 'Nama lengkap minimal 3 karakter';
      }
    }

    // Validate phone number (Indonesia format)
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      // Remove all non-digit characters
      final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');

      if (digitsOnly.length < 10 || digitsOnly.length > 13) {
        return 'Nomor telepon harus 10-13 digit';
      }

      // Must start with 0 or 62
      if (!digitsOnly.startsWith('0') && !digitsOnly.startsWith('62')) {
        return 'Nomor telepon harus diawali 0 atau 62';
      }
    }

    // Validate date of birth
    if (dateOfBirth != null) {
      final now = DateTime.now();
      final age = now.year - dateOfBirth.year;

      if (dateOfBirth.isAfter(now)) {
        return 'Tanggal lahir tidak valid';
      }

      if (age < 5) {
        return 'Umur minimal 5 tahun';
      }

      if (age > 120) {
        return 'Tanggal lahir tidak valid';
      }
    }

    return null; // All validations passed
  }
}
