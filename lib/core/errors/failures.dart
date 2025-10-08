import 'package:project_aivia/core/errors/exceptions.dart';

/// Failure classes untuk Result pattern
/// Mengkonversi Exception menjadi Failure yang user-friendly

abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => message;
}

/// Auth failures
class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});

  factory AuthFailure.fromException(AppException exception) {
    if (exception is InvalidCredentialsException) {
      return const AuthFailure(
        'Email atau password salah',
        code: 'invalid_credentials',
      );
    } else if (exception is UserAlreadyExistsException) {
      return const AuthFailure('Email sudah terdaftar', code: 'user_exists');
    } else if (exception is WeakPasswordException) {
      return const AuthFailure(
        'Password terlalu lemah. Minimal 8 karakter',
        code: 'weak_password',
      );
    } else if (exception is EmailNotConfirmedException) {
      return const AuthFailure(
        'Email belum dikonfirmasi',
        code: 'email_not_confirmed',
      );
    } else if (exception is SessionExpiredException) {
      return const AuthFailure(
        'Sesi berakhir. Login kembali',
        code: 'session_expired',
      );
    }
    return AuthFailure(exception.message, code: exception.code);
  }
}

/// Network failures
class NetworkFailure extends Failure {
  const NetworkFailure()
    : super('Tidak ada koneksi internet', code: 'network_error');
}

class ServerFailure extends Failure {
  const ServerFailure([String? message])
    : super(message ?? 'Terjadi kesalahan pada server', code: 'server_error');
}

/// Database failures
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.code});

  factory DatabaseFailure.fromException(AppException exception) {
    if (exception is RecordNotFoundException) {
      return const DatabaseFailure('Data tidak ditemukan', code: 'not_found');
    } else if (exception is PermissionDeniedException) {
      return const DatabaseFailure(
        'Anda tidak memiliki akses',
        code: 'permission_denied',
      );
    }
    return DatabaseFailure(exception.message, code: exception.code);
  }
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.code});
}

/// Unknown failure
class UnknownFailure extends Failure {
  const UnknownFailure([String? message])
    : super(message ?? 'Terjadi kesalahan', code: 'unknown');
}
