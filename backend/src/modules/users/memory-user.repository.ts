import { missingForCompletion, type LearningPreferences } from './user.schemas.js';
import {
  OnboardingIncompleteError,
  ProfileNotFoundError,
  TimezoneChangeTooSoonError,
  type ProfilePatch,
  type UserDataExport,
  type DailyActivity,
  type UserProfile,
  type UserRepository,
} from './user.repository.js';

/**
 * In-memory repository for unit tests. Mirrors FirestoreUserRepository semantics
 * (create-if-absent, completed onboarding is sticky). Not used in any deployed build.
 */
export class InMemoryUserRepository implements UserRepository {
  readonly profiles = new Map<string, UserProfile>();
  readonly preferences = new Map<string, Partial<LearningPreferences>>();
  readonly usage = new Map<string, number>(); // `${uid}/${date}`
  readonly activity = new Map<string, DailyActivity>(); // `${uid}/${date}`
  now = () => new Date();

  async getProfile(uid: string) {
    const p = this.profiles.get(uid);
    return p ? { ...p } : null;
  }

  async createProfileIfAbsent(input: { uid: string; email: string | null; displayName: string | null; timezone: string }) {
    const existing = this.profiles.get(input.uid);
    if (existing) return { profile: { ...existing }, created: false };
    const now = this.now();
    const profile: UserProfile = {
      ...input,
      onboardingStatus: 'not_started',
      onboardingCompletedAt: null,
      preferredTutorId: null,
      practiceReminders: false,
      timezoneUpdatedAt: null,
      createdAt: now,
      updatedAt: now,
    };
    this.profiles.set(input.uid, profile);
    return { profile: { ...profile }, created: true };
  }

  async getPreferences(uid: string) {
    const p = this.preferences.get(uid);
    return p ? { ...p } : null;
  }

  async saveOnboarding(uid: string, preferences: Partial<LearningPreferences>, complete: boolean) {
    const current = this.profiles.get(uid);
    if (!current) throw new ProfileNotFoundError();
    const merged = { ...(this.preferences.get(uid) ?? {}), ...preferences };
    if (complete) {
      const missing = missingForCompletion(merged);
      if (missing.length) throw new OnboardingIncompleteError(missing);
    }
    const now = this.now();
    const status = current.onboardingStatus === 'completed' || complete ? 'completed' : 'in_progress';
    const profile: UserProfile = {
      ...current,
      onboardingStatus: status,
      onboardingCompletedAt: current.onboardingCompletedAt ?? (status === 'completed' ? now : null),
      updatedAt: now,
    };
    this.profiles.set(uid, profile);
    this.preferences.set(uid, merged);
    return { profile: { ...profile }, preferences: { ...merged } };
  }

  async getUsageSeconds(uid: string, date: string) {
    return this.usage.get(`${uid}/${date}`) ?? 0;
  }

  async getDailyActivity(uid: string, dates: string[]) {
    return dates.flatMap((d) => {
      const a = this.activity.get(`${uid}/${d}`);
      return a ? [{ ...a }] : [];
    });
  }

  async deleteUserData(uid: string) {
    this.profiles.delete(uid);
    this.preferences.delete(uid);
    for (const map of [this.usage, this.activity] as Map<string, unknown>[]) {
      for (const key of [...map.keys()]) if (key.startsWith(`${uid}/`)) map.delete(key);
    }
  }

  async updateProfile(uid: string, patch: ProfilePatch, options: { now: Date; minTimezoneIntervalMs: number }) {
    const current = this.profiles.get(uid);
    if (!current) throw new ProfileNotFoundError();
    const next: UserProfile = { ...current, updatedAt: options.now };
    if (patch.displayName !== undefined) next.displayName = patch.displayName;
    if (patch.preferredTutorId !== undefined) next.preferredTutorId = patch.preferredTutorId;
    if (patch.practiceReminders !== undefined) next.practiceReminders = patch.practiceReminders;
    if (patch.timezone !== undefined && patch.timezone !== current.timezone) {
      const last = current.timezoneUpdatedAt;
      if (last && options.now.getTime() - last.getTime() < options.minTimezoneIntervalMs) {
        throw new TimezoneChangeTooSoonError(new Date(last.getTime() + options.minTimezoneIntervalMs));
      }
      next.timezone = patch.timezone;
      next.timezoneUpdatedAt = options.now;
    }
    this.profiles.set(uid, next);
    return { ...next };
  }

  async exportUserData(uid: string): Promise<UserDataExport | null> {
    const profile = this.profiles.get(uid);
    if (!profile) return null;
    const own = <T>(map: Map<string, T>) => [...map.entries()].filter(([k]) => k.startsWith(`${uid}/`));
    return {
      profile: { ...profile },
      preferences: this.preferences.get(uid) ?? null,
      usage: own(this.usage).map(([k, v]) => ({ date: k.slice(uid.length + 1), consumedSeconds: v })),
      dailyProgress: own(this.activity).map(([, v]) => ({ ...v })),
      conversations: [],
      mistakes: [],
      vocabulary: [],
    };
  }
}
