import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session/session_controller.dart';
import 'premium_services.dart';

/// Whether the signed-in user has an active subscription, as verified by the server
/// (`GET /me/subscription`, driven by the RevenueCat webhook). The app never decides this.
///
/// - `null`: nobody is signed in (guest); there is no entitlement to check.
/// - `true` / `false`: the server's answer. Errors surface as [AsyncError]; callers treat an
///   error as "not subscribed" (fail closed) and never as an unlock.
final entitlementProvider = FutureProvider<bool?>((ref) async {
  final session = await ref.watch(sessionProvider.future);
  if (session is! SignedIn) return null;
  final subscription = await ref.watch(subscriptionProvider.future);
  return subscription.isPremium;
});
