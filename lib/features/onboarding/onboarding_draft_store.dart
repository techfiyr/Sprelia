import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/storage/local_storage.dart';
import '../profile/data/learning_preferences.dart';

enum OnboardingStep { interfaceLanguage, nativeLanguage, goals, level, dailyGoal, accent, plan }

/// Onboarding progress saved on the device so closing the app never loses
/// answers (Phase 2 §E). Contains preferences only; no personal or secret data.
class OnboardingDraft {
  const OnboardingDraft({required this.step, required this.preferences});

  final OnboardingStep step;
  final LearningPreferences preferences;

  Map<String, Object?> toJson() => {'v': 1, 'step': step.name, 'preferences': preferences.toJson()};

  static OnboardingDraft? tryParse(String raw) {
    try {
      final j = (jsonDecode(raw) as Map).cast<String, Object?>();
      if (j['v'] != 1) return null;
      final step = OnboardingStep.values.where((s) => s.name == j['step']).firstOrNull;
      if (step == null || step == OnboardingStep.plan) return null;
      return OnboardingDraft(
        step: step,
        preferences: LearningPreferences.fromJson((j['preferences'] as Map?)?.cast<String, Object?>() ?? const {}),
      );
    } catch (_) {
      return null; // Corrupt draft: start over rather than crash.
    }
  }
}

class OnboardingDraftStore {
  const OnboardingDraftStore(this._prefs);

  final SharedPreferences _prefs;

  static String _key(String uid) => 'onboarding_draft_v1_$uid';

  OnboardingDraft? load(String uid) {
    final raw = _prefs.getString(_key(uid));
    return raw == null ? null : OnboardingDraft.tryParse(raw);
  }

  Future<void> save(String uid, OnboardingDraft draft) => _prefs.setString(_key(uid), jsonEncode(draft.toJson()));

  Future<void> clear(String uid) => _prefs.remove(_key(uid));
}

final onboardingDraftStoreProvider =
    Provider<OnboardingDraftStore>((ref) => OnboardingDraftStore(ref.watch(sharedPreferencesProvider)));
