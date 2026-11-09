import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakdaily/core/errors/app_failure.dart';

DioException response(int status, Object? data) {
  final req = RequestOptions(path: '/x');
  return DioException(
    requestOptions: req,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(requestOptions: req, statusCode: status, data: data),
  );
}

void main() {
  test('timeouts and connection errors become NetworkFailure', () {
    final req = RequestOptions(path: '/x');
    expect(AppFailure.from(DioException(requestOptions: req, type: DioExceptionType.connectionTimeout)),
        isA<NetworkFailure>());
    expect(AppFailure.from(DioException(requestOptions: req, type: DioExceptionType.connectionError)),
        isA<NetworkFailure>());
    expect(AppFailure.from(TimeoutException('t')), isA<NetworkFailure>());
  });

  test('401 becomes UnauthenticatedFailure', () {
    expect(AppFailure.from(response(401, {'error': {'code': 'INVALID_TOKEN', 'message': 'x'}})),
        isA<UnauthenticatedFailure>());
  });

  test('reads the API v1 error envelope', () {
    final f = AppFailure.from(response(402, {
      'error': {'code': 'FREE_LIMIT_REACHED', 'message': "You've completed today's free speaking time."},
    })) as ServerFailure;
    expect(f.code, 'FREE_LIMIT_REACHED');
    expect(f.message, "You've completed today's free speaking time.");
  });

  test('reads the legacy prototype error shape', () {
    final f = AppFailure.from(response(409, {'code': 'CONCURRENT_SESSION', 'message': 'In progress.'})) as ServerFailure;
    expect(f.code, 'CONCURRENT_SESSION');
  });

  test('never surfaces non-JSON bodies or raw exception text', () {
    final f = AppFailure.from(response(502, '<html>nginx 10.0.0.3 upstream error</html>'));
    expect(f.message, isNot(contains('nginx')));
    final unknown = AppFailure.from(StateError('secret token abc123 at /internal/path'));
    expect(unknown, isA<UnexpectedFailure>());
    expect(unknown.message, isNot(contains('abc123')));
  });
}
