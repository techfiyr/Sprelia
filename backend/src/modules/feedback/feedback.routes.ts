import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { AppError, ErrorCode } from '../../common/errors.js';
import { validate } from '../../common/validate.js';
import { authenticate, requireUser, requireVerifiedEmail } from '../auth/authenticate.js';
import type { TokenVerifier } from '../auth/token-verifier.js';
import type { CatalogService } from '../catalog/catalog.service.js';
import type { ConversationRepository } from '../conversations/conversation.repository.js';
import { computeStreak, STREAK_LOOKBACK_DAYS } from '../users/dashboard.js';
import { lastLocalDates } from '../users/local-date.js';
import { contentLevel } from '../users/recommendation.js';
import type { UserRepository } from '../users/user.repository.js';
import { learnerWordCount, MIN_LEARNER_WORDS, type ConversationAnalyzer } from './analysis.js';
import type { FeedbackRepository } from './feedback.repository.js';

export interface FeedbackRoutesOptions {
  verifier: TokenVerifier;
  users: UserRepository;
  conversations: ConversationRepository;
  feedback: FeedbackRepository;
  analyzer: ConversationAnalyzer;
  catalog: CatalogService;
  now: () => Date;
  requireEmailVerification: boolean;
}

const IdParams = z.object({ id: z.string().uuid() }).strict();
const EntryParams = z.object({ id: z.string().regex(/^[A-Za-z0-9_-]{1,80}$/) }).strict();
const ListQuery = z.object({ limit: z.coerce.number().int().min(1).max(100).default(50) }).strict();
const notFound = () => new AppError(404, ErrorCode.CONVERSATION_NOT_FOUND, 'Conversation not found.');
const entryNotFound = () => new AppError(404, ErrorCode.NOT_FOUND, 'Not found.');

/**
 * Post-session feedback, Mistake Vault, vocabulary and progress (Phase 8). Analysis runs on the
 * backend only, after the session; results are schema-validated and filtered before storage.
 */
export const feedbackRoutes: FastifyPluginAsync<FeedbackRoutesOptions> = async (app, opts) => {
  app.addHook('preHandler', authenticate(opts.verifier));
  app.addHook('preHandler', requireVerifiedEmail(opts.requireEmailVerification));
  app.addHook('onSend', async (_request, reply) => {
    reply.header('cache-control', 'private, no-store');
  });

  /**
   * Status contract (the app polls): `pending` (session still active or analysis running),
   * `completed` {feedback}, `insufficient_speech`, `failed` {message} (retryable).
   */
  app.get<{ Params: z.infer<typeof IdParams> }>(
    '/me/conversations/:id/feedback',
    { preHandler: validate({ params: IdParams }) },
    async (request) => {
      const { uid } = requireUser(request);
      const id = request.params.id;
      const conversation = await opts.conversations.getConversation(uid, id);
      if (!conversation) throw notFound();
      if (conversation.status === 'active') return { status: 'pending' };

      const existing = await opts.feedback.getFeedback(uid, id);
      if (existing?.status === 'completed') return { status: 'completed', feedback: existing.feedback };
      if (existing?.status === 'insufficient_speech') return { status: 'insufficient_speech' };
      if (existing?.status === 'processing') return { status: 'pending' };

      const transcript = await opts.feedback.getTranscript(uid, id);
      const now = opts.now();
      if (!transcript || learnerWordCount(transcript) < MIN_LEARNER_WORDS) {
        if (await opts.feedback.claimFeedback(uid, id, now)) {
          await opts.feedback.completeFeedback(uid, id, { status: 'insufficient_speech', feedback: null }, now);
        }
        return { status: 'insufficient_speech' };
      }
      if (!opts.analyzer.available) {
        return { status: 'failed', message: "Feedback isn't available right now. Please try again later." };
      }
      if (!(await opts.feedback.claimFeedback(uid, id, now))) return { status: 'pending' };

      try {
        const prefs = await opts.users.getPreferences(uid);
        const scenarioTitle = conversation.scenarioId
          ? (opts.catalog.publishedCategories().flatMap((c) => c.scenarios).find((s) => s.id === conversation.scenarioId)?.title ?? null)
          : null;
        const feedback = await opts.analyzer.analyze({ transcript, level: contentLevel(prefs), scenarioTitle });
        await opts.feedback.completeFeedback(uid, id, { status: 'completed', feedback }, opts.now());
        return { status: 'completed', feedback };
      } catch (err) {
        await opts.feedback.releaseFeedback(uid, id);
        request.log.error({ err: err instanceof Error ? err.name : 'unknown' }, 'feedback analysis failed');
        return { status: 'failed', message: 'We could not prepare feedback for this session. Please try again.' };
      }
    },
  );

  app.get<{ Querystring: z.infer<typeof ListQuery> }>('/me/mistakes', { preHandler: validate({ query: ListQuery }) }, async (request) => {
    const { uid } = requireUser(request);
    const items = await opts.feedback.listMistakes(uid, request.query.limit);
    return { mistakes: items.map((m) => ({ ...m, createdAt: m.createdAt.toISOString() })) };
  });

  app.patch<{ Params: z.infer<typeof EntryParams>; Body: { mastered: boolean } }>(
    '/me/mistakes/:id',
    { preHandler: validate({ params: EntryParams, body: z.object({ mastered: z.boolean() }).strict() }) },
    async (request) => {
      const { uid } = requireUser(request);
      if (!(await opts.feedback.setMistakeMastered(uid, request.params.id, request.body.mastered))) throw entryNotFound();
      return { id: request.params.id, mastered: request.body.mastered };
    },
  );

  app.get<{ Querystring: z.infer<typeof ListQuery> }>('/me/vocabulary', { preHandler: validate({ query: ListQuery }) }, async (request) => {
    const { uid } = requireUser(request);
    const items = await opts.feedback.listVocabulary(uid, request.query.limit);
    return { vocabulary: items.map((v) => ({ ...v, createdAt: v.createdAt.toISOString() })) };
  });

  app.patch<{ Params: z.infer<typeof EntryParams>; Body: { learned: boolean } }>(
    '/me/vocabulary/:id',
    { preHandler: validate({ params: EntryParams, body: z.object({ learned: z.boolean() }).strict() }) },
    async (request) => {
      const { uid } = requireUser(request);
      if (!(await opts.feedback.setVocabularyLearned(uid, request.params.id, request.body.learned))) throw entryNotFound();
      return { id: request.params.id, learned: request.body.learned };
    },
  );

  /** Progress tab (APP_FLOW §15): last 30 local days, streak, sessions, learning counts. */
  app.get('/me/progress', async (request) => {
    const { uid } = requireUser(request);
    const profile = await opts.users.getProfile(uid);
    if (!profile) throw new AppError(404, ErrorCode.PROFILE_NOT_FOUND, 'Your profile has not been created yet.');
    const dates = lastLocalDates(profile.timezone, opts.now(), STREAK_LOOKBACK_DAYS);
    const [activityList, counts, recent] = await Promise.all([
      opts.users.getDailyActivity(uid, dates),
      opts.feedback.counts(uid),
      opts.conversations.listConversations(uid, 10),
    ]);
    const activity = new Map(activityList.map((a) => [a.date, a]));
    const days = dates.slice(0, 30).reverse().map((date) => ({
      date,
      speakingSeconds: activity.get(date)?.speakingSeconds ?? 0,
      sessions: activity.get(date)?.sessionsCompleted ?? 0,
    }));
    return {
      progress: {
        days,
        totals: {
          speakingSeconds: days.reduce((n, d) => n + d.speakingSeconds, 0),
          sessions: days.reduce((n, d) => n + d.sessions, 0),
        },
        streakDays: computeStreak(dates[0]!, activity),
        mistakes: { open: counts.mistakesOpen, mastered: counts.mistakesMastered },
        vocabulary: { total: counts.vocabulary, learned: counts.vocabularyLearned },
        recentSessions: recent
          .filter((c) => c.status === 'ended')
          .map((c) => ({ id: c.id, tutorId: c.tutorId, scenarioId: c.scenarioId, startedAt: c.startedAt.toISOString(), billedSeconds: c.billedSeconds })),
      },
    };
  });
};
