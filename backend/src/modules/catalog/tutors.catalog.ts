/**
 * Public tutor catalogue (APP_FLOW §7, BRAND §6). Display data only.
 *
 * System prompts and voice configuration are NOT part of this catalogue and are
 * never sent to clients (they live server-side with the realtime module).
 * Review-managed in code for Phase 2; moves to the read-only `tutors` collection
 * once an admin workflow exists.
 */
export type CefrLevel = 'A1' | 'A2' | 'B1' | 'B2' | 'C1';

export interface PublicTutor {
  id: string;
  name: string;
  title: string;
  personality: string[];
  description: string;
  levels: { min: CefrLevel; max: CefrLevel };
  categoryIds: string[];
  /** Brand tone for the placeholder avatar (BRAND §6 portraits not yet designed). */
  tone: 'primary' | 'primaryDark' | 'accent';
  /** Voice conversations are available (server persona exists; Phase 6). */
  voiceAvailable: boolean;
  voiceSampleAvailable: boolean;
}

export const TUTORS: readonly PublicTutor[] = [
  {
    id: 'emma',
    name: 'Emma',
    title: 'Friendly English Coach',
    personality: ['Warm', 'Patient', 'Encouraging'],
    description: 'A patient coach who helps you feel relaxed and confident while you speak.',
    levels: { min: 'A1', max: 'B1' },
    // professional/academic added 2026-11-09: beginner (A1–A2) work and classroom scenarios.
    categoryIds: ['everyday', 'travel', 'social', 'professional', 'academic'],
    tone: 'primary',
    voiceAvailable: true,
    voiceSampleAvailable: false,
  },
  {
    id: 'alex',
    name: 'Alex',
    title: 'Professional Communication Coach',
    personality: ['Professional', 'Structured', 'Helpful'],
    description: 'Practice interviews, meetings and presentations with clear, structured guidance.',
    levels: { min: 'A2', max: 'C1' },
    // social added 2026-11-09 (owner decision): professional networking.
    categoryIds: ['professional', 'academic', 'social'],
    tone: 'primaryDark',
    voiceAvailable: true,
    voiceSampleAvailable: false,
  },
  {
    id: 'sofia',
    name: 'Sofia',
    title: 'Everyday Conversation Partner',
    personality: ['Natural', 'Expressive', 'Friendly'],
    description: 'Chat naturally about daily life, travel and social situations.',
    levels: { min: 'A1', max: 'B2' },
    categoryIds: ['everyday', 'travel', 'social'],
    tone: 'accent',
    voiceAvailable: true,
    voiceSampleAvailable: false,
  },
];

export function tutorExists(id: string): boolean {
  return TUTORS.some((t) => t.id === id);
}
