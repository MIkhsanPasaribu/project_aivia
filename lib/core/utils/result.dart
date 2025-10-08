import 'package:project_aivia/core/errors/failures.dart';

/// Result pattern untuk error handling yang type-safe
/// Menggunakan sealed class untuk exhaustive checking

sealed class Result<T> {
  const Result();

  /// Berhasil dengan data
  bool get isSuccess => this is Success<T>;

  /// Gagal dengan error
  bool get isFailure => this is ResultFailure<T>;

  /// Get data jika success, throw jika failure
  T get data {
    if (this is Success<T>) {
      return (this as Success<T>).data;
    }
    throw Exception('Called data on Failure');
  }

  /// Get failure jika failure, throw jika success
  Failure get failure {
    if (this is ResultFailure<T>) {
      return (this as ResultFailure<T>).failure;
    }
    throw Exception('Called failure on Success');
  }

  /// Fold pattern untuk handling both cases
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    if (this is Success<T>) {
      return onSuccess((this as Success<T>).data);
    } else {
      return onFailure((this as ResultFailure<T>).failure);
    }
  }

  /// Map data jika success
  Result<R> map<R>(R Function(T data) mapper) {
    if (this is Success<T>) {
      return Success(mapper((this as Success<T>).data));
    } else {
      return ResultFailure((this as ResultFailure<T>).failure);
    }
  }

  /// FlatMap untuk chaining operations
  Future<Result<R>> flatMap<R>(
    Future<Result<R>> Function(T data) mapper,
  ) async {
    if (this is Success<T>) {
      return mapper((this as Success<T>).data);
    } else {
      return ResultFailure((this as ResultFailure<T>).failure);
    }
  }
}

/// Success case
class Success<T> extends Result<T> {
  @override
  final T data;

  const Success(this.data);

  @override
  String toString() => 'Success($data)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Success<T> && other.data == data;
  }

  @override
  int get hashCode => data.hashCode;
}

/// Failure case (renamed from Failure to avoid conflict)
class ResultFailure<T> extends Result<T> {
  @override
  final Failure failure;

  const ResultFailure(this.failure);

  @override
  String toString() => 'Failure($failure)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ResultFailure<T> && other.failure == failure;
  }

  @override
  int get hashCode => failure.hashCode;
}
