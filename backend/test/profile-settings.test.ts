import { describe, expect, it } from 'vitest';
import { InMemoryUserRepository } from '../src/modules/users/memory-user.repository.js';
import { makeApp, OTHER_TOKEN, OTHER_USER, TEST_USER, VALID_TOKEN } from './helpers.js';

const auth = (token = VALID_TOKEN) => ({ authorization: `Bearer ${token}` });
const T0 = new Date('2026-11-09T08:00:00Z');

async function setup(now = () => T0) {
  const users = new InMemoryUserRepository();
  await users.createProfileIfAbsent({ uid: TEST_USER.uid, email: TEST_USER.email!, displayName: 'Rahim', timezone: 'Asia/Dhaka' });
  await users.saveOnboarding(
    TEST_USER.uid,
    { interfaceLanguage: 'en', nativeLanguage: 'bn', goals: ['career'], level: 'B1', dailyGoalMinutes: 10, accent: 'british' },
    true,
  );
  const app = await makeApp({ users, now });
  return { app, users };
}

describe('PATCH /me/profile', () => {
  it('updates display name, preferred tutor and reminders; never server-owned fields', async () => {
    const { app } = await setup();
    const res = await app.inject({
      method: 'PATCH',
      url: '/api/v1/me/profile',
      headers: auth(),
      payload: { displayName: 'Rahim K', preferredTutorId: 'sofia', practiceReminders: true },
    });
    expect(res.statusCode).toBe(200);
    expect(res.json().profile).toMatchObject({ displayName: 'Rahim K', preferredTutorId: 'sofia', practiceReminders: true });

    for (const payload of [{ uid: 'x' }, { email: 'x@example.com' }, { onboardingStatus: 'completed' }, {}]) {
      const bad = await app.inject({ method: 'PATCH', url: '/api/v1/me/profile', headers: auth(), payload });
      expect(bad.statusCode, JSON.stringify(payload)).toBe(400);
    }
  });

  it('rejects unknown tutors and invalid values', async () => {
    const { app } = await setup();
    for (const payload of [{ preferredTutorId: 'nobody' }, { displayName: '<script>' }, { timezone: 'Mars/Base' }, { practiceReminders: 'yes' }]) {
      const res = await app.inject({ method: 'PATCH', url: '/api/v1/me/profile', headers: auth(), payload });
      expect(res.statusCode, JSON.stringify(payload)).toBe(400);
    }
  });

  it('clears the display name and preferred tutor with null', async () => {
    const { app } = await setup();
    const res = await app.inject({ method: 'PATCH', url: '/api/v1/me/profile', headers: auth(), payload: { displayName: null, preferredTutorId: null } });
    expect(res.json().profile).toMatchObject({ displayName: null, preferredTutorId: null });
  });

  it('limits time zone changes to one per day (quota boundary)', async () => {
    let now = T0;
    const { app } = await setup(() => now);
    const change = (timezone: string) => app.inject({ method: 'PATCH', url: '/api/v1/me/profile', headers: auth(), payload: { timezone } });
    expect((await change('Europe/London')).statusCode).toBe(200);
    expect((await change('Europe/London')).statusCode).toBe(200); // same zone: not a change
    const tooSoon = await change('Asia/Tokyo');
    expect(tooSoon.statusCode).toBe(429);
    expect(tooSoon.json().error.code).toBe('TIMEZONE_CHANGE_TOO_SOON');
    now = new Date(T0.getTime() + 24 * 3600 * 1000 + 1000);
    expect((await change('Asia/Tokyo')).json().profile.timezone).toBe('Asia/Tokyo');
  });

  it('the preferred tutor drives the recommendation only where that tutor fits', async () => {
    const { app } = await setup();
    const dashboardTutor = async () =>
      (await app.inject({ method: 'GET', url: '/api/v1/me/dashboard', headers: auth() })).json().dashboard.recommendation.tutorId;
    await app.inject({ method: 'PATCH', url: '/api/v1/me/preferences', headers: auth(), payload: { preferences: { goals: ['travel_social'] } } });
    expect(await dashboardTutor()).toBe('sofia'); // automatic choice for travel at B1
    await app.inject({ method: 'PATCH', url: '/api/v1/me/profile', headers: auth(), payload: { preferredTutorId: 'emma' } });
    expect(await dashboardTutor()).toBe('emma');
    // Career at B1: Emma has no compatible professional scenario, so a suitable tutor is used.
    await app.inject({ method: 'PATCH', url: '/api/v1/me/preferences', headers: auth(), payload: { preferences: { goals: ['career'] } } });
    expect(await dashboardTutor()).toBe('alex');
  });
});

describe('PATCH /me/preferences', () => {
  it('edits learning preferences after onboarding without resetting completion', async () => {
    const { app } = await setup();
    const res = await app.inject({
      method: 'PATCH',
      url: '/api/v1/me/preferences',
      headers: auth(),
      payload: { preferences: { level: 'B2', goals: ['travel_social', 'everyday'], dailyGoalMinutes: 15 } },
    });
    expect(res.statusCode).toBe(200);
    expect(res.json().profile.onboarding).toMatchObject({
      status: 'completed',
      preferences: { level: 'B2', goals: ['travel_social', 'everyday'], dailyGoalMinutes: 15, accent: 'british', nativeLanguage: 'bn' },
    });
  });

  it('validates every field and rejects empty or unknown input', async () => {
    const { app } = await setup();
    for (const preferences of [{}, { level: 'C2' }, { dailyGoalMinutes: 20 }, { goals: [] }, { accent: 'pirate' }, { nativeLanguage: 'Bengali' }, { extra: 1 }]) {
      const res = await app.inject({ method: 'PATCH', url: '/api/v1/me/preferences', headers: auth(), payload: { preferences } });
      expect(res.statusCode, JSON.stringify(preferences)).toBe(400);
    }
  });

  it('requires a profile', async () => {
    const app = await makeApp();
    const res = await app.inject({ method: 'PATCH', url: '/api/v1/me/preferences', headers: auth(), payload: { preferences: { level: 'A2' } } });
    expect(res.statusCode).toBe(404);
  });
});

describe('GET /me/export', () => {
  it('returns only the caller’s own data as a downloadable JSON document', async () => {
    const { app, users } = await setup();
    users.usage.set(`${TEST_USER.uid}/2026-11-09`, 300);
    users.activity.set(`${TEST_USER.uid}/2026-11-09`, { date: '2026-11-09', speakingSeconds: 300, sessionsCompleted: 2 });
    await users.createProfileIfAbsent({ uid: OTHER_USER.uid, email: OTHER_USER.email!, displayName: 'Other', timezone: 'UTC' });
    users.usage.set(`${OTHER_USER.uid}/2026-11-09`, 999);

    const res = await app.inject({ method: 'GET', url: '/api/v1/me/export', headers: auth() });
    expect(res.statusCode).toBe(200);
    expect(res.headers['content-disposition']).toContain('attachment');
    expect(res.headers['cache-control']).toBe('private, no-store');
    const body = res.json();
    expect(body).toMatchObject({ format: 'sprelia-export-v1', profile: { uid: TEST_USER.uid, displayName: 'Rahim' } });
    expect(body.usage).toEqual([{ date: '2026-11-09', consumedSeconds: 300 }]);
    expect(body.dailyProgress).toEqual([{ date: '2026-11-09', speakingSeconds: 300, sessionsCompleted: 2 }]);
    expect(JSON.stringify(body)).not.toContain(OTHER_USER.uid);

    const other = await app.inject({ method: 'GET', url: '/api/v1/me/export', headers: auth(OTHER_TOKEN) });
    expect(other.json().profile.uid).toBe(OTHER_USER.uid);
  });
});
