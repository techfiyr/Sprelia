import { describe, expect, it } from 'vitest';
import { computeStreak } from '../src/modules/users/dashboard.js';
import { addDays, lastLocalDates, localDate } from '../src/modules/users/local-date.js';
import { recommend } from '../src/modules/users/recommendation.js';
import { isValidTimeZone } from '../src/modules/users/user.schemas.js';

describe('local dates', () => {
  it('uses the learner time zone for the day boundary', () => {
    const at = new Date('2026-11-09T20:30:00Z');
    expect(localDate('UTC', at)).toBe('2026-11-09');
    expect(localDate('Asia/Dhaka', at)).toBe('2026-11-10');
    expect(localDate('America/Los_Angeles', at)).toBe('2026-11-09');
  });

  it('does calendar arithmetic across month and DST boundaries', () => {
    expect(addDays('2026-03-01', -1)).toBe('2026-02-28');
    expect(addDays('2026-11-01', 1)).toBe('2026-11-02');
    expect(lastLocalDates('UTC', new Date('2026-01-02T12:00:00Z'), 3)).toEqual(['2026-01-02', '2026-01-01', '2025-12-31']);
  });

  it('validates IANA time zones', () => {
    expect(isValidTimeZone('Asia/Dhaka')).toBe(true);
    expect(isValidTimeZone('America/Argentina/Buenos_Aires')).toBe(true);
    expect(isValidTimeZone('UTC')).toBe(true);
    expect(isValidTimeZone('Mars/Olympus')).toBe(false);
    expect(isValidTimeZone('../../etc/passwd')).toBe(false);
    expect(isValidTimeZone('')).toBe(false);
  });
});

describe('streak', () => {
  const act = (dates: string[]) =>
    new Map(dates.map((d) => [d, { date: d, speakingSeconds: 60, sessionsCompleted: 1 }]));

  it('counts consecutive days ending today', () => {
    expect(computeStreak('2026-11-10', act(['2026-11-10', '2026-11-09', '2026-11-07']))).toBe(2);
  });
  it('keeps yesterday’s streak alive before today’s practice', () => {
    expect(computeStreak('2026-11-10', act(['2026-11-09', '2026-11-08']))).toBe(2);
  });
  it('is zero after a missed day', () => {
    expect(computeStreak('2026-11-10', act(['2026-11-08']))).toBe(0);
  });
});

describe('recommend', () => {
  it('defaults to Emma and everyday practice without preferences', () => {
    expect(recommend(null)).toEqual({ tutorId: 'emma', scenarioId: 'introductions', categoryIds: ['everyday'] });
  });
  it('picks Alex for career goals above A1', () => {
    expect(recommend({ goals: ['career'], level: 'B2' })).toMatchObject({ tutorId: 'alex', scenarioId: 'job-interviews' });
  });
  it('keeps A1 career learners with Emma', () => {
    expect(recommend({ goals: ['career'], level: 'A1' }).tutorId).toBe('emma');
  });
  it('picks Sofia for intermediate travel learners and a level-appropriate scenario', () => {
    const r = recommend({ goals: ['travel_social'], level: 'B2' });
    expect(r.tutorId).toBe('sofia');
    expect(r.categoryIds).toEqual(['travel', 'social']);
    expect(r.scenarioId).toBe('travel-problems');
  });
  it('treats "not sure" as A2 for content only', () => {
    expect(recommend({ goals: ['academic'], level: 'not_sure' }).scenarioId).toBe('classroom-discussion');
  });
});
