/// Route paths. Features navigate with these helpers, never with string literals.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const signIn = '/sign-in';
  static const onboarding = '/onboarding';
  static const verifyEmail = '/verify-email';

  // Main navigation tabs (APP_FLOW §1).
  static const home = '/home';
  static const practice = '/practice';
  static const learn = '/learn';
  static const progress = '/progress';
  static const profile = '/profile';
  static const profileEditPattern = '/profile/edit/:field';
  static String profileEdit(String field) => '/profile/edit/${Uri.encodeComponent(field)}';

  static const categoryPattern = '/practice/category/:categoryId';
  static String category(String id) => '/practice/category/${Uri.encodeComponent(id)}';

  // Full-screen flows above the tab shell.
  static const tutors = '/tutors';
  static const preparePattern = '/prepare/:tutorId';
  static const conversationPattern = '/conversation/:tutorId';
  static const feedbackPattern = '/feedback/:conversationId';

  /// Tutor selection, optionally for a chosen scenario.
  static String tutorsFor({String? scenarioId}) =>
      scenarioId == null ? tutors : Uri(path: tutors, queryParameters: {'scenario': scenarioId}).toString();

  static String prepare(String tutorId, {String? scenarioId}) => Uri(
        path: '/prepare/${Uri.encodeComponent(tutorId)}',
        queryParameters: scenarioId == null ? null : {'scenario': scenarioId},
      ).toString();

  static String conversation(String tutorId, {String? scenarioId}) => Uri(
        path: '/conversation/${Uri.encodeComponent(tutorId)}',
        queryParameters: scenarioId == null ? null : {'scenario': scenarioId},
      ).toString();
  static String feedback(String conversationId) => '/feedback/${Uri.encodeComponent(conversationId)}';

  /// Routes reachable without signing in.
  static const publicRoutes = {splash, welcome, signIn};
}
