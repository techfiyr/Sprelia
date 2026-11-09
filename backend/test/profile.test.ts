import { afterEach, describe, expect, it } from 'vitest';
import type { FastifyInstance } from 'fastify';
import { InMemoryUserRepository } from '../src/modules/users/memory-user.repository.js';
import { makeApp, OTHER_TOKEN, REVOKED_TOKEN, VALID_TOKEN } from './helpers.js';

const auth = (token = VALID_TOKEN) => ({ authorization: `Bearer ${token}` });

const FULL_PREFS = {
  interfaceLanguage: 'en',
  nativeLanguage: 'bn',
  goals: ['career', 'confidence'],
  level: 'B1',
  dailyGoalMinutes: 10,
  accent: 'international',
} as const;

const PROTECTED: { method: 'GET' | 'POST' | 'PUT'; url: string; payload?: object }[] = [
  { method: 'GET', url: '/api/v1/me/profile' },
  { method: 'POST', url: '/api/v1/me/profile', payload: { timezone: 'UTC' } },
  { method: 'PUT', url: '/api/v1/me/onboarding', payload: { preferences: {} } },
  { method: 'GET', url: '/api/v1/me/dashboard' },
  { method: 'GET', url: '/api/v1/tutors' },
  { method: 'GET', url: '/api/v1/practice/categories' },
];

describe('authentication on Phase 2 endpoints', () => {
  let app: FastifyInstance;
  afterEach(() => app?.close());

  it.each(PROTECTED)('$method $url rejects missing tokens', async (route) => {
    app = await makeApp();
    const res = await app.inject({ ...route });
    expect(res.statusCode).toBe(401);
    expect(res.json().error.code).toBe('UNAUTHENTICATED');
  });

  it.each(PROTECTED)('$method $url rejects invalid tokens (before validating the body)', async (route) => {
    app = await makeApp();
    const res = await app.inject({ ...route, payload: { junk: true }, headers: auth(REVOKED_TOKEN) });
    expect(res.statusCode).toBe(401);
    expect(res.json().error.code).toBe('INVALID_TOKEN');
  });
});

describe('profile', () => {
  let app: FastifyInstance;
  afterEach(() => app?.close());

  it('returns 404 PROFILE_NOT_FOUND before creation', async () => {
    app = await makeApp();
    const res = await app.inject({ method: 'GET', url: '/api/v1/me/profile', headers: auth() });
    expect(res.statusCode).toBe(404);
    expect(res.json().error.code).toBe('PROFILE_NOT_FOUND');
  });

  it('creates the profile from the verified identity', async () => {
    app = await makeApp();
    const res = await app.inject({
      method: 'POST',
      url: '/api/v1/me/profile',
      headers: auth(),
      payload: { displayName: '  Rahim ', timezone: 'Asia/Dhaka' },
    });
    expect(res.statusCode).toBe(201);
    const { profile, created } = res.json();
    expect(created).toBe(true);
    expect(profile).toMatchObject({
      uid: 'user-123',
      email: 'learner@example.com',
      displayName: 'Rahim',
      timezone: 'Asia/Dhaka',
      onboarding: { status: 'not_started', completedAt: null, preferences: {} },
    });
    expect(res.headers['cache-control']).toBe('private, no-store');
  });

  it('is idempotent and never overwrites an existing profile', async () => {
    app = await makeApp();
    await app.inject({ method: 'POST', url: '/api/v1/me/profile', headers: auth(), payload: { displayName: 'First', timezone: 'Asia/Dhaka' } });
    const again = await app.inject({
      method: 'POST',
      url: '/api/v1/me/profile',
      headers: auth(),
      payload: { displayName: 'Second', timezone: 'Europe/London' },
    });
    expect(again.statusCode).toBe(200);
    expect(again.json().created).toBe(false);
    expect(again.json().profile).toMatchObject({ displayName: 'First', timezone: 'Asia/Dhaka' });
  });

  it.each([
    ['client-supplied uid', { timezone: 'UTC', uid: 'attacker' }],
    ['client-supplied email', { timezone: 'UTC', email: 'x@evil.test' }],
    ['protected status field', { timezone: 'UTC', onboardingStatus: 'completed' }],
    ['invalid time zone', { timezone: 'Mars/Olympus' }],
    ['missing time zone', {}],
    ['markup in display name', { timezone: 'UTC', displayName: '<script>' }],
    ['overlong display name', { timezone: 'UTC', displayName: 'x'.repeat(61) }],
  ])('rejects %s', async (_name, payload) => {
    app = await makeApp();
    const res = await app.inject({ method: 'POST', url: '/api/v1/me/profile', headers: auth(), payload });
    expect(res.statusCode).toBe(400);
    expect(res.json().error.code).toBe('VALIDATION_ERROR');
  });

  it('keeps users isolated from each other', async () => {
    const users = new InMemoryUserRepository();
    app = await makeApp({ users });
    await app.inject({ method: 'POST', url: '/api/v1/me/profile', headers: auth(), payload: { displayName: 'A', timezone: 'UTC' } });
    const other = await app.inject({ method: 'GET', url: '/api/v1/me/profile?uid=user-123', headers: auth(OTHER_TOKEN) });
    expect(other.statusCode).toBe(404);
    expect(users.profiles.has('user-456')).toBe(false);
  });
});

describe('onboarding', () => {
  let app: FastifyInstance;
  let users: InMemoryUserRepository;
  afterEach(() => app?.close());

  async function withProfile() {
    users = new InMemoryUserRepository();
    app = await makeApp({ users });
    await app.inject({ method: 'POST', url: '/api/v1/me/profile', headers: auth(), payload: { timezone: 'Asia/Dhaka' } });
  }
  const save = (payload: object, token = VALID_TOKEN) =>
    app.inject({ method: 'PUT', url: '/api/v1/me/onboarding', headers: auth(token), payload });

  it('requires a profile', async () => {
    app = await makeApp();
    const res = await save({ preferences: { level: 'A2' } });
    expect(res.statusCode).toBe(404);
    expect(res.json().error.code).toBe('PROFILE_NOT_FOUND');
  });

  it('saves partial progress as in_progress', async () => {
    await withProfile();
    const res = await save({ preferences: { interfaceLanguage: 'en', nativeLanguage: 'bn' } });
    expect(res.statusCode).toBe(200);
    expect(res.json().profile.onboarding).toMatchObject({
      status: 'in_progress',
      preferences: { interfaceLanguage: 'en', nativeLanguage: 'bn' },
    });
    expect(res.json().plan).toBeNull();
  });

  it('merges saves and completes with all preferences', async () => {
    await withProfile();
    await save({ preferences: { interfaceLanguage: 'en', nativeLanguage: 'bn' } });
    const res = await save({ preferences: FULL_PREFS, complete: true });
    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.profile.onboarding.status).toBe('completed');
    expect(body.profile.onboarding.completedAt).toEqual(expect.any(String));
    expect(body.plan.tutorId).toBe('alex');
    expect(body.plan.categoryIds).toEqual(['professional', 'everyday', 'social']);
    // Rotates among free scenarios Alex can teach at B1 in those categories.
    expect(['job-interviews', 'office-conversations', 'meetings', 'networking']).toContain(body.plan.scenarioId);
  });

  it('completes from previously saved partial progress plus the final answers', async () => {
    await withProfile();
    await save({ preferences: { interfaceLanguage: 'en', nativeLanguage: 'bn', goals: ['everyday'] } });
    const res = await save({ preferences: { level: 'A2', dailyGoalMinutes: 5, accent: 'american' }, complete: true });
    expect(res.statusCode).toBe(200);
    expect(res.json().profile.onboarding.status).toBe('completed');
    expect(res.json().profile.onboarding.preferences).toMatchObject({ nativeLanguage: 'bn', level: 'A2' });
  });

  it('refuses to complete with missing preferences and names the fields', async () => {
    await withProfile();
    const res = await save({ preferences: { level: 'A2' }, complete: true });
    expect(res.statusCode).toBe(400);
    const paths = res.json().error.details.map((d: { path: string }) => d.path);
    expect(paths).toEqual(expect.arrayContaining(['body.preferences.goals', 'body.preferences.accent']));
    expect(users.profiles.get('user-123')!.onboardingStatus).toBe('not_started');
  });

  it.each([
    ['unknown goal', { goals: ['get_rich'] }],
    ['duplicate goals', { goals: ['career', 'career'] }],
    ['empty goals', { goals: [] }],
    ['unsupported daily goal', { dailyGoalMinutes: 7 }],
    ['retired 20-minute daily goal', { dailyGoalMinutes: 20 }],
    ['unknown level', { level: 'C2' }],
    ['unsupported interface language', { interfaceLanguage: 'xx' }],
    ['malformed native language', { nativeLanguage: 'Bengali' }],
    ['unknown accent', { accent: 'pirate' }],
    ['unknown preference field', { isPremium: true }],
  ])('rejects %s', async (_name, preferences) => {
    await withProfile();
    const res = await save({ preferences });
    expect(res.statusCode).toBe(400);
    expect(res.json().error.code).toBe('VALIDATION_ERROR');
  });

  it('rejects attempts to set protected fields at the top level', async () => {
    await withProfile();
    const res = await save({ preferences: {}, uid: 'user-456', status: 'completed' });
    expect(res.statusCode).toBe(400);
  });

  it('accepts C1 as a self-reported level', async () => {
    await withProfile();
    const res = await save({ preferences: { ...FULL_PREFS, level: 'C1' }, complete: true });
    expect(res.statusCode).toBe(200);
    expect(res.json().profile.onboarding.preferences.level).toBe('C1');
    expect(res.json().plan.tutorId).toBe('alex');
  });

  it('keeps onboarding completed when preferences are edited later', async () => {
    await withProfile();
    await save({ preferences: FULL_PREFS, complete: true });
    const res = await save({ preferences: { accent: 'british' } });
    expect(res.json().profile.onboarding.status).toBe('completed');
    expect(res.json().profile.onboarding.preferences.accent).toBe('british');
  });

  it("only writes the caller's own preferences", async () => {
    await withProfile();
    const res = await save({ preferences: { level: 'A1' } }, OTHER_TOKEN);
    expect(res.statusCode).toBe(404);
    expect(users.preferences.has('user-456')).toBe(false);
    expect(users.preferences.get('user-123')).toBeUndefined();
  });
});

describe('dashboard', () => {
  let app: FastifyInstance;
  afterEach(() => app?.close());

  const NOW = new Date('2026-11-09T20:30:00Z'); // 02:30 on 2026-11-10 in Asia/Dhaka

  it('requires a profile', async () => {
    app = await makeApp();
    const res = await app.inject({ method: 'GET', url: '/api/v1/me/dashboard', headers: auth() });
    expect(res.statusCode).toBe(404);
  });

  it('reports zeros, never invented progress, for a new learner', async () => {
    app = await makeApp({ now: () => NOW });
    await app.inject({ method: 'POST', url: '/api/v1/me/profile', headers: auth(), payload: { displayName: 'Rahim', timezone: 'Asia/Dhaka' } });
    const res = await app.inject({ method: 'GET', url: '/api/v1/me/dashboard', headers: auth() });
    expect(res.statusCode).toBe(200);
    const { recommendation, ...rest } = res.json().dashboard;
    expect(rest).toEqual({
      displayName: 'Rahim',
      plan: 'free',
      dailyGoalMinutes: null,
      today: { date: '2026-11-10', timezone: 'Asia/Dhaka', speakingSeconds: 0, freeAllowanceSeconds: 600, remainingFreeSeconds: 600 },
      progress: { streakDays: 0, weeklySpeakingSeconds: 0, weeklySessions: 0 },
    });
    expect(recommendation.tutorId).toBe('emma');
    expect(recommendation.categoryIds).toEqual(['everyday']);
    expect(['introductions', 'daily-routines', 'shopping']).toContain(recommendation.scenarioId);
  });

  it('uses only server-recorded usage and activity', async () => {
    const users = new InMemoryUserRepository();
    app = await makeApp({ users, now: () => NOW });
    await app.inject({ method: 'POST', url: '/api/v1/me/profile', headers: auth(), payload: { timezone: 'Asia/Dhaka' } });
    users.usage.set('user-123/2026-11-10', 240);
    for (const [date, secs] of [['2026-11-10', 240], ['2026-11-09', 300], ['2026-11-08', 120], ['2026-11-06', 60]] as const) {
      users.activity.set(`user-123/${date}`, { date, speakingSeconds: secs, sessionsCompleted: 1 });
    }
    const res = await app.inject({ method: 'GET', url: '/api/v1/me/dashboard', headers: auth() });
    const d = res.json().dashboard;
    expect(d.today).toMatchObject({ speakingSeconds: 240, remainingFreeSeconds: 360 });
    expect(d.progress).toEqual({ streakDays: 3, weeklySpeakingSeconds: 720, weeklySessions: 4 });
  });

  it('ignores client-supplied usage values', async () => {
    app = await makeApp({ now: () => NOW });
    await app.inject({ method: 'POST', url: '/api/v1/me/profile', headers: auth(), payload: { timezone: 'UTC' } });
    const res = await app.inject({
      method: 'GET',
      url: '/api/v1/me/dashboard?remainingFreeSeconds=99999&plan=premium',
      headers: { ...auth(), 'x-plan': 'premium' },
    });
    expect(res.json().dashboard.plan).toBe('free');
    expect(res.json().dashboard.today.remainingFreeSeconds).toBe(600);
  });
});

describe('catalogue', () => {
  let app: FastifyInstance;
  afterEach(() => app?.close());

  it('lists tutors without prompts or voice configuration', async () => {
    app = await makeApp();
    const res = await app.inject({ method: 'GET', url: '/api/v1/tutors', headers: auth() });
    expect(res.statusCode).toBe(200);
    const { tutors } = res.json();
    expect(tutors.map((t: { id: string }) => t.id)).toEqual(['emma', 'alex', 'sofia']);
    expect(res.body).not.toMatch(/"(persona|systemPrompt|systemInstruction|voiceName|openingInstruction)"/);
    expect(res.body).not.toMatch(/Aoede|Charon|Kore/);
    expect(tutors.find((t: { id: string }) => t.id === 'alex').levels).toEqual({ min: 'A2', max: 'C1' });
  });

  it('lists the five practice categories from APP_FLOW §8', async () => {
    app = await makeApp();
    const res = await app.inject({ method: 'GET', url: '/api/v1/practice/categories', headers: auth() });
    const { categories } = res.json();
    expect(categories.map((c: { id: string }) => c.id)).toEqual(['everyday', 'professional', 'academic', 'travel', 'social']);
    const tutorIds = new Set(['emma', 'alex', 'sofia']);
    for (const c of categories) {
      expect(c.scenarios.length).toBeGreaterThan(0);
      for (const sc of c.scenarios) {
        expect(tutorIds.has(sc.suggestedTutorId)).toBe(true);
        expect(sc.objectives.length).toBeGreaterThan(0);
      }
    }
  });
});
