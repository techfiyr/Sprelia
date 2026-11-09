import express, { type NextFunction, type Request, type Response } from 'express';
import { randomUUID } from 'node:crypto';
import { z } from 'zod';
import { analyzeConversation, type Feedback, type TranscriptLine } from './analysis.js';
import { config } from './config.js';
import { createLiveToken } from './tokens.js';
import { buildSystemPrompt, tutors } from './tutors.js';
import * as usage from './usage.js';

type FeedbackRecord =
  | { status: 'pending' }
  | { status: 'completed'; feedback: Feedback }
  | { status: 'insufficient_speech' }
  | { status: 'failed'; message: string };

interface Conversation {
  id: string;
  uid: string;
  tutorId: string;
  status: 'active' | 'completed';
  allowedSeconds: number;
  expiresAt: Date;
  usageSeconds?: number;
  transcript?: TranscriptLine[];
  feedback?: FeedbackRecord;
}

// Prototype store. Production: Firestore users/{uid}/conversations/{id}.
const conversations = new Map<string, Conversation>();

const app = express();
app.use(express.json({ limit: '1mb' }));

// --- Auth -------------------------------------------------------------------
declare module 'express-serve-static-core' {
  interface Request {
    uid?: string;
  }
}

function auth(req: Request, res: Response, next: NextFunction) {
  if (config.devSkipAuth) {
    const devUid = req.header('x-dev-user-id');
    if (devUid) {
      req.uid = devUid;
      return next();
    }
  }
  // TODO(auth): verify `Authorization: Bearer <Firebase ID token>` with firebase-admin.
  return res.status(401).json({ message: 'Authentication required' });
}

app.get('/healthz', (_req, res) => {
  res.json({ ok: true });
});

app.use('/v1', auth);

function ownedConversation(req: Request, res: Response): Conversation | undefined {
  const c = conversations.get(String(req.params.id));
  if (!c || c.uid !== req.uid) {
    res.status(404).json({ message: 'Conversation not found' });
    return undefined;
  }
  return c;
}

// --- Usage ------------------------------------------------------------------
app.get('/v1/usage/daily', (req, res) => {
  res.json(usage.getDaily(req.uid!, config.freeDailySeconds));
});

// --- Conversations ------------------------------------------------------------
const CreateConversation = z.object({
  tutorId: z.string(),
  scenarioId: z.string().optional(),
  mode: z.enum(['free', 'scenario']).default('free'),
});

app.post('/v1/conversations', async (req, res) => {
  const body = CreateConversation.safeParse(req.body);
  if (!body.success) return res.status(400).json({ message: 'Invalid request' });

  const tutor = tutors[body.data.tutorId];
  if (!tutor?.active) return res.status(404).json({ message: 'Tutor not available' });

  const uid = req.uid!;
  const id = randomUUID();
  // TODO(subscription): read the server-verified entitlement; premium gets a higher limit.
  let allowedSeconds: number;
  try {
    allowedSeconds = usage.reserve(uid, id, config.freeDailySeconds);
  } catch {
    return res.status(409).json({ code: 'CONCURRENT_SESSION', message: 'You already have a conversation in progress.' });
  }
  if (allowedSeconds === 0) {
    return res.status(402).json({
      code: 'FREE_LIMIT_REACHED',
      message: "You've used today's free speaking time. Come back tomorrow or upgrade to Premium.",
    });
  }

  try {
    // TODO(learner-context): load level and goals from Firestore.
    const systemPrompt = buildSystemPrompt(tutor, { level: 'A2' });
    const grant = await createLiveToken({ tutor, systemPrompt, allowedSeconds });

    conversations.set(id, {
      id,
      uid,
      tutorId: tutor.id,
      status: 'active',
      allowedSeconds,
      expiresAt: grant.expiresAt,
    });

    res.status(201).json({
      conversationId: id,
      allowedDurationSeconds: allowedSeconds,
      expiresAt: grant.expiresAt.toISOString(),
      realtime: {
        provider: 'gemini-live',
        token: grant.token,
        model: config.liveModel,
        websocketUrl: config.liveWebsocketUrl,
        openingInstruction: tutor.openingInstruction,
      },
    });
  } catch (err) {
    usage.release(id);
    console.error('createLiveToken failed', err instanceof Error ? err.message : err);
    res.status(502).json({ message: 'Could not start a voice session. Please try again.' });
  }
});

const EndConversation = z.object({
  reason: z.string().max(64).optional(),
  clientElapsedSeconds: z.number().int().nonnegative().optional(),
  transcript: z
    .array(z.object({ speaker: z.enum(['user', 'tutor']), text: z.string().max(4000) }))
    .max(500)
    .default([]),
});

app.post('/v1/conversations/:id/end', (req, res) => {
  const c = ownedConversation(req, res);
  if (!c) return;
  const body = EndConversation.safeParse(req.body);
  if (!body.success) return res.status(400).json({ message: 'Invalid request' });

  // Idempotent: a repeated /end returns the same result without re-billing or re-analysing.
  if (c.status === 'completed') {
    return res.json({ conversationId: c.id, usageSeconds: c.usageSeconds, feedbackStatus: c.feedback?.status });
  }

  c.usageSeconds = usage.finalize(c.id) ?? 0;
  c.status = 'completed';
  c.transcript = body.data.transcript.filter((l) => l.text.trim().length > 0);

  const learnerWords = c.transcript
    .filter((l) => l.speaker === 'user')
    .reduce((n, l) => n + l.text.split(/\s+/).filter(Boolean).length, 0);

  if (learnerWords < 15) {
    c.feedback = { status: 'insufficient_speech' };
  } else {
    c.feedback = { status: 'pending' };
    // Prototype: run analysis in-process. Production: Cloud Tasks job.
    void analyzeConversation({ transcript: c.transcript, learnerLevel: 'A2' })
      .then((feedback) => {
        c.feedback = { status: 'completed', feedback };
      })
      .catch((err) => {
        console.error('analysis failed', c.id, err instanceof Error ? err.message : err);
        c.feedback = { status: 'failed', message: 'We could not generate feedback for this session.' };
      });
  }

  console.log(
    JSON.stringify({ event: 'conversation_completed', id: c.id, usageSeconds: c.usageSeconds, reason: body.data.reason, learnerWords }),
  );
  res.json({ conversationId: c.id, usageSeconds: c.usageSeconds, feedbackStatus: c.feedback.status });
});

app.get('/v1/conversations/:id', (req, res) => {
  const c = ownedConversation(req, res);
  if (!c) return;
  res.json({ id: c.id, tutorId: c.tutorId, status: c.status, usageSeconds: c.usageSeconds });
});

app.get('/v1/conversations/:id/feedback', (req, res) => {
  const c = ownedConversation(req, res);
  if (!c) return;
  res.json(c.feedback ?? { status: 'pending' });
});

// Reconcile sessions that ended without an /end call (app killed, network lost).
setInterval(() => {
  usage.sweepExpired((id) => {
    const c = conversations.get(id);
    // Token expires at allowedSeconds + 30s; allow another minute for a late /end.
    return c ? c.allowedSeconds * 1000 + 90_000 : undefined;
  });
}, 60_000).unref();

app.listen(config.port, () => {
  console.log(`Sprelia prototype backend on :${config.port}${config.devSkipAuth ? ' (DEV_SKIP_AUTH on)' : ''}`);
});
