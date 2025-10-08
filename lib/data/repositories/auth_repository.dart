import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;
import 'package:project_aivia/core/errors/exceptions.dart';
import 'package:project_aivia/core/errors/failures.dart';
import 'package:project_aivia/core/utils/result.dart';
import 'package:project_aivia/data/models/user_profile.dart';

/// Repository untuk manajemen autentikasi
/// Menggunakan Supabase Auth + custom profiles table
class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  /// Stream untuk mendengarkan perubahan auth state
  Stream<User?> get authStateChanges {
    return _supabase.auth.onAuthStateChange.map((event) => event.session?.user);
  }

  /// Get current logged in user
  User? get currentUser => _supabase.auth.currentUser;

  /// Register user baru
  ///
  /// Process:
  /// 1. Signup ke Supabase Auth
  /// 2. Trigger database akan auto-create profile
  /// 3. Fetch profile yang baru dibuat
  Future<Result<UserProfile>> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    try {
      // 1. Signup to Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'user_role': role.value},
      );

      if (response.user == null) {
        throw const AuthException('Gagal membuat akun');
      }

      // 2. Wait a bit for trigger to create profile
      await Future.delayed(const Duration(milliseconds: 500));

      // 3. Fetch created profile
      final profileData = await _supabase
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .single();

      final profile = UserProfile.fromJson(profileData);

      return Success(profile);
    } on AuthException catch (e) {
      if (e.message.contains('already registered')) {
        return const ResultFailure(
          AuthFailure('Email sudah terdaftar', code: 'user_exists'),
        );
      } else if (e.message.contains('password')) {
        return const ResultFailure(
          AuthFailure(
            'Password terlalu lemah. Minimal 8 karakter',
            code: 'weak_password',
          ),
        );
      }
      return ResultFailure(AuthFailure(e.message, code: e.code));
    } on PostgrestException catch (e) {
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(
        UnknownFailure('Gagal membuat akun: ${e.toString()}'),
      );
    }
  }

  /// Login user
  ///
  /// Process:
  /// 1. SignIn ke Supabase Auth
  /// 2. Fetch profile dari database
  Future<Result<UserProfile>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Sign in to Supabase Auth
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const InvalidCredentialsException();
      }

      // 2. Fetch user profile
      final profileData = await _supabase
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .single();

      final profile = UserProfile.fromJson(profileData);

      return Success(profile);
    } on AuthException catch (e) {
      if (e.message.contains('Invalid login credentials')) {
        return const ResultFailure(
          AuthFailure('Email atau password salah', code: 'invalid_credentials'),
        );
      } else if (e.message.contains('Email not confirmed')) {
        return const ResultFailure(
          AuthFailure('Email belum dikonfirmasi', code: 'email_not_confirmed'),
        );
      }
      return ResultFailure(AuthFailure(e.message, code: e.code));
    } on PostgrestException catch (e) {
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(UnknownFailure('Gagal login: ${e.toString()}'));
    }
  }

  /// Logout user
  Future<Result<void>> signOut() async {
    try {
      await _supabase.auth.signOut();
      return const Success(null);
    } on AuthException catch (e) {
      return ResultFailure(AuthFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(UnknownFailure('Gagal logout: ${e.toString()}'));
    }
  }

  /// Get current user profile
  Future<Result<UserProfile>> getCurrentProfile() async {
    try {
      final user = currentUser;
      if (user == null) {
        return const ResultFailure(
          AuthFailure('User tidak login', code: 'not_logged_in'),
        );
      }

      final profileData = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      final profile = UserProfile.fromJson(profileData);

      return Success(profile);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return const ResultFailure(
          DatabaseFailure('Profile tidak ditemukan', code: 'not_found'),
        );
      }
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(
        UnknownFailure('Gagal mengambil profile: ${e.toString()}'),
      );
    }
  }

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Get current user ID
  String? get currentUserId => currentUser?.id;

  /// Update user profile
  Future<Result<UserProfile>> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? address,
    DateTime? dateOfBirth,
    String? avatarUrl,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return const ResultFailure(
          AuthFailure('User tidak login', code: 'not_logged_in'),
        );
      }

      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (address != null) updates['address'] = address;
      if (dateOfBirth != null) {
        updates['date_of_birth'] = dateOfBirth.toIso8601String();
      }
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isEmpty) {
        return getCurrentProfile();
      }

      await _supabase.from('profiles').update(updates).eq('id', user.id);

      return getCurrentProfile();
    } on PostgrestException catch (e) {
      return ResultFailure(DatabaseFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(
        UnknownFailure('Gagal update profile: ${e.toString()}'),
      );
    }
  }

  /// Change password
  Future<Result<void>> changePassword({required String newPassword}) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
      return const Success(null);
    } on AuthException catch (e) {
      return ResultFailure(AuthFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(
        UnknownFailure('Gagal ubah password: ${e.toString()}'),
      );
    }
  }

  /// Request password reset email
  Future<Result<void>> resetPasswordRequest(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return const Success(null);
    } on AuthException catch (e) {
      return ResultFailure(AuthFailure(e.message, code: e.code));
    } catch (e) {
      return ResultFailure(
        UnknownFailure('Gagal kirim email reset: ${e.toString()}'),
      );
    }
  }
}
