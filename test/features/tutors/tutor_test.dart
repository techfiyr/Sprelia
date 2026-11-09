import 'package:flutter_test/flutter_test.dart';
import 'package:speakdaily/features/tutors/tutor.dart';

void main() {
  test('Emma is the only tutor enabled in the prototype', () {
    expect(tutors.where((t) => t.available).map((t) => t.id), ['emma']);
    expect(tutorById('unknown').id, 'emma');
  });

  test('tutor metadata matches APP_FLOW §7', () {
    expect(tutorById('emma').levels, 'A1 – B1');
    expect(tutorById('alex').levels, 'A2 – C1');
    expect(tutorById('sofia').levels, 'A1 – B2');
    expect(tutorById('sofia').title, 'Everyday Conversation Partner');
  });
}
