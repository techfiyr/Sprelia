import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/sign_in_screen.dart';
import '../../features/auth/verify_email_screen.dart';
import '../../features/feedback/feedback_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/learn/learn_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/practice/category_screen.dart';
import '../../features/practice/conversation_screen.dart';
import '../../features/practice/practice_screen.dart';
import '../../features/practice/prepare_screen.dart';
import '../../features/profile/preference_editor_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/tutors/tutors_screen.dart';
import '../session/session_controller.dart';
import '../widgets/widgets.dart';
import 'app_routes.dart';
import 'app_shell.dart';

export 'app_routes.dart';

/// Pure redirect rule (unit-testable). Returns the location to go to, or null.
///
/// - Session loading or failed → splash (which shows retry on failure).
/// - Signed out → welcome / sign-in only.
/// - Signed in with an unverified email/password account → email verification only.
/// - Signed in, onboarding incomplete → onboarding only.
/// - Signed in and onboarded → never back to splash/welcome/sign-in/onboarding.
String? sessionRedirect(AsyncValue<SessionState> session, String location) {
  final value = session.value;
  if (value == null) return location == AppRoutes.splash ? null : AppRoutes.splash;
  if (session.hasError && !session.isLoading) return location == AppRoutes.splash ? null : AppRoutes.splash;

  switch (value) {
    case SignedOut():
      if (location == AppRoutes.welcome || location == AppRoutes.signIn) return null;
      return AppRoutes.welcome;
    case NeedsEmailVerification():
      return location == AppRoutes.verifyEmail ? null : AppRoutes.verifyEmail;
    case SignedIn(:final profile) when !profile.onboardingCompleted:
      return location == AppRoutes.onboarding ? null : AppRoutes.onboarding;
    case SignedIn():
      final entry = AppRoutes.publicRoutes.contains(location) ||
          location == AppRoutes.onboarding ||
          location == AppRoutes.verifyEmail;
      return entry ? AppRoutes.home : null;
  }
}

/// Application router.
///
/// - Tabs live in a [StatefulShellRoute]; focused flows (tutor selection,
///   preparation, live conversation, feedback) are pushed full-screen above it.
/// - Access is driven by [sessionRedirect]; the router re-evaluates whenever
///   the session changes.
/// - Unknown locations render [RouteNotFoundScreen].
final routerProvider = Provider<GoRouter>((ref) {
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  StatefulShellBranch tab(String path, Widget screen, {List<RouteBase> routes = const []}) => StatefulShellBranch(
        routes: [GoRoute(path: path, builder: (_, _) => screen, routes: routes)],
      );

  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (_, state) => sessionRedirect(ref.read(sessionProvider), state.matchedLocation),
    errorBuilder: (_, _) => const RouteNotFoundScreen(),
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: AppRoutes.welcome, builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: AppRoutes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(path: AppRoutes.verifyEmail, builder: (_, _) => const VerifyEmailScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (_, _) => const OnboardingScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          tab(AppRoutes.home, const HomeScreen()),
          tab(AppRoutes.practice, const PracticeScreen(), routes: [
            GoRoute(
              path: 'category/:categoryId',
              builder: (_, s) => CategoryScreen(categoryId: s.pathParameters['categoryId']!),
            ),
          ]),
          tab(AppRoutes.learn, const LearnScreen()),
          tab(AppRoutes.progress, const ProgressScreen()),
          tab(AppRoutes.profile, const ProfileScreen(), routes: [
            GoRoute(
              path: 'edit/:field',
              builder: (_, s) {
                final field = PreferenceField.fromSlug(s.pathParameters['field']);
                return field == null ? const RouteNotFoundScreen() : PreferenceEditorScreen(field: field);
              },
            ),
          ]),
        ],
      ),
      GoRoute(
        path: AppRoutes.tutors,
        builder: (_, s) => TutorsScreen(scenarioId: s.uri.queryParameters['scenario']),
      ),
      GoRoute(
        path: AppRoutes.preparePattern,
        builder: (_, s) => PrepareScreen(
          tutorId: s.pathParameters['tutorId']!,
          scenarioId: s.uri.queryParameters['scenario'],
        ),
      ),
      GoRoute(
        path: AppRoutes.conversationPattern,
        builder: (_, s) => ConversationScreen(
          tutorId: s.pathParameters['tutorId']!,
          scenarioId: s.uri.queryParameters['scenario'],
        ),
      ),
      GoRoute(
        path: AppRoutes.feedbackPattern,
        builder: (_, s) => FeedbackScreen(conversationId: s.pathParameters['conversationId']!),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class RouteNotFoundScreen extends StatelessWidget {
  const RouteNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: AppEmptyState(
        icon: Icons.explore_off_outlined,
        title: "This page isn't available",
        message: 'The link may be out of date.',
        actionLabel: 'Go to Home',
        onAction: () => context.go(AppRoutes.home),
      ),
    );
  }
}
