import { describe, expect, it } from 'vitest';
import { computeStreak } from '../src/modules/users/dashboard.js';
import { addDays, lastLocalDates, localDate } from '../src/modules/users/local-date.js';
import { CatalogService } from '../src/modules/catalog/catalog.service.js';
import { contentLevel, recommend } from '../src/modules/users/recommendation.js';
import { ENGLISH_LEVELS, LEARNING_GOALS, isValidTimeZone } from '../src/modules/users/user.schemas.js';

const GOALS = LEARNING_GOALS;
const LEVELS = ENGLISH_LEVELS;

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
  const catalog = new CatalogService({ includeDrafts: true });
  const opts = (seed = 's') => ({ categories: catalog.publishedCategories(), tutors: catalog.tutors, seed });

  it('defaults to Emma and an Emma-compatible everyday scenario without preferences', () => {
    const r = recommend(null, opts());
    expect(r.tutorId).toBe('emma');
    expect(r.categoryIds).toEqual(['everyday']);
    expect(['introductions', 'daily-routines', 'shopping']).toContain(r.scenarioId);
  });

  it('picks Alex for career goals above A1 and a scenario Alex can teach', () => {
    const r = recommend({ goals: ['career'], level: 'B2' }, opts());
    expect(r.tutorId).toBe('alex');
    expect(['job-interviews', 'office-conversations', 'meetings']).toContain(r.scenarioId);
  });

  it('gives A1 career learners a beginner work scenario with Emma', () => {
    expect(recommend({ goals: ['career'], level: 'A1' }, opts())).toMatchObject({ tutorId: 'emma', scenarioId: 'talking-about-work' });
    expect(recommend({ goals: ['academic'], level: 'A1' }, opts())).toMatchObject({ tutorId: 'emma', scenarioId: 'classroom-basics' });
  });

  it('supports C1 learners with Alex', () => {
    const r = recommend({ goals: ['business'], level: 'C1' }, opts());
    expect(r.tutorId).toBe('alex');
    expect(['job-interviews', 'meetings']).toContain(r.scenarioId);
  });

  it('falls back to the closest level when no scenario covers the learner (C1 everyday)', () => {
    const r = recommend({ goals: ['everyday'], level: 'C1' }, opts());
    expect(r.scenarioId).not.toBeNull();
    expect(['hobbies', 'food-restaurants']).toContain(r.scenarioId);
    expect(r.tutorId).toBe('sofia');
  });

  it('treats "not sure" as A2 for content only', () => {
    expect(contentLevel({ level: 'not_sure' })).toBe('A2');
  });

  it('is stable for a seed and rotates across seeds', () => {
    const prefs = { goals: ['travel_social' as const], level: 'B1' as const };
    expect(recommend(prefs, opts('u:2026-11-09'))).toEqual(recommend(prefs, opts('u:2026-11-09')));
    const seen = new Set(Array.from({ length: 40 }, (_, i) => recommend(prefs, opts(`u:${i}`)).scenarioId));
    expect(seen.size).toBeGreaterThan(3);
  });

  it('never recommends premium scenarios on the free plan', () => {
    const premium = new Set(catalog.publishedCategories().flatMap((c) => c.scenarios.filter((s) => s.premium).map((s) => s.id)));
    for (const g of GOALS) for (const l of LEVELS) for (let i = 0; i < 30; i++) {
      expect(premium.has(recommend({ goals: [g], level: l }, opts(String(i))).scenarioId ?? '')).toBe(false);
    }
  });

  it('can recommend every free scenario, always paired with a compatible tutor', () => {
    const cats = catalog.publishedCategories();
    const free = new Set(cats.flatMap((c) => c.scenarios.filter((s) => !s.premium).map((s) => s.id)));
    const reached = new Set<string>();
    for (const g of GOALS) for (const l of LEVELS) for (let i = 0; i < 60; i++) {
      const r = recommend({ goals: [g], level: l }, opts(`seed-${i}`));
      if (!r.scenarioId) continue;
      reached.add(r.scenarioId);
      const c = cats.find((x) => x.scenarios.some((s) => s.id === r.scenarioId))!;
      const s = c.scenarios.find((x) => x.id === r.scenarioId)!;
      expect(s.compatibleTutorIds, `${r.tutorId} for ${s.id}`).toContain(r.tutorId);
    }
    expect([...free].filter((id) => !reached.has(id))).toEqual([]);
  });
});
