import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/feedback/feedback_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/learn/learn_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/practice/conversation_screen.dart';
import '../../features/practice/practice_screen.dart';
import '../../features/practice/prepare_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/tutors/tutors_screen.dart';
import '../widgets/widgets.dart';
import 'app_routes.dart';
import 'app_shell.dart';

export 'app_routes.dart';

/// Application router.
///
/// - Tabs live in a [StatefulShellRoute]; focused flows (tutor selection,
///   preparation, live conversation, feedback) are pushed full-screen above it.
/// - Unknown locations render [RouteNotFoundScreen] instead of crashing.
/// - Auth/onboarding redirects are added in Phase 4 (Firebase Auth). Until
///   then every route is reachable, matching the prototype.
final routerProvider = Provider<GoRouter>((ref) {
  final rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

  StatefulShellBranch tab(String path, Widget screen) => StatefulShellBranch(
        routes: [GoRoute(path: path, builder: (_, _) => screen)],
      );

  final router = GoRouter(
    navigatorKey: rootKey,
    initialLocation: AppRoutes.welcome,
    errorBuilder: (_, _) => const RouteNotFoundScreen(),
    routes: [
      GoRoute(path: AppRoutes.welcome, builder: (_, _) => const WelcomeScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          tab(AppRoutes.home, const HomeScreen()),
          tab(AppRoutes.practice, const PracticeScreen()),
          tab(AppRoutes.learn, const LearnScreen()),
          tab(AppRoutes.progress, const ProgressScreen()),
          tab(AppRoutes.profile, const ProfileScreen()),
        ],
      ),
      GoRoute(path: AppRoutes.tutors, builder: (_, _) => const TutorsScreen()),
      GoRoute(
        path: AppRoutes.preparePattern,
        builder: (_, s) => PrepareScreen(tutorId: s.pathParameters['tutorId']!),
      ),
      GoRoute(
        path: AppRoutes.conversationPattern,
        builder: (_, s) => ConversationScreen(tutorId: s.pathParameters['tutorId']!),
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
