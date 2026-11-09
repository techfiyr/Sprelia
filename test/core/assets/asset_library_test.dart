import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speakdaily/core/assets/app_assets.dart';

/// Enforces the asset library guidelines (doc/ASSET_LIBRARY.md) so the registry,
/// the files on disk, pubspec.yaml and the inventory document cannot drift apart.
void main() {
  final fileEntries = AppAssets.all.where((e) => !e.path.startsWith('code:')).toList();
  final docFiles = {'README.md', 'ATTRIBUTION.md'};

  List<File> assetFiles() => Directory('assets')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => !docFiles.contains(f.uri.pathSegments.last) && !f.uri.pathSegments.last.startsWith('.'))
      .toList();

  String rel(File f) => f.path.replaceAll(r'\', '/').replaceFirst(RegExp(r'^\./'), '');

  /// Paths registered in pubspec.yaml (`assets:` entries and font `asset:` entries).
  Set<String> pubspecAssets() {
    final yaml = File('pubspec.yaml').readAsLinesSync().where((l) => !l.trimLeft().startsWith('#'));
    final pattern = RegExp(r'^\s*-?\s*(?:asset:\s*)?(assets/[^\s#]+)');
    return {for (final l in yaml) ?pattern.firstMatch(l)?.group(1)};
  }

  bool isRegistered(String path, Set<String> registered) =>
      registered.contains(path) || registered.any((r) => r.endsWith('/') && path.startsWith(r));

  test('registry has no duplicate paths', () {
    final paths = AppAssets.all.map((e) => e.path).toList();
    expect(paths.toSet().length, paths.length);
  });

  test('every file under assets/ is in the registry (no orphans)', () {
    final known = fileEntries.map((e) => e.path).toSet();
    final orphans = assetFiles().map(rel).where((p) => !known.contains(p)).toList();
    expect(orphans, isEmpty, reason: 'Add these to AppAssets and doc/ASSET_LIBRARY.md');
  });

  test('status matches the files on disk', () {
    for (final e in fileEntries) {
      final exists = File(e.path).existsSync();
      switch (e.status) {
        case AssetStatus.available:
          expect(exists, isTrue, reason: '${e.path} is "available" but missing');
        case AssetStatus.planned:
          expect(exists, isFalse, reason: '${e.path} exists: update its status (and licence) in AppAssets');
        case AssetStatus.placeholder:
          break; // Coded placeholders have no file; unapproved candidates do.
      }
    }
  });

  test('only available, licensed assets are bundled; bundled ones are registered in pubspec', () {
    final registered = pubspecAssets();
    for (final e in fileEntries) {
      if (e.bundled) {
        expect(e.status, AssetStatus.available, reason: '${e.path}: only approved assets may be bundled');
        expect(e.license.toUpperCase(), isNot(anyOf(contains('UNKNOWN'), startsWith('TBD'))));
        expect(isRegistered(e.path, registered), isTrue, reason: '${e.path} missing from pubspec.yaml');
      } else {
        expect(isRegistered(e.path, registered), isFalse, reason: '${e.path} is not approved for bundling');
      }
    }
    for (final r in registered) {
      expect(r.endsWith('/') ? Directory(r).existsSync() : File(r).existsSync(), isTrue,
          reason: 'pubspec.yaml registers $r, which does not exist');
    }
  });

  test('names are lowercase snake_case with allowed formats', () {
    const allowed = {'png', 'webp', 'svg', 'gif', 'json', 'ttf', 'otf', 'txt', 'jpeg', 'jpg'};
    final name = RegExp(r'^[a-z0-9]+(_[a-z0-9]+)*\.[a-z0-9]+$');
    final dir = RegExp(r'^[a-z0-9_]+$');
    for (final e in fileEntries) {
      final segments = e.path.split('/');
      expect(segments.first, 'assets', reason: e.path);
      for (final d in segments.sublist(1, segments.length - 1)) {
        expect(dir.hasMatch(d), isTrue, reason: 'folder "$d" in ${e.path}');
      }
      expect(name.hasMatch(segments.last), isTrue, reason: 'file name ${segments.last}');
      expect(allowed, contains(e.format), reason: e.path);
      if (e.bundled) {
        expect({'jpeg', 'jpg'}, isNot(contains(e.format)), reason: '${e.path}: bundle WebP/PNG, not JPEG');
      }
    }
  });

  test('files stay within size budgets', () {
    const budgetKb = {'png': 500, 'webp': 300, 'jpeg': 500, 'jpg': 500, 'svg': 100, 'gif': 100, 'json': 300, 'ttf': 600, 'otf': 600, 'txt': 50};
    for (final f in assetFiles()) {
      final ext = f.path.split('.').last;
      final kb = f.lengthSync() / 1024;
      expect(kb, lessThanOrEqualTo(budgetKb[ext] ?? 0), reason: '${rel(f)} is ${kb.toStringAsFixed(0)} KB');
    }
  });

  test('no duplicate asset content', () {
    final seen = <String, String>{};
    for (final f in assetFiles()) {
      final hash = sha256.convert(f.readAsBytesSync()).toString();
      expect(seen[hash], isNull, reason: '${rel(f)} duplicates ${seen[hash]}');
      seen[hash] = rel(f);
    }
  });

  test('every entry has a purpose and licence/source', () {
    for (final e in AppAssets.all) {
      expect(e.purpose.trim(), isNotEmpty, reason: e.path);
      expect(e.license.trim(), isNotEmpty, reason: e.path);
    }
  });

  test('the inventory document lists every registered asset', () {
    final doc = File('doc/ASSET_LIBRARY.md').readAsStringSync();
    for (final e in AppAssets.all) {
      expect(doc, contains(e.path.replaceFirst('code:', '')), reason: 'add ${e.path} to doc/ASSET_LIBRARY.md');
    }
  });

  test('Dart code uses AppAssets, not asset string literals or embedded base64 images', () {
    final literal = RegExp('''['"]assets/''');
    final base64Image = RegExp(r'data:image/|[A-Za-z0-9+/]{2000,}={0,2}');
    final offenders = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      if (f.path.endsWith('app_assets.dart') || f.path.contains('/l10n/')) continue;
      final src = f.readAsStringSync();
      if (literal.hasMatch(src) || base64Image.hasMatch(src)) offenders.add(rel(f));
    }
    expect(offenders, isEmpty);
  });

  test('tutor avatars fall back to the placeholder until approved', () {
    expect(AppAssets.tutorAvatar('emma'), isNull);
    expect(AppAssets.tutorAvatar('unknown'), isNull);
    expect(AppAssets.tutorEmmaCandidate.isUsable, isFalse);
  });
}
