import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/services/api_client.dart';

/// Thrown when the backend needs a fresh sign-in before a sensitive operation.
class ReauthRequiredFailure implements Exception {
  const ReauthRequiredFailure();
}

/// Account lifecycle on the backend. Always the signed-in user: the backend derives
/// the uid from the ID token and never accepts one from the client.
abstract interface class AccountRepository {
  /// Permanently deletes the account and all learning data (`DELETE /api/v1/me`).
  /// Requires a sign-in within the last few minutes ([ReauthRequiredFailure] otherwise).
  Future<void> deleteAccount();
}

class ApiAccountRepository implements AccountRepository {
  ApiAccountRepository(this._dio);

  final Dio _dio;

  @override
  Future<void> deleteAccount() async {
    try {
      await _dio.delete<void>('/api/v1/me');
    } catch (e) {
      final failure = AppFailure.from(e);
      if (failure is ServerFailure && failure.code == 'REAUTH_REQUIRED') throw const ReauthRequiredFailure();
      throw failure;
    }
  }
}

final accountRepositoryProvider = Provider<AccountRepository>((ref) => ApiAccountRepository(ref.watch(apiClientProvider)));
