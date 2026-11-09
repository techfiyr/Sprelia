import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/services/api_client.dart';

enum Plan { free, premium }

/// The server-verified subscription (GET /me/subscription). The app never decides entitlement.
class SubscriptionInfo {
  const SubscriptionInfo({required this.plan, required this.dailyAllowanceSeconds, this.expiresAt, this.store});

  final Plan plan;
  final int dailyAllowanceSeconds;
  final DateTime? expiresAt;
  final String? store;

  bool get isPremium => plan == Plan.premium;

  factory SubscriptionInfo.fromJson(Map<String, Object?> j) => SubscriptionInfo(
        plan: j['plan'] == 'premium' ? Plan.premium : Plan.free,
        dailyAllowanceSeconds: (j['dailyAllowanceSeconds'] as int?) ?? 600,
        expiresAt: j['expiresAt'] is String ? DateTime.tryParse(j['expiresAt']! as String) : null,
        store: j['store'] as String?,
      );
}

abstract interface class SubscriptionRepository {
  Future<SubscriptionInfo> getSubscription();
}

class ApiSubscriptionRepository implements SubscriptionRepository {
  ApiSubscriptionRepository(this._dio);
  final Dio _dio;

  @override
  Future<SubscriptionInfo> getSubscription() async {
    try {
      final res = await _dio.get<Map<String, Object?>>('/api/v1/me/subscription');
      return SubscriptionInfo.fromJson((res.data!['subscription']! as Map).cast<String, Object?>());
    } catch (e) {
      throw AppFailure.from(e);
    }
  }
}

final subscriptionRepositoryProvider =
    Provider<SubscriptionRepository>((ref) => ApiSubscriptionRepository(ref.watch(apiClientProvider)));
final subscriptionProvider = FutureProvider.autoDispose<SubscriptionInfo>((ref) => ref.watch(subscriptionRepositoryProvider).getSubscription());

/// In-app purchases (RevenueCat SDK). Purchases are confirmed by the backend (webhook + REST),
/// never by the client. Unavailable until the RevenueCat project, store products and the SDK are
/// set up (owner action).
abstract interface class PurchaseService {
  bool get available;
  Future<void> purchase(String packageId);
  Future<void> restore();
}

class UnavailablePurchaseService implements PurchaseService {
  const UnavailablePurchaseService();
  @override
  bool get available => false;
  @override
  Future<void> purchase(String packageId) => Future.error(const ServerFailure(statusCode: 0, message: 'Purchases are not available yet.'));
  @override
  Future<void> restore() => Future.error(const ServerFailure(statusCode: 0, message: 'Purchases are not available yet.'));
}

final purchaseServiceProvider = Provider<PurchaseService>((ref) => const UnavailablePurchaseService());

/// Where an ad could appear. Policy (APP_FLOW §16, APP_DEVELOPMENT §11): free plan only, never
/// during a conversation, never on the paywall or before a paywall decision.
enum AdPlacement { homeBanner, afterFeedback, conversation, paywall }

bool adAllowed(Plan plan, AdPlacement placement) => switch (placement) {
      AdPlacement.conversation || AdPlacement.paywall => false,
      AdPlacement.homeBanner || AdPlacement.afterFeedback => plan == Plan.free,
    };

/// Ads (AdMob SDK). Unavailable until the AdMob app and ad unit IDs and the consent flow exist
/// (owner action); nothing is shown or loaded meanwhile.
abstract interface class AdService {
  bool get available;
}

class UnavailableAdService implements AdService {
  const UnavailableAdService();
  @override
  bool get available => false;
}

final adServiceProvider = Provider<AdService>((ref) => const UnavailableAdService());
