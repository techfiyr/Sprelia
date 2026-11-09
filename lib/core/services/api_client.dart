import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';

final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
  ));
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    // TODO(auth): replace with the Firebase ID token once Firebase Auth is wired up.
    options.headers['x-dev-user-id'] = AppConfig.devUserId;
    handler.next(options);
  }));
  return dio;
});
