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
  /** Learner's explicit tutor choice (Profile → Preferred tutor); null = automatic. */
  preferredTutorId: string | null;
  /** Opt-in for practice reminders (delivery needs FCM, not configured yet). */
  practiceReminders: boolean;
  /** Last time the time zone changed (changes are rate-limited: quota day boundary). */
  timezoneUpdatedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

export interface ProfilePatch {
  displayName?: string | null;
  timezone?: string;
  preferredTutorId?: string | null;
  practiceReminders?: boolean;
}

/** Everything stored for one user, for GET /me/export. */
export interface UserDataExport {
  profile: UserProfile;
  preferences: Partial<LearningPreferences> | null;
  usage: { date: string; consumedSeconds: number }[];
  dailyProgress: DailyActivity[];
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

  /**
   * Permanently deletes users/{uid} and every subcollection (account deletion).
   * Idempotent: succeeds when nothing is stored.
   */
  deleteUserData(uid: string): Promise<void>;

  /**
   * Applies a profile patch atomically. A time zone change is refused with
   * TimezoneChangeTooSoonError when the previous change was less than
   * `minTimezoneIntervalMs` ago (prevents quota farming across day boundaries).
   */
  updateProfile(uid: string, patch: ProfilePatch, options: { now: Date; minTimezoneIntervalMs: number }): Promise<UserProfile>;

  /** All of the user's own stored data (no other users). */
  exportUserData(uid: string): Promise<UserDataExport | null>;
}

export class TimezoneChangeTooSoonError extends Error {
  constructor(public readonly retryAfter: Date) {
    super('timezone changed too recently');
    this.name = 'TimezoneChangeTooSoonError';
  }
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
