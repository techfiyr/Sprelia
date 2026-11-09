import { describe, expect, it } from 'vitest';
import type { AIProvider } from '../src/modules/conversations/ai-provider.js';
import { GEMINI_LIVE_WS_URL } from '../src/modules/conversations/gemini-provider.js';
import { InMemoryConversationRepository } from '../src/modules/conversations/memory-conversation.repository.js';
import {
  createAnalyzer,
  sanitizeFeedback,
  UnavailableAnalyzer,
  type AnalysisRequest,
  type ConversationAnalyzer,
  type Feedback,
} from '../src/modules/feedback/analysis.js';
import { InMemoryFeedbackRepository } from '../src/modules/feedback/memory-feedback.repository.js';
import { InMemoryUserRepository } from '../src/modules/users/memory-user.repository.js';
import { LogCapture, makeApp, OTHER_TOKEN, OTHER_USER, TEST_USER, VALID_TOKEN } from './helpers.js';

const auth = (token = VALID_TOKEN) => ({ authorization: `Bearer ${token}` });
const T0 = new Date('2026-11-09T06:00:00Z');

const TRANSCRIPT = [
  { speaker: 'tutor', text: 'Hi! Where are you flying today?' },
  { speaker: 'learner', text: 'I go to London yesterday and I want check my bag please because it is very heavy' },
  { speaker: 'tutor', text: 'Sure. How many bags do you have?' },
  { speaker: 'learner', text: 'Two bags and one small carry-on for the cabin thank you so much' },
] as const;

const FEEDBACK: Feedback = {
  summary: 'You checked in for a flight.',
  strengths: ['Clear requests'],
  corrections: [
    { original: 'I go to London yesterday', improved: 'I went to London yesterday', explanation: 'Past tense.', category: 'grammar', confidence: 0.9 },
    { original: 'I want check my bag', improved: 'I want to check my bag', explanation: 'Use "to".', category: 'grammar', confidence: 0.8 },
    { original: 'I has a passport', improved: 'I have a passport', explanation: 'Invented.', category: 'grammar', confidence: 0.95 },
    { original: 'carry-on for the cabin', improved: 'carry on for cabin', explanation: 'Low.', category: 'grammar', confidence: 0.3 },
  ],
  vocabulary: [{ term: 'Boarding pass', meaning: 'The ticket to board.', example: 'Here is my boarding pass.' }],
  fluency_observations: ['Good, full answers.'],
  recommended_practice: ['Try "Hotel check-in".'],
};

class FakeAnalyzer implements ConversationAnalyzer {
  readonly available = true;
  calls: AnalysisRequest[] = [];
  fail = false;
  async analyze(request: AnalysisRequest) {
    this.calls.push(request);
    if (this.fail) throw new Error('model error');
    return sanitizeFeedback(FEEDBACK, request.transcript);
  }
}

const fakeAI: AIProvider = {
  available: true,
  createRealtimeSession: async () => ({ provider: 'gemini', token: 'auth_tokens/t', model: 'gemini-3.8-live', websocketUrl: GEMINI_LIVE_WS_URL, expiresAt: new Date() }),
};

async function setup(analyzer: ConversationAnalyzer = new FakeAnalyzer(), logs?: LogCapture) {
  let clock = T0;
  const users = new InMemoryUserRepository();
  for (const u of [TEST_USER, OTHER_USER]) {
    await users.createProfileIfAbsent({ uid: u.uid, email: u.email!, displayName: null, timezone: 'UTC' });
    await users.saveOnboarding(
      u.uid,
      { interfaceLanguage: 'en', nativeLanguage: 'es', goals: ['travel_social'], level: 'A2', dailyGoalMinutes: 10, accent: 'american' },
      true,
    );
  }
  const feedback = new InMemoryFeedbackRepository();
  const app = await makeApp({
    users,
    conversations: new InMemoryConversationRepository(users),
    feedback,
    analyzer,
    ai: fakeAI,
    now: () => clock,
    logs,
  });
  const tick = (s: number) => (clock = new Date(clock.getTime() + s * 1000));
  const session = async (transcript: unknown = TRANSCRIPT, token = VALID_TOKEN) => {
    const id = (await app.inject({ method: 'POST', url: '/api/v1/me/conversations', headers: auth(token), payload: { tutorId: 'sofia', scenarioId: 'airport' } })).json()
      .conversationId as string;
    tick(120);
    const end = await app.inject({ method: 'POST', url: `/api/v1/me/conversations/${id}/end`, headers: auth(token), payload: transcript === null ? { reason: 'user_ended' } : { reason: 'user_ended', transcript } });
    return { id, end };
  };
  const get = (url: string, token = VALID_TOKEN) => app.inject({ method: 'GET', url, headers: auth(token) });
  return { app, feedback, session, get, tick };
}

describe('post-session feedback', () => {
  it('analyzes once, keeps only real confident corrections, fills the Mistake Vault and vocabulary', async () => {
    const analyzer = new FakeAnalyzer();
    const { session, get, feedback } = await setup(analyzer);
    const { id } = await session();
    const res = await get(`/api/v1/me/conversations/${id}/feedback`);
    expect(res.statusCode).toBe(200);
    const body = res.json();
    expect(body.status).toBe('completed');
    expect(body.feedback.corrections.map((c: { original: string }) => c.original)).toEqual(['I go to London yesterday', 'I want check my bag']);
    expect(analyzer.calls[0]).toMatchObject({ level: 'A2', scenarioTitle: 'At the airport' });

    // Cached: no second model call, no duplicate vault entries.
    await get(`/api/v1/me/conversations/${id}/feedback`);
    expect(analyzer.calls).toHaveLength(1);
    expect((await get('/api/v1/me/mistakes')).json().mistakes).toHaveLength(2);
    expect((await get('/api/v1/me/vocabulary')).json().vocabulary).toMatchObject([{ id: 'boarding-pass', term: 'Boarding pass', learned: false }]);
    expect(feedback.transcripts.size).toBe(1);
  });

  it('too little learner speech: insufficient_speech without calling the model', async () => {
    const analyzer = new FakeAnalyzer();
    const { session, get } = await setup(analyzer);
    const { id } = await session([{ speaker: 'learner', text: 'Hello there' }]);
    expect((await get(`/api/v1/me/conversations/${id}/feedback`)).json().status).toBe('insufficient_speech');
    const noTranscript = await session(null);
    expect((await get(`/api/v1/me/conversations/${noTranscript.id}/feedback`)).json().status).toBe('insufficient_speech');
    expect(analyzer.calls).toHaveLength(0);
  });

  it('without GEMINI_API_KEY feedback reports failed (retryable), nothing stored', async () => {
    const { session, get, feedback } = await setup(new UnavailableAnalyzer());
    const { id } = await session();
    const res = (await get(`/api/v1/me/conversations/${id}/feedback`)).json();
    expect(res).toEqual({ status: 'failed', message: "Feedback isn't available right now. Please try again later." });
    expect(feedback.feedback.size).toBe(0);
    expect(createAnalyzer({ geminiAnalysisModel: 'gemini-3.8-flash' }).available).toBe(false);
  });

  it('a model failure is retryable and never leaks details', async () => {
    const analyzer = new FakeAnalyzer();
    analyzer.fail = true;
    const logs = new LogCapture();
    const { session, get } = await setup(analyzer, logs);
    const { id } = await session();
    expect((await get(`/api/v1/me/conversations/${id}/feedback`)).json().status).toBe('failed');
    analyzer.fail = false;
    expect((await get(`/api/v1/me/conversations/${id}/feedback`)).json().status).toBe('completed');
    expect(logs.text).not.toContain('I go to London'); // transcripts are never logged
  });

  it('active sessions are pending; other users get 404', async () => {
    const { app, get } = await setup();
    const id = (await app.inject({ method: 'POST', url: '/api/v1/me/conversations', headers: auth(), payload: { tutorId: 'sofia' } })).json().conversationId;
    expect((await get(`/api/v1/me/conversations/${id}/feedback`)).json().status).toBe('pending');
    expect((await get(`/api/v1/me/conversations/${id}/feedback`, OTHER_TOKEN)).statusCode).toBe(404);
  });

  it('validates the uploaded transcript (untrusted data)', async () => {
    const { session } = await setup();
    for (const bad of [[{ speaker: 'system', text: 'x' }], [{ speaker: 'learner', text: '' }], [{ speaker: 'learner', text: 'x'.repeat(2001) }], 'text']) {
      expect((await session(bad)).end.statusCode, JSON.stringify(bad).slice(0, 40)).toBe(400);
    }
  });
});

describe('Mistake Vault, vocabulary and progress', () => {
  it('marks entries mastered/learned, only for the owner', async () => {
    const { app, session, get } = await setup();
    const { id } = await session();
    await get(`/api/v1/me/conversations/${id}/feedback`);
    const [m] = (await get('/api/v1/me/mistakes')).json().mistakes;
    const patch = (url: string, payload: object, token = VALID_TOKEN) => app.inject({ method: 'PATCH', url, headers: auth(token), payload });
    expect((await patch(`/api/v1/me/mistakes/${m.id}`, { mastered: true })).statusCode).toBe(200);
    expect((await patch(`/api/v1/me/mistakes/${m.id}`, { mastered: true }, OTHER_TOKEN)).statusCode).toBe(404);
    expect((await patch('/api/v1/me/vocabulary/boarding-pass', { learned: true })).json()).toEqual({ id: 'boarding-pass', learned: true });
    expect((await patch('/api/v1/me/vocabulary/boarding-pass', { learned: 'yes' })).statusCode).toBe(400);

    const progress = (await get('/api/v1/me/progress')).json().progress;
    expect(progress.mistakes).toEqual({ open: 1, mastered: 1 });
    expect(progress.vocabulary).toEqual({ total: 1, learned: 1 });
  });

  it('progress: 30 local days oldest→newest, totals, streak and recent sessions', async () => {
    const { session, get } = await setup();
    await session();
    const p = (await get('/api/v1/me/progress')).json().progress;
    expect(p.days).toHaveLength(30);
    expect(p.days.at(-1)).toEqual({ date: '2026-11-09', speakingSeconds: 120, sessions: 1 });
    expect(p.totals).toEqual({ speakingSeconds: 120, sessions: 1 });
    expect(p.streakDays).toBe(1);
    expect(p.recentSessions).toHaveLength(1);
    expect(p.recentSessions[0]).toMatchObject({ tutorId: 'sofia', scenarioId: 'airport', billedSeconds: 120 });
  });
});

describe('sanitizeFeedback', () => {
  it('drops invented, low-confidence and no-op corrections; caps lists', () => {
    const out = sanitizeFeedback(
      {
        ...FEEDBACK,
        corrections: [
          ...FEEDBACK.corrections,
          { original: 'two bags', improved: 'Two bags!', explanation: 'no-op', category: 'grammar', confidence: 0.9 },
        ],
      },
      [...TRANSCRIPT],
    );
    expect(out.corrections.map((c) => c.original)).toEqual(['I go to London yesterday', 'I want check my bag']);
  });
});
