import 'package:flutter_test/flutter_test.dart';
import 'package:speakdaily/core/config/app_config.dart';

void main() {
  group('AppConfig.fromValues', () {
    test('development defaults to the Android emulator host', () {
      final c = AppConfig.fromValues(appEnv: 'development', apiBaseUrl: '');
      expect(c.environment, AppEnvironment.development);
      expect(c.apiBaseUrl, 'http://10.0.2.2:8080');
      expect(c.devUserId, 'dev-user');
    });

    test('strips a trailing slash', () {
      final c = AppConfig.fromValues(appEnv: 'staging', apiBaseUrl: 'https://api.example.com/');
      expect(c.apiBaseUrl, 'https://api.example.com');
    });

    test('never exposes the dev user id outside development', () {
      final c = AppConfig.fromValues(appEnv: 'production', apiBaseUrl: 'https://api.example.com');
      expect(c.devUserId, isNull);
    });

    test('rejects DEV_USER_ID outside development', () {
      expect(
        () => AppConfig.fromValues(appEnv: 'staging', apiBaseUrl: 'https://api.example.com', devUserId: 'x'),
        throwsA(isA<ConfigException>()),
      );
    });

    test('requires https outside development', () {
      expect(
        () => AppConfig.fromValues(appEnv: 'production', apiBaseUrl: 'http://api.example.com'),
        throwsA(isA<ConfigException>()),
      );
    });

    test('requires an explicit URL outside development', () {
      expect(() => AppConfig.fromValues(appEnv: 'staging', apiBaseUrl: ''), throwsA(isA<ConfigException>()));
    });

    test('rejects unknown environments and relative URLs', () {
      expect(() => AppConfig.fromValues(appEnv: 'qa', apiBaseUrl: 'https://x.dev'), throwsA(isA<ConfigException>()));
      expect(() => AppConfig.fromValues(appEnv: 'development', apiBaseUrl: '/api'), throwsA(isA<ConfigException>()));
    });
  });
}
