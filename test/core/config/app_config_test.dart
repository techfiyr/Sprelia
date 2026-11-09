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

    AppConfig release(String env, String url) => AppConfig.fromValues(
          appEnv: env,
          apiBaseUrl: url,
          firebaseProjectId: 'sprelia',
          firebaseApiKey: 'k',
          firebaseAppId: '1:1:android:1',
          firebaseMessagingSenderId: '1',
        );

    test('strips a trailing slash', () {
      expect(release('staging', 'https://api.example.com/').apiBaseUrl, 'https://api.example.com');
    });

    test('never exposes the dev user id outside development', () {
      expect(release('production', 'https://api.example.com').devUserId, isNull);
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

    group('Firebase', () {
      AppConfig build({
        String env = 'development',
        String url = 'https://api.example.com',
        String project = 'demo-sprelia',
        String apiKey = 'k',
        String appId = '1:1:android:1',
        String sender = '1',
        String emulator = '10.0.2.2:9099',
      }) =>
          AppConfig.fromValues(
            appEnv: env,
            apiBaseUrl: url,
            firebaseProjectId: project,
            firebaseApiKey: apiKey,
            firebaseAppId: appId,
            firebaseMessagingSenderId: sender,
            firebaseAuthEmulatorHost: emulator,
          );

      test('development may use the emulator with a demo project', () {
        final c = build();
        expect(c.firebase!.usesEmulator, isTrue);
        expect(c.firebase!.authEmulatorAddress, ('10.0.2.2', 9099));
      });

      test('development without Firebase disables sign-in', () {
        expect(AppConfig.fromValues(appEnv: 'development', apiBaseUrl: '').firebase, isNull);
      });

      test('the emulator is refused outside development', () {
        expect(() => build(env: 'staging', project: 'sprelia'), throwsA(isA<ConfigException>()));
        expect(() => build(env: 'production', project: 'sprelia'), throwsA(isA<ConfigException>()));
      });

      test('Firebase is required outside development', () {
        expect(
          () => AppConfig.fromValues(appEnv: 'staging', apiBaseUrl: 'https://api.example.com'),
          throwsA(isA<ConfigException>()),
        );
      });

      test('demo projects require the emulator', () {
        expect(() => build(emulator: ''), throwsA(isA<ConfigException>()));
      });

      test('partial Firebase config is rejected', () {
        expect(() => build(apiKey: ''), throwsA(isA<ConfigException>()));
      });

      test('a project number is not accepted as a project ID', () {
        expect(() => build(project: '756773147926', emulator: ''), throwsA(isA<ConfigException>()));
      });

      test('single approved project: sprelia in every environment, no other real project', () {
        final dev = build(project: 'sprelia', emulator: '');
        expect(dev.firebase!.projectId, 'sprelia');
        expect(dev.firebase!.usesSharedProject, isTrue);
        expect(build(env: 'staging', project: 'sprelia', emulator: '').firebase!.projectId, 'sprelia');
        expect(() => build(project: 'sprelia-dev', emulator: ''), throwsA(isA<ConfigException>()));
        expect(() => build(env: 'staging', project: 'sprelia-dev', emulator: ''), throwsA(isA<ConfigException>()));
        expect(() => build(env: 'production', project: 'sprelia-dev', emulator: ''), throwsA(isA<ConfigException>()));
        expect(build().firebase!.usesSharedProject, isFalse);
      });

      test('Google sign-in is configured only with valid OAuth client IDs', () {
        AppConfig google(String server, [String ios = '']) => AppConfig.fromValues(
              appEnv: 'development',
              apiBaseUrl: '',
              firebaseProjectId: 'demo-sprelia',
              firebaseApiKey: 'k',
              firebaseAppId: '1:1:android:1',
              firebaseMessagingSenderId: '1',
              firebaseAuthEmulatorHost: '10.0.2.2:9099',
              googleServerClientId: server,
              googleIosClientId: ios,
            );
        expect(google('').firebase!.googleSignInConfigured, isFalse);
        expect(google('123-abc.apps.googleusercontent.com').firebase!.googleSignInConfigured, isTrue);
        expect(() => google('not-a-client-id'), throwsA(isA<ConfigException>()));
        expect(() => google('123-abc.apps.googleusercontent.com', 'bad'), throwsA(isA<ConfigException>()));
      });

      test('App Check can only be disabled in development', () {
        AppConfig withAppCheck(String env, bool enabled) => AppConfig.fromValues(
              appEnv: env,
              apiBaseUrl: env == 'development' ? '' : 'https://api.example.com',
              firebaseProjectId: 'sprelia',
              firebaseApiKey: 'k',
              firebaseAppId: '1:1:android:1',
              firebaseMessagingSenderId: '1',
              appCheckEnabled: enabled,
            );
        expect(withAppCheck('development', false).appCheckEnabled, isFalse);
        expect(withAppCheck('staging', false).appCheckEnabled, isTrue);
        expect(withAppCheck('production', false).appCheckEnabled, isTrue);
      });

      test('a real project works without the emulator in production', () {
        final c = build(env: 'production', project: 'sprelia', emulator: '');
        expect(c.firebase!.usesEmulator, isFalse);
        expect(c.voicePrototypeEnabled, isFalse);
      });
    });

    test('rejects unknown environments and relative URLs', () {
      expect(() => AppConfig.fromValues(appEnv: 'qa', apiBaseUrl: 'https://x.dev'), throwsA(isA<ConfigException>()));
      expect(() => AppConfig.fromValues(appEnv: 'development', apiBaseUrl: '/api'), throwsA(isA<ConfigException>()));
    });
  });
}
