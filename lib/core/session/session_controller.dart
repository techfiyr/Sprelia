import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../features/profile/data/profile_models.dart';
import '../../features/profile/data/profile_repository.dart';
import '../auth/auth_repository.dart';

sealed class SessionState {
  const SessionState();
}

final class SignedOut extends SessionState {
  const SignedOut();
}

final class SignedIn extends SessionState {
  const SignedIn(this.user, this.profile);
  final AuthUser user;
  final UserProfile profile;
}

/// IANA time zone of the device (used once, when the profile is created).
/// Falls back to UTC; the learner can correct it in settings later.
final deviceTimeZoneProvider = Provider<Future<String> Function()>((ref) => () async {
      try {
        return (await FlutterTimezone.getLocalTimezone()).identifier;
      } catch (_) {
        return 'UTC';
      }
    });

/// The app session: who is signed in and their server-side profile.
///
/// Signed in without a profile → the profile is created (idempotent on the
/// server). The router redirects based on this state.
final sessionProvider = AsyncNotifierProvider<SessionController, SessionState>(SessionController.new);

class SessionController extends AsyncNotifier<SessionState> {
  @override
  Future<SessionState> build() async {
    final user = await ref.watch(authStateProvider.future);
    if (user == null) return const SignedOut();
    final repo = ref.watch(profileRepositoryProvider);
    final profile = await repo.getProfile() ??
        await repo.createProfile(timezone: await ref.read(deviceTimeZoneProvider)());
    return SignedIn(user, profile);
  }

  /// Reloads the profile from the server (e.g. after onboarding completes).
  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> signOut() => ref.read(authRepositoryProvider).signOut();
}
