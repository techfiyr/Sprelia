/// Compile-time configuration. Supply values with `--dart-define`.
/// Never put secrets here: the app only ever receives short-lived tokens.
class AppConfig {
  const AppConfig._();

  /// Backend base URL. Android emulator → host machine is 10.0.2.2.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  /// Prototype-only dev user id, sent while Firebase Auth is not wired yet.
  /// The backend accepts it only when DEV_SKIP_AUTH=true.
  static const devUserId = String.fromEnvironment('DEV_USER_ID', defaultValue: 'dev-user');

  static const freeDailySeconds = 600; // display only; the server is authoritative
}
