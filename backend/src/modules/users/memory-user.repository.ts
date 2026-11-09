import { missingForCompletion, type LearningPreferences } from './user.schemas.js';
import {
  OnboardingIncompleteError,
  ProfileNotFoundError,
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
}
