import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local key/value storage for NON-sensitive data only (e.g. the
/// onboarding draft). Never store tokens, credentials or transcripts here.
///
/// Overridden in `main.dart` with a preloaded instance so reads are synchronous.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden at startup'),
);
