import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';

/// Shared HTTP client for the Sprelia backend.
///
/// Phase 4 adds an interceptor that attaches `Authorization: Bearer <Firebase ID
/// token>` (and the App Check token) and refreshes on 401. Never log request
/// headers or bodies from this client.
final apiClientProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final dio = Dio(BaseOptions(
    baseUrl: config.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
    headers: {'accept': 'application/json'},
  ));

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
