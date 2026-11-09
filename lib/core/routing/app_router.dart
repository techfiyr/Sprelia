import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/feedback/feedback_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/onboarding/welcome_screen.dart';
import '../../features/practice/conversation_screen.dart';
import '../../features/practice/prepare_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/tutors/tutors_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/welcome',
    routes: [
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/tutors', builder: (_, _) => const TutorsScreen()),
      GoRoute(
        path: '/prepare/:tutorId',
        builder: (_, s) => PrepareScreen(tutorId: s.pathParameters['tutorId']!),
      ),
      GoRoute(
        path: '/conversation/:tutorId',
        builder: (_, s) => ConversationScreen(tutorId: s.pathParameters['tutorId']!),
      ),
      GoRoute(
        path: '/feedback/:conversationId',
        builder: (_, s) => FeedbackScreen(conversationId: s.pathParameters['conversationId']!),
      ),
      GoRoute(path: '/progress', builder: (_, _) => const ProgressScreen()),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
    ],
  );
});
