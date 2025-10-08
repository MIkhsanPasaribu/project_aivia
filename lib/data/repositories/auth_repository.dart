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
  /// 1. Signup ke Supabase Auth (with email confirmation disabled for dev)
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
      // emailRedirectTo: null to disable email confirmation in development
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'user_role': role.value},
        emailRedirectTo: null, // Disable email confirmation
      );

      if (response.user == null) {
        throw const AuthException('Gagal membuat akun');
      }

      // 2. Wait for trigger to create profile
      await Future.delayed(const Duration(milliseconds: 1500));

      // 3. Fetch created profile with retry mechanism (exponential backoff)
      UserProfile? profile;
      int retries = 5;
      int delayMs = 500;

      while (retries > 0 && profile == null) {
        try {
          final profileData = await _supabase
              .from('profiles')
              .select()
              .eq('id', response.user!.id)
              .single();

          profile = UserProfile.fromJson(profileData);
        } on PostgrestException catch (e) {
          // PGRST116 means no rows returned
          if (e.code == 'PGRST116' && retries > 0) {
            retries--;
            if (retries > 0) {
              await Future.delayed(Duration(milliseconds: delayMs));
              delayMs = (delayMs * 1.5).toInt(); // Exponential backoff
            }
          } else {
            rethrow;
          }
        } catch (e) {
          retries--;
          if (retries > 0) {
            await Future.delayed(Duration(milliseconds: delayMs));
            delayMs = (delayMs * 1.5).toInt(); // Exponential backoff
          } else {
            rethrow;
          }
        }
      }

      if (profile == null) {
        throw const DatabaseException('Profile tidak dapat dibuat');
      }

      return Success(profile);
    } on AuthException catch (e) {
      // Handle rate limit error
      if (e.message.contains('429') ||
          e.message.contains('rate') ||
          e.message.contains('email_send_rate_limit')) {
        return const ResultFailure(
          AuthFailure(
            'Terlalu banyak permintaan. Silakan tunggu beberapa saat dan coba lagi.',
            code: 'rate_limit',
          ),
        );
      } else if (e.message.contains('already registered') ||
          e.message.contains('already been registered')) {
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
      } else if (e.message.contains('email')) {
        return const ResultFailure(
          AuthFailure('Format email tidak valid', code: 'invalid_email'),
        );
      }
      return ResultFailure(
        AuthFailure('Gagal membuat akun: ${e.message}', code: e.code),
      );
    } on PostgrestException catch (e) {
      return ResultFailure(
        DatabaseFailure('Database error: ${e.message}', code: e.code),
      );
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

  /// Force sign out (untuk timeout atau error)
  /// Logout secara lokal tanpa call ke server
  Future<Result<void>> forceSignOut() async {
    try {
      // Clear local session without server call
      await _supabase.auth.signOut(scope: SignOutScope.local);
      return const Success(null);
    } catch (e) {
      return ResultFailure(
        UnknownFailure('Gagal force logout: ${e.toString()}'),
      );
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
