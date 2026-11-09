import { z } from 'zod';

/** Learning goals (APP_FLOW §5, screen 3). */
export const LEARNING_GOALS = ['everyday', 'career', 'business', 'travel_social', 'academic', 'confidence'] as const;
/** Self-reported level (APP_FLOW §5, screen 4; C1 added by owner decision 2026-11-09). Not a formal CEFR assessment. */
export const ENGLISH_LEVELS = ['A1', 'A2', 'B1', 'B2', 'C1', 'not_sure'] as const;
/** Motivational daily target in minutes (owner decision 2026-11-09: 5, 10, 15). Not the free allowance. */
export const DAILY_GOAL_MINUTES = [5, 10, 15] as const;
/** Accent preference (APP_FLOW §5, screen 6). Preferences, not correctness. */
export const ACCENTS = ['american', 'british', 'australian', 'international'] as const;
/** Interface languages the app currently ships. Extend together with the app's ARB files. */
export const INTERFACE_LANGUAGES = ['en'] as const;

export type LearningGoal = (typeof LEARNING_GOALS)[number];
export type EnglishLevel = (typeof ENGLISH_LEVELS)[number];
export type Accent = (typeof ACCENTS)[number];

/** ISO 639-1/639-2 language code with an optional region, e.g. "bn", "pt-BR". */
const languageCode = z.string().regex(/^[a-z]{2,3}(-[A-Z]{2})?$/, 'must be an ISO 639 language code');

export function isValidTimeZone(tz: string): boolean {
  if (tz.length > 64 || !/^(UTC|[A-Za-z_]+(\/[A-Za-z0-9_+-]+){1,2})$/.test(tz)) return false;
  try {
    new Intl.DateTimeFormat('en-US', { timeZone: tz });
    return true;
  } catch {
    return false;
  }
}

export const TimeZone = z.string().refine(isValidTimeZone, 'must be an IANA time zone, e.g. "Asia/Dhaka"');

export const DisplayName = z
  .string()
  .trim()
  .min(1)
  .max(60)
  .refine((s) => !/[\u0000-\u001f<>]/.test(s), 'contains unsupported characters');

/** POST /me/profile. `uid` and `email` always come from the verified token. */
export const CreateProfileBody = z
  .object({
    displayName: DisplayName.optional(),
    timezone: TimeZone,
  })
  .strict();
export type CreateProfileBody = z.infer<typeof CreateProfileBody>;

export const LearningPreferences = z
  .object({
    interfaceLanguage: z.enum(INTERFACE_LANGUAGES),
    nativeLanguage: languageCode,
    goals: z
      .array(z.enum(LEARNING_GOALS))
      .min(1)
      .max(LEARNING_GOALS.length)
      .refine((g) => new Set(g).size === g.length, 'must not contain duplicates'),
    level: z.enum(ENGLISH_LEVELS),
    dailyGoalMinutes: z.union([z.literal(5), z.literal(10), z.literal(15)]),
    accent: z.enum(ACCENTS),
  })
  .strict();
export type LearningPreferences = z.infer<typeof LearningPreferences>;

/**
 * PUT /me/onboarding. Partial saves are allowed while onboarding is in progress.
 * `complete: true` succeeds only when the MERGED, server-stored preferences are
 * complete (checked inside the write transaction).
 */
export const SaveOnboardingBody = z
  .object({
    preferences: LearningPreferences.partial().strict(),
    complete: z.boolean().default(false),
  })
  .strict();

/** Field paths missing or invalid for completing onboarding (empty when complete). */
export function missingForCompletion(merged: Partial<LearningPreferences>): string[] {
  const full = LearningPreferences.safeParse(merged);
  return full.success ? [] : [...new Set(full.error.issues.map((i) => String(i.path[0] ?? '')))];
}
export type SaveOnboardingBody = z.infer<typeof SaveOnboardingBody>;

/** Catalogue IDs are kebab-case; the route also checks the tutor exists. */
const TutorId = z.string().regex(/^[a-z][a-z0-9-]{1,30}$/, 'must be a tutor ID');

/** PATCH /me/profile. Server-owned fields (uid, email, status, timestamps) are never accepted. */
export const UpdateProfileBody = z
  .object({
    displayName: DisplayName.nullable().optional(),
    timezone: TimeZone.optional(),
    preferredTutorId: TutorId.nullable().optional(),
    practiceReminders: z.boolean().optional(),
  })
  .strict()
  .refine((b) => Object.keys(b).length > 0, 'at least one field is required');
export type UpdateProfileBody = z.infer<typeof UpdateProfileBody>;

/** PATCH /me/preferences: edit learning preferences after onboarding (each field validated). */
export const UpdatePreferencesBody = z
  .object({ preferences: LearningPreferences.partial().strict() })
  .strict()
  .refine((b) => Object.keys(b.preferences).length > 0, 'at least one preference is required');
export type UpdatePreferencesBody = z.infer<typeof UpdatePreferencesBody>;
