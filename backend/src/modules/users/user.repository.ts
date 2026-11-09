import type { LearningPreferences } from './user.schemas.js';

export type OnboardingStatus = 'not_started' | 'in_progress' | 'completed';

/** users/{uid} */
export interface UserProfile {
  uid: string;
  email: string | null;
  displayName: string | null;
  timezone: string;
  onboardingStatus: OnboardingStatus;
  onboardingCompletedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

/** Server-maintained activity for one local day: users/{uid}/dailyProgress/{YYYY-MM-DD}. */
export interface DailyActivity {
  date: string;
  speakingSeconds: number;
  sessionsCompleted: number;
}

/**
 * Persistence for user-owned data. Every method is keyed by the uid of the
 * *verified* caller; routes never pass a client-supplied uid.
 *
 * Writes are only ever performed by the backend (Admin SDK); Firestore rules
 * deny direct client writes.
 */
export interface UserRepository {
  getProfile(uid: string): Promise<UserProfile | null>;

  /** Creates the profile if absent (atomic). Never overwrites an existing profile. */
  createProfileIfAbsent(input: {
    uid: string;
    email: string | null;
    displayName: string | null;
    timezone: string;
  }): Promise<{ profile: UserProfile; created: boolean }>;

  getPreferences(uid: string): Promise<Partial<LearningPreferences> | null>;

  /**
   * Merges preferences and updates onboarding status atomically.
   * Once completed, onboarding stays completed (later saves edit preferences).
   * Throws OnboardingIncompleteError (and writes nothing) when `complete` is
   * requested but the merged preferences are incomplete.
   */
  saveOnboarding(
    uid: string,
    preferences: Partial<LearningPreferences>,
    complete: boolean,
  ): Promise<{ profile: UserProfile; preferences: Partial<LearningPreferences> }>;

  /** Server-recorded usage seconds for a local date (0 when none recorded). */
  getUsageSeconds(uid: string, date: string): Promise<number>;

  /** Activity for the given local dates (missing days are omitted). */
  getDailyActivity(uid: string, dates: string[]): Promise<DailyActivity[]>;
}

export class OnboardingIncompleteError extends Error {
  constructor(public readonly missing: string[]) {
    super('onboarding incomplete');
    this.name = 'OnboardingIncompleteError';
  }
}

export class ProfileNotFoundError extends Error {
  constructor() {
    super('profile not found');
    this.name = 'ProfileNotFoundError';
  }
}
