import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/local_storage.dart';

/// The guest trial: exactly one introductory lesson, playable without an account.
///
/// Only a non-sensitive "the sample lesson was finished" flag is stored on the device. It never
/// unlocks anything: access to the rest of the app is decided by the server (signed-in account +
/// active subscription). Clearing app data only resets the one sample lesson.
const guestLessonDoneKey = 'guest.sample_lesson_done.v1';

final guestLessonDoneProvider = NotifierProvider<GuestLessonDone, bool>(GuestLessonDone.new);

class GuestLessonDone extends Notifier<bool> {
  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(guestLessonDoneKey) ?? false;

  Future<void> markDone() async {
    state = true;
    await ref.read(sharedPreferencesProvider).setBool(guestLessonDoneKey, true);
  }
}
