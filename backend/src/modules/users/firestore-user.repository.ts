import { FieldPath, Timestamp, type DocumentData, type Firestore } from 'firebase-admin/firestore';
import { LearningPreferences, missingForCompletion } from './user.schemas.js';
import {
  OnboardingIncompleteError,
  ProfileNotFoundError,
  type DailyActivity,
  TimezoneChangeTooSoonError,
  type OnboardingStatus,
  type ProfilePatch,
  type UserDataExport,
  type UserProfile,
  type UserRepository,
} from './user.repository.js';

const SCHEMA_VERSION = 1;

/**
 * Firestore layout (APP_DEVELOPMENT §6):
 *   users/{uid}                          profile (this file)
 *   users/{uid}/preferences/learning     onboarding preferences
 *   users/{uid}/usage/{YYYY-MM-DD}       server-only usage ledger (read here, written in Phase 7)
 *   users/{uid}/dailyProgress/{date}     server-only activity (read here, written in Phase 7–8)
 */
export class FirestoreUserRepository implements UserRepository {
  constructor(private readonly db: Firestore) {}

  private userRef(uid: string) {
    return this.db.collection('users').doc(uid);
  }
  private prefsRef(uid: string) {
    return this.userRef(uid).collection('preferences').doc('learning');
  }

  async getProfile(uid: string): Promise<UserProfile | null> {
    const snap = await this.userRef(uid).get();
    return snap.exists ? toProfile(uid, snap.data()!) : null;
  }

  async createProfileIfAbsent(input: {
    uid: string;
    email: string | null;
    displayName: string | null;
    timezone: string;
  }): Promise<{ profile: UserProfile; created: boolean }> {
    const ref = this.userRef(input.uid);
    return this.db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (snap.exists) return { profile: toProfile(input.uid, snap.data()!), created: false };
      const now = Timestamp.now();
      const doc = {
        uid: input.uid,
        email: input.email,
        displayName: input.displayName,
        timezone: input.timezone,
        onboardingStatus: 'not_started' satisfies OnboardingStatus,
        onboardingCompletedAt: null,
        preferredTutorId: null,
        practiceReminders: false,
        timezoneUpdatedAt: null,
        createdAt: now,
        updatedAt: now,
        schemaVersion: SCHEMA_VERSION,
      };
      tx.create(ref, doc);
      return { profile: toProfile(input.uid, doc), created: true };
    });
  }

  async getPreferences(uid: string): Promise<Partial<LearningPreferences> | null> {
    const snap = await this.prefsRef(uid).get();
    return snap.exists ? toPreferences(snap.data()!) : null;
  }

  async saveOnboarding(
    uid: string,
    preferences: Partial<LearningPreferences>,
    complete: boolean,
  ): Promise<{ profile: UserProfile; preferences: Partial<LearningPreferences> }> {
    const userRef = this.userRef(uid);
    const prefsRef = this.prefsRef(uid);
    return this.db.runTransaction(async (tx) => {
      const [userSnap, prefsSnap] = await Promise.all([tx.get(userRef), tx.get(prefsRef)]);
      if (!userSnap.exists) throw new ProfileNotFoundError();
      const current = toProfile(uid, userSnap.data()!);
      const merged = { ...(prefsSnap.exists ? toPreferences(prefsSnap.data()!) : {}), ...preferences };
      if (complete) {
        const missing = missingForCompletion(merged);
        if (missing.length) throw new OnboardingIncompleteError(missing);
      }
      const now = Timestamp.now();

      const status: OnboardingStatus =
        current.onboardingStatus === 'completed' || complete ? 'completed' : 'in_progress';
      const completedAt =
        current.onboardingCompletedAt ?? (status === 'completed' ? now.toDate() : null);

      tx.set(prefsRef, { ...merged, updatedAt: now, schemaVersion: SCHEMA_VERSION });
      tx.update(userRef, {
        onboardingStatus: status,
        onboardingCompletedAt: completedAt ? Timestamp.fromDate(completedAt) : null,
        updatedAt: now,
      });
      return {
        profile: { ...current, onboardingStatus: status, onboardingCompletedAt: completedAt, updatedAt: now.toDate() },
        preferences: merged,
      };
    });
  }

  async deleteUserData(uid: string): Promise<void> {
    // Deletes the profile document and all nested subcollections (preferences, usage,
    // dailyProgress and any future ones). Missing documents are not an error.
    await this.db.recursiveDelete(this.userRef(uid));
  }

  async updateProfile(uid: string, patch: ProfilePatch, options: { now: Date; minTimezoneIntervalMs: number }): Promise<UserProfile> {
    const ref = this.userRef(uid);
    return this.db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      if (!snap.exists) throw new ProfileNotFoundError();
      const current = toProfile(uid, snap.data()!);
      const now = Timestamp.fromDate(options.now);
      const update: Record<string, unknown> = { updatedAt: now };
      if (patch.displayName !== undefined) update.displayName = patch.displayName;
      if (patch.preferredTutorId !== undefined) update.preferredTutorId = patch.preferredTutorId;
      if (patch.practiceReminders !== undefined) update.practiceReminders = patch.practiceReminders;
      if (patch.timezone !== undefined && patch.timezone !== current.timezone) {
        const last = current.timezoneUpdatedAt;
        if (last && options.now.getTime() - last.getTime() < options.minTimezoneIntervalMs) {
          throw new TimezoneChangeTooSoonError(new Date(last.getTime() + options.minTimezoneIntervalMs));
        }
        update.timezone = patch.timezone;
        update.timezoneUpdatedAt = now;
      }
      tx.update(ref, update);
      return toProfile(uid, { ...snap.data()!, ...update });
    });
  }

  async exportUserData(uid: string): Promise<UserDataExport | null> {
    const ref = this.userRef(uid);
    const [snap, prefs, usage, progress] = await Promise.all([
      ref.get(),
      this.getPreferences(uid),
      ref.collection('usage').get(),
      ref.collection('dailyProgress').get(),
    ]);
    if (!snap.exists) return null;
    return {
      profile: toProfile(uid, snap.data()!),
      preferences: prefs,
      usage: usage.docs.map((d) => ({ date: d.id, consumedSeconds: nonNegative(d.get('consumedSeconds')) })),
      dailyProgress: progress.docs.map((d) => ({
        date: d.id,
        speakingSeconds: nonNegative(d.get('speakingSeconds')),
        sessionsCompleted: nonNegative(d.get('sessionsCompleted')),
      })),
    };
  }

  async getUsageSeconds(uid: string, date: string): Promise<number> {
    const snap = await this.userRef(uid).collection('usage').doc(date).get();
    const consumed = snap.exists ? snap.get('consumedSeconds') : 0;
    return typeof consumed === 'number' && consumed > 0 ? consumed : 0;
  }

  async getDailyActivity(uid: string, dates: string[]): Promise<DailyActivity[]> {
    if (dates.length === 0) return [];
    const sorted = [...dates].sort();
    const snap = await this.userRef(uid)
      .collection('dailyProgress')
      .where(FieldPath.documentId(), '>=', sorted[0]!)
      .where(FieldPath.documentId(), '<=', sorted[sorted.length - 1]!)
      .get();
    const wanted = new Set(dates);
    return snap.docs
      .filter((d) => wanted.has(d.id))
      .map((d) => ({
        date: d.id,
        speakingSeconds: nonNegative(d.get('speakingSeconds')),
        sessionsCompleted: nonNegative(d.get('sessionsCompleted')),
      }));
  }
}

function nonNegative(v: unknown): number {
  return typeof v === 'number' && Number.isFinite(v) && v > 0 ? Math.floor(v) : 0;
}

function toDate(v: unknown): Date | null {
  if (v instanceof Timestamp) return v.toDate();
  if (v instanceof Date) return v;
  return null;
}

function toProfile(uid: string, d: DocumentData): UserProfile {
  const status = d.onboardingStatus;
  return {
    uid,
    email: typeof d.email === 'string' ? d.email : null,
    displayName: typeof d.displayName === 'string' ? d.displayName : null,
    timezone: typeof d.timezone === 'string' ? d.timezone : 'UTC',
    onboardingStatus: status === 'in_progress' || status === 'completed' ? status : 'not_started',
    onboardingCompletedAt: toDate(d.onboardingCompletedAt),
    preferredTutorId: typeof d.preferredTutorId === 'string' ? d.preferredTutorId : null,
    practiceReminders: d.practiceReminders === true,
    timezoneUpdatedAt: toDate(d.timezoneUpdatedAt),
    createdAt: toDate(d.createdAt) ?? new Date(0),
    updatedAt: toDate(d.updatedAt) ?? new Date(0),
  };
}

/**
 * Re-validates stored data field by field so a corrupted or outdated value (e.g. a
 * retired daily goal of 20 minutes) drops only that field, never the whole document.
 */
function toPreferences(d: DocumentData): Partial<LearningPreferences> {
  const out: Record<string, unknown> = {};
  for (const [key, field] of Object.entries(LearningPreferences.shape)) {
    if (!(key in d)) continue;
    const parsed = field.safeParse(d[key]);
    if (parsed.success) out[key] = parsed.data;
  }
  return out as Partial<LearningPreferences>;
}
