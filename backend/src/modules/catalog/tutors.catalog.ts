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
  /** Voice conversations are currently available (prototype: Emma only). */
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
    categoryIds: ['everyday', 'travel', 'social'],
    tone: 'primary',
    voiceAvailable: true,
    voiceSampleAvailable: false,
  },
  {
    id: 'alex',
    name: 'Alex',
    title: 'Professional Communication Coach',
    personality: ['Professional', 'Structured', 'Helpful'],
    description: 'Practise interviews, meetings and presentations with clear, structured guidance.',
    levels: { min: 'A2', max: 'C1' },
    categoryIds: ['professional', 'academic'],
    tone: 'primaryDark',
    voiceAvailable: false,
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
    voiceAvailable: false,
    voiceSampleAvailable: false,
  },
];

export function tutorExists(id: string): boolean {
  return TUTORS.some((t) => t.id === id);
}
