import 'package:flutter_test/flutter_test.dart';
import 'package:speakdaily/features/tutors/tutor.dart';

void main() {
  test('Emma is the only tutor enabled in the prototype', () {
    expect(tutors.where((t) => t.available).map((t) => t.id), ['emma']);
    expect(tutorById('unknown').id, 'emma');
  });
}
