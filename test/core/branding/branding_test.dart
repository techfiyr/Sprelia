import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:speakdaily/core/branding/app_brand.dart';

/// Branding regression check: the user-facing product name is "Hermione".
///
/// The old name ("SpeakDaily", "Speaks Daily", "SpeaksDaily", any case or spacing) must not
/// appear in user-visible app text or native metadata. Technical identifiers are allowed and
/// intentionally unchanged: the Dart package `speakdaily` (`package:speakdaily/...`) and the
/// repository folder name. App IDs (`com.techfiyr.sprelia`) are checked separately below.
final _stale = RegExp(r'speaks?[\s_-]?daily', caseSensitive: false);
const _allowedTechnical = ['package:speakdaily/'];

Iterable<File> _files(String dir, bool Function(String) include) => Directory(dir)
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => include(f.path));

List<String> _staleHits(File f) {
  final hits = <String>[];
  final lines = f.readAsLinesSync();
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i];
    for (final ok in _allowedTechnical) {
      line = line.replaceAll(ok, '');
    }
    if (_stale.hasMatch(line)) hits.add('${f.path}:${i + 1}');
  }
  return hits;
}

void main() {
  test('the brand constant is Hermione', () {
    expect(AppBrand.name, 'Hermione');
  });

  test('app source and localization strings never show the old product name', () {
    final files = _files('lib', (p) => p.endsWith('.dart') || p.endsWith('.arb'));
    expect(files, isNotEmpty);
    expect(files.expand(_staleHits).toList(), isEmpty);
  });

  test('native display labels and metadata say Hermione', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:label="Hermione"'));

    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    for (final key in ['CFBundleDisplayName', 'CFBundleName']) {
      expect(RegExp('<key>$key</key>\\s*<string>Hermione</string>').hasMatch(plist), isTrue, reason: key);
    }

    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(RegExp(r'^description: "Hermione', multiLine: true).hasMatch(pubspec), isTrue);

    for (final f in [
      File('android/app/src/main/AndroidManifest.xml'),
      File('ios/Runner/Info.plist'),
      ..._files('android/app/src/main/res', (p) => p.endsWith('.xml')),
    ]) {
      expect(_staleHits(f), isEmpty, reason: f.path);
    }
  });

  test('installed-app identity is unchanged (upgrades keep working)', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('applicationId = "com.techfiyr.sprelia"'));
    final pbx = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    expect(pbx, contains('PRODUCT_BUNDLE_IDENTIFIER = com.techfiyr.sprelia;'));
  });
}
