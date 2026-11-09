import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

/// A failure that is safe to show to the user.
///
/// Raw exceptions (`$e`) must never be rendered: they can contain URLs, tokens,
/// server internals or stack traces. Convert with [AppFailure.from] and show
/// [message]; report the original error through `ErrorReporter`.
sealed class AppFailure implements Exception {
  const AppFailure(this.message);

  final String message;

  factory AppFailure.from(Object error) {
    if (error is AppFailure) return error;
    if (error is TimeoutException || error is SocketException) return const NetworkFailure();
    if (error is DioException) return _fromDio(error);
    return const UnexpectedFailure();
  }

  static AppFailure _fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.cancel:
        return const CancelledFailure();
      case DioExceptionType.badCertificate:
        return const UnexpectedFailure();
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break;
    }
    final status = e.response?.statusCode;
    if (status == null) {
      return e.error is SocketException ? const NetworkFailure() : const UnexpectedFailure();
    }
    final (code, serverMessage) = _serverError(e.response?.data);
    if (status == 401) return const UnauthenticatedFailure();
    return ServerFailure(
      statusCode: status,
      code: code,
      // Our backend's error messages are written for end users; anything else
      // (proxies, HTML error pages) falls back to a generic message.
      message: serverMessage ?? 'Something went wrong on our side. Please try again.',
    );
  }

  /// Reads `{error: {code, message}}` (API v1) or `{code, message}` (legacy prototype).
  static (String?, String?) _serverError(Object? data) {
    if (data is! Map) return (null, null);
    final envelope = data['error'] is Map ? data['error'] as Map : data;
    final code = envelope['code'];
    final message = envelope['message'];
    return (
      code is String ? code : null,
      message is String && message.isNotEmpty && message.length <= 300 ? message : null,
    );
  }
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure() : super("You're offline. Check your connection and try again.");
}

final class UnauthenticatedFailure extends AppFailure {
  const UnauthenticatedFailure() : super('Your session has expired. Please sign in again.');
}

final class CancelledFailure extends AppFailure {
  const CancelledFailure() : super('The request was cancelled.');
}

final class ServerFailure extends AppFailure {
  const ServerFailure({required this.statusCode, this.code, required String message}) : super(message);

  final int statusCode;

  /// Machine-readable code from the backend, e.g. `FREE_LIMIT_REACHED`.
  final String? code;
}

final class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure() : super('Something went wrong. Please try again.');
}
