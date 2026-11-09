/// Route paths. Features navigate with these helpers, never with string literals.
abstract final class AppRoutes {
  static const welcome = '/welcome';

  // Main navigation tabs (APP_FLOW §1).
  static const home = '/home';
  static const practice = '/practice';
  static const learn = '/learn';
  static const progress = '/progress';
  static const profile = '/profile';

  // Full-screen flows above the tab shell.
  static const tutors = '/tutors';
  static const preparePattern = '/prepare/:tutorId';
  static const conversationPattern = '/conversation/:tutorId';
  static const feedbackPattern = '/feedback/:conversationId';

  static String prepare(String tutorId) => '/prepare/${Uri.encodeComponent(tutorId)}';
  static String conversation(String tutorId) => '/conversation/${Uri.encodeComponent(tutorId)}';
  static String feedback(String conversationId) => '/feedback/${Uri.encodeComponent(conversationId)}';
}
