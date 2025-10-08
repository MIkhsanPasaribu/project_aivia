import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_aivia/data/models/user_profile.dart';
import 'package:project_aivia/data/repositories/auth_repository.dart';
import 'package:project_aivia/core/utils/result.dart';

/// Provider untuk AuthRepository instance
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Provider untuk auth state changes stream
/// Mendengarkan perubahan auth state dari Supabase
final authStateChangesProvider = StreamProvider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

/// Provider untuk current user profile
/// Mengambil profile lengkap user yang sedang login
final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final authRepository = ref.watch(authRepositoryProvider);
  final result = await authRepository.getCurrentProfile();
  return result.fold(onSuccess: (profile) => profile, onFailure: (_) => null);
});

/// Provider untuk auth controller
/// Menyediakan methods untuk login, register, logout
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
      return AuthController(ref.watch(authRepositoryProvider));
    });

/// Auth Controller untuk mengelola state autentikasi
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AsyncValue.data(null));

  /// Sign up user baru
  Future<Result<UserProfile>> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
  }) async {
    state = const AsyncValue.loading();

    final result = await _authRepository.signUp(
      email: email,
      password: password,
      fullName: fullName,
      role: role,
    );

    result.fold(
      onSuccess: (_) => state = const AsyncValue.data(null),
      onFailure: (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
    );

    return result;
  }

  /// Sign in user
  Future<Result<UserProfile>> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    final result = await _authRepository.signIn(
      email: email,
      password: password,
    );

    result.fold(
      onSuccess: (_) => state = const AsyncValue.data(null),
      onFailure: (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
    );

    return result;
  }

  /// Sign out user
  Future<Result<void>> signOut() async {
    state = const AsyncValue.loading();

    final result = await _authRepository.signOut();

    result.fold(
      onSuccess: (_) => state = const AsyncValue.data(null),
      onFailure: (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
    );

    return result;
  }

  /// Check if user is logged in
  bool get isLoggedIn => _authRepository.currentUser != null;
}
