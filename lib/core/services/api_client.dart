import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_repository.dart';
import '../config/app_config.dart';

/// Shared HTTP client for the Sprelia backend.
///
/// - Attaches `Authorization: Bearer <Firebase ID token>` when signed in.
/// - On a 401 it refreshes the token once and retries the request once.
/// - Never logs headers or bodies.
/// - Sends `X-Firebase-AppCheck` when App Check is active (Phase 3).
final apiClientProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final auth = ref.watch(authRepositoryProvider);
  final dio = Dio(BaseOptions(
    baseUrl: config.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'accept': 'application/json'},
  ));

  dio.interceptors.add(AuthTokenInterceptor(auth, dio));
  dio.interceptors.add(AppCheckInterceptor(ref.watch(appCheckTokenProvider)));

  // LEGACY PROTOTYPE ONLY: the Express prototype trusts this header when it runs
  // with DEV_SKIP_AUTH=true. `devUserId` is null outside development, so the
  // header can never be sent by staging or production builds.
  final devUserId = config.devUserId;
  if (devUserId != null) {
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      options.headers['x-dev-user-id'] = devUserId;
      handler.next(options);
    }));
  }

  ref.onDispose(dio.close);
  return dio;
});

/// App Check token source; overridden in `main.dart` when App Check is active.
final appCheckTokenProvider = Provider<Future<String?> Function()>((ref) => () async => null);

/// Adds the App Check token. A missing token is not an error here: the backend's
/// APP_CHECK_MODE decides whether such requests are allowed. Tokens are never logged.
class AppCheckInterceptor extends Interceptor {
  AppCheckInterceptor(this._token);

  final Future<String?> Function() _token;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final token = await _token();
      if (token != null && token.isNotEmpty) options.headers['x-firebase-appcheck'] = token;
    } catch (_) {
      // Unavailable (e.g. unregistered debug token): send without it.
    }
    handler.next(options);
  }
}

class AuthTokenInterceptor extends QueuedInterceptor {
  AuthTokenInterceptor(this._auth, this._dio);

  final AuthRepository _auth;
  final Dio _dio;
  static const _retriedKey = 'auth_retried';

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final token = await _auth.idToken();
      if (token != null) options.headers['authorization'] = 'Bearer $token';
    } catch (_) {
      // No token available: the request proceeds unauthenticated and the
      // backend answers 401, which the UI handles.
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    if (err.response?.statusCode != 401 || options.extra[_retriedKey] == true) {
      return handler.next(err);
    }
    try {
      final token = await _auth.idToken(forceRefresh: true);
      if (token == null) return handler.next(err);
      options.extra[_retriedKey] = true;
      options.headers['authorization'] = 'Bearer $token';
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (e) {
      handler.next(e);
    } catch (_) {
      handler.next(err);
    }
  }
}
