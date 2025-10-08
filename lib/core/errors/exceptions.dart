/// Custom Exceptions untuk AIVIA
///
/// Digunakan untuk error handling yang lebih spesifik
library;

/// Base exception class
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => message;
}

/// Auth related exceptions
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});
}

class InvalidCredentialsException extends AuthException {
  const InvalidCredentialsException()
    : super('Email atau password salah', code: 'invalid_credentials');
}

class UserAlreadyExistsException extends AuthException {
  const UserAlreadyExistsException()
    : super('Email sudah terdaftar', code: 'user_exists');
}

class WeakPasswordException extends AuthException {
  const WeakPasswordException()
    : super(
        'Password terlalu lemah. Minimal 8 karakter',
        code: 'weak_password',
      );
}

class EmailNotConfirmedException extends AuthException {
  const EmailNotConfirmedException()
    : super(
        'Email belum dikonfirmasi. Cek inbox Anda',
        code: 'email_not_confirmed',
      );
}

class SessionExpiredException extends AuthException {
  const SessionExpiredException()
    : super(
        'Sesi Anda telah berakhir. Silakan login kembali',
        code: 'session_expired',
      );
}

/// Network related exceptions
class NetworkException extends AppException {
  const NetworkException()
    : super('Tidak ada koneksi internet', code: 'network_error');
}

class ServerException extends AppException {
  const ServerException([String? message])
    : super(message ?? 'Terjadi kesalahan pada server', code: 'server_error');
}

class TimeoutException extends AppException {
  const TimeoutException()
    : super('Koneksi timeout. Coba lagi', code: 'timeout');
}

/// Database related exceptions
class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.code, super.originalError});
}

class RecordNotFoundException extends DatabaseException {
  const RecordNotFoundException()
    : super('Data tidak ditemukan', code: 'not_found');
}

class PermissionDeniedException extends DatabaseException {
  const PermissionDeniedException()
    : super('Anda tidak memiliki akses', code: 'permission_denied');
}

/// Validation exceptions
class ValidationException extends AppException {
  const ValidationException(super.message, {super.code});
}

/// Unknown exception
class UnknownException extends AppException {
  const UnknownException([String? message])
    : super(
        message ?? 'Terjadi kesalahan yang tidak diketahui',
        code: 'unknown',
      );
}
