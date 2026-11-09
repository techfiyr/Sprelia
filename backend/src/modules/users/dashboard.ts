import type { DailyActivity, UserProfile, UserRepository } from './user.repository.js';
import { addDays, lastLocalDates } from './local-date.js';
import { recommend, type Recommendation } from './recommendation.js';

export const STREAK_LOOKBACK_DAYS = 60;

export interface Dashboard {
  displayName: string | null;
  /** Phase 2: always "free". Entitlements arrive with RevenueCat (Phase 9); never client-supplied. */
  plan: 'free';
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
  options: { now: Date; freeDailySeconds: number },
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

  return {
    displayName: profile.displayName,
    plan: 'free',
    dailyGoalMinutes: prefs?.dailyGoalMinutes ?? null,
    today: {
      date: today,
      timezone: profile.timezone,
      speakingSeconds: activity.get(today)?.speakingSeconds ?? 0,
      freeAllowanceSeconds: options.freeDailySeconds,
      remainingFreeSeconds: Math.max(0, options.freeDailySeconds - usageSeconds),
    },
    progress: {
      streakDays: computeStreak(today, activity),
      weeklySpeakingSeconds: week.reduce((n, d) => n + (activity.get(d)?.speakingSeconds ?? 0), 0),
      weeklySessions: week.reduce((n, d) => n + (activity.get(d)?.sessionsCompleted ?? 0), 0),
    },
    recommendation: recommend(prefs),
  };
}
