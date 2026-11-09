import 'package:flutter/material.dart';

/// Client-side tutor metadata for display. Prompts and voice configuration
/// live on the backend (`backend/src/tutors.ts`) and are never sent to the app.
class Tutor {
  const Tutor({
    required this.id,
    required this.name,
    required this.title,
    required this.personality,
    required this.levels,
    required this.focus,
    required this.color,
    this.available = true,
  });

  final String id;
  final String name;
  final String title;
  final String personality;
  final String levels;
  final String focus;
  final Color color;

  /// Prototype phase: only Emma is enabled.
  final bool available;
}

const tutors = <Tutor>[
  Tutor(
    id: 'emma',
    name: 'Emma',
    title: 'Friendly English Coach',
    personality: 'Patient and encouraging',
    levels: 'A1 – B1',
    focus: 'Everyday communication',
    color: Color(0xFF3B5BDB),
  ),
  Tutor(
    id: 'alex',
    name: 'Alex',
    title: 'Professional Communication Coach',
    personality: 'Direct, constructive feedback',
    levels: 'B1 – B2',
    focus: 'Interviews, meetings, presentations',
    color: Color(0xFF0F766E),
    available: false,
  ),
  Tutor(
    id: 'sofia',
    name: 'Sofia',
    title: 'Natural Conversation Partner',
    personality: 'Expressive and relaxed',
    levels: 'A2 – B2',
    focus: 'Social and travel situations',
    color: Color(0xFFC2410C),
    available: false,
  ),
];

Tutor tutorById(String id) => tutors.firstWhere((t) => t.id == id, orElse: () => tutors.first);
