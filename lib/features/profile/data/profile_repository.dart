import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/services/api_client.dart';
import 'profile_models.dart';

/// Profile, onboarding and dashboard data. Always for the signed-in user:
/// the backend derives the uid from the ID token.
abstract interface class ProfileRepository {
  /// Null when the profile has not been created yet.
  Future<UserProfile?> getProfile();
  Future<UserProfile> createProfile({required String timezone, String? displayName});
  Future<(UserProfile, LearningPlan?)> saveOnboarding(LearningPreferences preferences, {required bool complete});
  Future<Dashboard> getDashboard();
}

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this._dio);

  final Dio _dio;

  Future<T> _call<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  @override
  Future<UserProfile?> getProfile() async {
    try {
      final res = await _dio.get<Map<String, Object?>>('/api/v1/me/profile');
      return UserProfile.fromJson((res.data!['profile']! as Map).cast<String, Object?>());
    } catch (e) {
      final failure = AppFailure.from(e);
      if (failure is ServerFailure && failure.code == 'PROFILE_NOT_FOUND') return null;
      throw failure;
    }
  }

  @override
  Future<UserProfile> createProfile({required String timezone, String? displayName}) => _call(() async {
        final res = await _dio.post<Map<String, Object?>>('/api/v1/me/profile', data: {
          'timezone': timezone,
          if (displayName != null && displayName.trim().isNotEmpty) 'displayName': displayName.trim(),
        });
        return UserProfile.fromJson((res.data!['profile']! as Map).cast<String, Object?>());
      });

  @override
  Future<(UserProfile, LearningPlan?)> saveOnboarding(LearningPreferences preferences, {required bool complete}) =>
      _call(() async {
        final res = await _dio.put<Map<String, Object?>>('/api/v1/me/onboarding', data: {
          'preferences': preferences.toJson(),
          'complete': complete,
        });
        final plan = res.data!['plan'];
        return (
          UserProfile.fromJson((res.data!['profile']! as Map).cast<String, Object?>()),
          plan is Map ? LearningPlan.fromJson(plan.cast<String, Object?>()) : null,
        );
      });

  @override
  Future<Dashboard> getDashboard() => _call(() async {
        final res = await _dio.get<Map<String, Object?>>('/api/v1/me/dashboard');
        return Dashboard.fromJson((res.data!['dashboard']! as Map).cast<String, Object?>());
      });
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => ApiProfileRepository(ref.watch(apiClientProvider)));

/// Home dashboard for the signed-in user. Refresh with `ref.invalidate`.
final dashboardProvider = FutureProvider.autoDispose<Dashboard>((ref) => ref.watch(profileRepositoryProvider).getDashboard());
