import 'package:dio/dio.dart';

/// Domain-level exception the repository layer throws.
/// Keeps Dio internals out of providers and UI.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.cause});

  final String message;
  final int? statusCode;
  final Object? cause;

  /// Maps a raw [DioException] into a friendly, typed [ApiException].
  factory ApiException.fromDio(DioException e) {
    final status = e.response?.statusCode;
    final message = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Connection timed out. Check your network and try again.',
      DioExceptionType.badResponse => switch (status) {
          400 => 'Bad request.',
          401 => 'Your session has expired. Please sign in again.',
          403 => 'You don\'t have access to this.',
          404 => 'We couldn\'t find what you were looking for.',
          final s? when s >= 500 =>
            'Something went wrong on our end. Try again shortly.',
          _ => 'Unexpected server response.',
        },
      DioExceptionType.cancel => 'Request was cancelled.',
      DioExceptionType.connectionError =>
        'No internet connection. Check your network.',
      _ => 'Something went wrong. Please try again.',
    };
    return ApiException(message, statusCode: status, cause: e);
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
