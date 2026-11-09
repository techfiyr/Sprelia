import { randomUUID } from 'node:crypto';
import type { FastifyPluginAsync } from 'fastify';
import { z } from 'zod';
import { AppError, ErrorCode, validationError } from '../../common/errors.js';
import { validate } from '../../common/validate.js';
import { authenticate, requireUser, requireVerifiedEmail } from '../auth/authenticate.js';
import type { TokenVerifier } from '../auth/token-verifier.js';
import type { CatalogService } from '../catalog/catalog.service.js';
import { localDate } from '../users/local-date.js';
import { contentLevel } from '../users/recommendation.js';
import type { UserRepository } from '../users/user.repository.js';
import { Transcript } from '../feedback/analysis.js';
import type { FeedbackRepository } from '../feedback/feedback.repository.js';
import type { AIProvider } from './ai-provider.js';
import {
  ConversationNotFoundError,
  DailyLimitReachedError,
  END_REASONS,
  SessionActiveError,
  type ConversationRecord,
  type ConversationRepository,
} from './conversation.repository.js';
import { buildSystemPrompt, openingInstruction, PERSONAS } from './personas.js';

export interface ConversationRoutesOptions {
  verifier: TokenVerifier;
  users: UserRepository;
  conversations: ConversationRepository;
  catalog: CatalogService;
  ai: AIProvider;
  now: () => Date;
  freeDailySeconds: number;
  premiumDailySeconds: number;
  maxSessionSeconds: number;
  minSessionSeconds: number;
  requireEmailVerification: boolean;
  /** Server-verified Premium entitlement (Phase 9). Never client-supplied. */
  isPremium: (uid: string) => Promise<boolean>;
  /** Stores the uploaded transcript for post-session feedback (Phase 8). */
  feedback?: FeedbackRepository;
}

const Id = z.string().uuid();
const StartBody = z
  .object({
    tutorId: z.string().regex(/^[a-z][a-z0-9-]{1,30}$/),
    scenarioId: z.string().regex(/^[a-z][a-z0-9-]{1,60}$/).nullable().optional(),
  })
  .strict();
const EndBody = z
  .object({
    reason: z.enum(END_REASONS).default('user_ended'),
    /** Live transcription captured by the app (untrusted data; size-limited; used only for feedback). */
    transcript: Transcript.optional(),
  })
  .strict();
const ListQuery = z.object({ limit: z.coerce.number().int().min(1).max(50).default(20) }).strict();

const err = (status: number, code: ErrorCode, message: string) => new AppError(status, code, message);

function serialize(c: ConversationRecord) {
  return {
    id: c.id,
    status: c.status,
    tutorId: c.tutorId,
    scenarioId: c.scenarioId,
    localDate: c.localDate,
    startedAt: c.startedAt.toISOString(),
    endedAt: c.endedAt?.toISOString() ?? null,
    reservedSeconds: c.reservedSeconds,
    billedSeconds: c.billedSeconds,
    endReason: c.endReason,
  };
}

/**
 * Voice sessions (Phases 6–7). Ownership is structural (uid from the verified token; ids are
 * looked up under users/{uid}). Usage is measured and billed on the server only; the client
 * never reports durations.
 */
export const conversationRoutes: FastifyPluginAsync<ConversationRoutesOptions> = async (app, opts) => {
  app.addHook('preHandler', authenticate(opts.verifier));
  app.addHook('preHandler', requireVerifiedEmail(opts.requireEmailVerification));
  app.addHook('onSend', async (_request, reply) => {
    reply.header('cache-control', 'private, no-store');
  });

  app.post<{ Body: z.infer<typeof StartBody> }>(
    '/me/conversations',
    { preHandler: validate({ body: StartBody }) },
    async (request, reply) => {
      const { uid } = requireUser(request);
      const profile = await opts.users.getProfile(uid);
      if (!profile || profile.onboardingStatus !== 'completed') {
        throw err(409, ErrorCode.ONBOARDING_REQUIRED, 'Please finish setting up your learning plan first.');
      }
      const tutor = opts.catalog.tutors.find((t) => t.id === request.body.tutorId);
      const persona = tutor ? PERSONAS[tutor.id] : undefined;
      if (!tutor || !persona || !tutor.voiceAvailable) {
        throw validationError([{ path: 'body.tutorId', message: 'unknown or unavailable tutor' }]);
      }

      const scenarioId = request.body.scenarioId ?? null;
      const scenario = scenarioId
        ? opts.catalog.publishedCategories().flatMap((c) => c.scenarios).find((s) => s.id === scenarioId)
        : null;
      if (scenarioId && !scenario) throw err(404, ErrorCode.SCENARIO_NOT_FOUND, 'This practice scenario is not available.');
      if (scenario && !scenario.compatibleTutorIds.includes(tutor.id)) {
        throw validationError([{ path: 'body.tutorId', message: 'this tutor does not teach this scenario' }]);
      }
      const premium = await opts.isPremium(uid);
      if (scenario?.premium && !premium) {
        throw err(403, ErrorCode.PREMIUM_REQUIRED, 'This scenario is part of Premium.');
      }
      if (!opts.ai.available) {
        throw err(503, ErrorCode.VOICE_UNAVAILABLE, 'Voice practice is not available right now. Please try again later.');
      }

      const now = opts.now();
      let record: ConversationRecord;
      try {
        record = await opts.conversations.startSession(uid, {
          id: randomUUID(),
          tutorId: tutor.id,
          scenarioId,
          localDate: localDate(profile.timezone, now),
          allowanceSeconds: premium ? opts.premiumDailySeconds : opts.freeDailySeconds,
          maxSessionSeconds: opts.maxSessionSeconds,
          minSessionSeconds: opts.minSessionSeconds,
          now,
        });
      } catch (e) {
        if (e instanceof SessionActiveError) {
          throw new AppError(409, ErrorCode.SESSION_ACTIVE, 'You already have a conversation in progress.', [
            { path: 'conversationId', message: e.conversationId },
          ]);
        }
        if (e instanceof DailyLimitReachedError) {
          throw err(403, ErrorCode.DAILY_LIMIT_REACHED, "You've used today's free speaking time. It resets at midnight.");
        }
        throw e;
      }

      const prefs = await opts.users.getPreferences(uid);
      try {
        const grant = await opts.ai.createRealtimeSession({
          systemPrompt: buildSystemPrompt({ persona, level: contentLevel(prefs), accent: prefs?.accent, scenario }),
          voiceName: persona.voiceName,
          allowedSeconds: record.reservedSeconds,
        });
        reply.status(201);
        return {
          conversationId: record.id,
          allowedDurationSeconds: record.reservedSeconds,
          expiresAt: record.expiresAt.toISOString(),
          realtime: {
            provider: grant.provider,
            token: grant.token,
            model: grant.model,
            websocketUrl: grant.websocketUrl,
            openingInstruction: openingInstruction(persona, scenario?.title),
          },
        };
      } catch (e) {
        await opts.conversations.failSession(uid, record.id, opts.now());
        request.log.error({ err: e instanceof Error ? e.name : 'unknown' }, 'realtime grant failed');
        throw err(503, ErrorCode.VOICE_UNAVAILABLE, 'Voice practice is not available right now. Please try again later.');
      }
    },
  );

  app.post<{ Params: { id: string }; Body: z.infer<typeof EndBody> }>(
    '/me/conversations/:id/end',
    { preHandler: validate({ params: z.object({ id: Id }).strict(), body: EndBody }) },
    async (request) => {
      const { uid } = requireUser(request);
      try {
        const c = await opts.conversations.endSession(uid, request.params.id, request.body.reason, opts.now());
        const transcript = request.body.transcript;
        if (opts.feedback && transcript?.length && c.status === 'ended' && !(await opts.feedback.getFeedback(uid, c.id))) {
          await opts.feedback.saveTranscript(uid, c.id, transcript, opts.now());
        }
        return { conversation: serialize(c) };
      } catch (e) {
        if (e instanceof ConversationNotFoundError) throw err(404, ErrorCode.CONVERSATION_NOT_FOUND, 'Conversation not found.');
        throw e;
      }
    },
  );

  app.get<{ Querystring: z.infer<typeof ListQuery> }>(
    '/me/conversations',
    { preHandler: validate({ query: ListQuery }) },
    async (request) => {
      const { uid } = requireUser(request);
      return { conversations: (await opts.conversations.listConversations(uid, request.query.limit)).map(serialize) };
    },
  );

  app.get<{ Params: { id: string } }>(
    '/me/conversations/:id',
    { preHandler: validate({ params: z.object({ id: Id }).strict() }) },
    async (request) => {
      const { uid } = requireUser(request);
      const c = await opts.conversations.getConversation(uid, request.params.id);
      if (!c) throw err(404, ErrorCode.CONVERSATION_NOT_FOUND, 'Conversation not found.');
      return { conversation: serialize(c) };
    },
  );
};
