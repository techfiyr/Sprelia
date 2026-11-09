import type { DailyActivity, UserProfile, UserRepository } from './user.repository.js';
import { addDays, lastLocalDates } from './local-date.js';
import type { CatalogService } from '../catalog/catalog.service.js';
import { recommend, type Recommendation } from './recommendation.js';

export const STREAK_LOOKBACK_DAYS = 60;

export interface Dashboard {
  displayName: string | null;
  /** Phase 2: always "free". Entitlements arrive with RevenueCat (Phase 9); never client-supplied. */
  plan: 'free' | 'premium';
  dailyGoalMinutes: number | null;
  today: {
    date: string;
    timezone: string;
    speakingSeconds: number;
    freeAllowanceSeconds: number;
    remainingFreeSeconds: number;
  };
  progress: {
    streakDays: number;
    weeklySpeakingSeconds: number;
    weeklySessions: number;
  };
  recommendation: Recommendation;
}

/** Consecutive practice days ending today (or yesterday, if today has no session yet). */
export function computeStreak(today: string, activity: Map<string, DailyActivity>): number {
  const practiced = (d: string) => (activity.get(d)?.sessionsCompleted ?? 0) > 0;
  let day = practiced(today) ? today : addDays(today, -1);
  let streak = 0;
  while (practiced(day) && streak < STREAK_LOOKBACK_DAYS) {
    streak++;
    day = addDays(day, -1);
  }
  return streak;
}

/**
 * Builds the home dashboard purely from server-recorded data. Missing data
 * means zero; nothing is estimated or invented (APP_FLOW §6, BRAND §7).
 */
export async function buildDashboard(
  users: UserRepository,
  profile: UserProfile,
  options: { now: Date; freeDailySeconds: number; catalog: CatalogService; premium?: boolean; premiumDailySeconds?: number },
): Promise<Dashboard> {
  const dates = lastLocalDates(profile.timezone, options.now, STREAK_LOOKBACK_DAYS);
  const today = dates[0]!;
  const [prefs, usageSeconds, activityList] = await Promise.all([
    users.getPreferences(profile.uid),
    users.getUsageSeconds(profile.uid, today),
    users.getDailyActivity(profile.uid, dates),
  ]);
  const activity = new Map(activityList.map((a) => [a.date, a]));
  const week = dates.slice(0, 7);
  const allowance = options.premium ? (options.premiumDailySeconds ?? options.freeDailySeconds) : options.freeDailySeconds;

  return {
    displayName: profile.displayName,
    plan: options.premium ? 'premium' : 'free',
    dailyGoalMinutes: prefs?.dailyGoalMinutes ?? null,
    today: {
      date: today,
      timezone: profile.timezone,
      speakingSeconds: activity.get(today)?.speakingSeconds ?? 0,
      // Today's allowance for this user's plan (field names kept for API compatibility).
      freeAllowanceSeconds: allowance,
      remainingFreeSeconds: Math.max(0, allowance - usageSeconds),
    },
    progress: {
      streakDays: computeStreak(today, activity),
      weeklySpeakingSeconds: week.reduce((n, d) => n + (activity.get(d)?.speakingSeconds ?? 0), 0),
      weeklySessions: week.reduce((n, d) => n + (activity.get(d)?.sessionsCompleted ?? 0), 0),
    },
    // Premium scenarios are recommended only with a server-verified entitlement.
    recommendation: recommend(prefs, {
      includePremium: options.premium ?? false,
      categories: options.catalog.publishedCategories(),
      tutors: options.catalog.tutors,
      seed: `${profile.uid}:${today}`,
      chosenTutorId: profile.preferredTutorId,
    }),
  };
}
