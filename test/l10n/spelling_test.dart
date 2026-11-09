import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Owner decision 2026-11-09: American English spelling for the initial release.
/// British English is supported later via `app_en_GB.arb` (see doc/roadmap/phase_2.md).
void main() {
  test('app_en.arb uses American English spelling', () {
    final arb = (jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map<String, dynamic>)
        .entries
        .where((e) => !e.key.startsWith('@') && e.value is String)
        .map((e) => '${e.key}: ${e.value}');
    final british = RegExp(
      r'practis|analys|colour|favour|organis|recognis|realis|centre|travell|\benrol\b|programme|behaviour|catalogue|cancell',
      caseSensitive: false,
    );
    expect(arb.where(british.hasMatch).toList(), isEmpty);
  });
}
