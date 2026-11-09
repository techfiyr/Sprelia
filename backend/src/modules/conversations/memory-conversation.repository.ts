import type { InMemoryUserRepository } from '../users/memory-user.repository.js';
import { ProfileNotFoundError } from '../users/user.repository.js';
import {
  billableSeconds,
  ConversationNotFoundError,
  DailyLimitReachedError,
  SessionActiveError,
  type ConversationRecord,
  type ConversationRepository,
  type EndReason,
  type StartSessionInput,
} from './conversation.repository.js';

/**
 * In-memory twin of FirestoreConversationRepository for unit tests. Shares usage and activity
 * with an InMemoryUserRepository so dashboards reflect billing. Not used in deployed builds.
 */
export class InMemoryConversationRepository implements ConversationRepository {
  readonly conversations = new Map<string, ConversationRecord>(); // `${uid}/${id}`
  readonly active = new Map<string, string>(); // uid → conversation id
  readonly ledger: { uid: string; conversationId: string; localDate: string; seconds: number; reason: EndReason }[] = [];

  constructor(private readonly users: InMemoryUserRepository) {}

  private bill(uid: string, c: ConversationRecord, reason: EndReason, now: Date): ConversationRecord {
    const billed = billableSeconds(c, now > c.expiresAt ? c.expiresAt : now);
    const key = `${uid}/${c.localDate}`;
    this.users.usage.set(key, (this.users.usage.get(key) ?? 0) + billed);
    const a = this.users.activity.get(key) ?? { date: c.localDate, speakingSeconds: 0, sessionsCompleted: 0 };
    this.users.activity.set(key, {
      date: c.localDate,
      speakingSeconds: a.speakingSeconds + billed,
      sessionsCompleted: a.sessionsCompleted + (billed > 0 ? 1 : 0),
    });
    this.ledger.push({ uid, conversationId: c.id, localDate: c.localDate, seconds: billed, reason });
    const ended: ConversationRecord = { ...c, status: 'ended', billedSeconds: billed, endedAt: now, endReason: reason };
    this.conversations.set(`${uid}/${c.id}`, ended);
    if (this.active.get(uid) === c.id) this.active.delete(uid);
    return ended;
  }

  async startSession(uid: string, input: StartSessionInput): Promise<ConversationRecord> {
    if (!this.users.profiles.has(uid)) throw new ProfileNotFoundError();
    const activeId = this.active.get(uid);
    if (activeId) {
      const c = this.conversations.get(`${uid}/${activeId}`);
      if (c?.status === 'active' && input.now < c.expiresAt) throw new SessionActiveError(c.id);
      if (c?.status === 'active') this.bill(uid, c, 'expired', input.now);
      else this.active.delete(uid);
    }
    const consumed = this.users.usage.get(`${uid}/${input.localDate}`) ?? 0;
    const remaining = Math.max(0, input.allowanceSeconds - consumed);
    if (remaining < input.minSessionSeconds) throw new DailyLimitReachedError(remaining);
    const reservedSeconds = Math.min(remaining, input.maxSessionSeconds);
    const record: ConversationRecord = {
      id: input.id,
      status: 'active',
      tutorId: input.tutorId,
      scenarioId: input.scenarioId,
      localDate: input.localDate,
      startedAt: input.now,
      expiresAt: new Date(input.now.getTime() + reservedSeconds * 1000),
      reservedSeconds,
      billedSeconds: null,
      endedAt: null,
      endReason: null,
    };
    this.conversations.set(`${uid}/${input.id}`, record);
    this.active.set(uid, input.id);
    return { ...record };
  }

  async endSession(uid: string, id: string, reason: EndReason, now: Date): Promise<ConversationRecord> {
    const c = this.conversations.get(`${uid}/${id}`);
    if (!c) throw new ConversationNotFoundError();
    if (c.status !== 'active') return { ...c };
    return this.bill(uid, c, reason, now);
  }

  async failSession(uid: string, id: string, now: Date): Promise<void> {
    const c = this.conversations.get(`${uid}/${id}`);
    if (!c || c.status !== 'active') return;
    this.conversations.set(`${uid}/${id}`, { ...c, status: 'failed', billedSeconds: 0, endedAt: now, endReason: 'start_failed' });
    if (this.active.get(uid) === id) this.active.delete(uid);
  }

  async getConversation(uid: string, id: string): Promise<ConversationRecord | null> {
    const c = this.conversations.get(`${uid}/${id}`);
    return c ? { ...c } : null;
  }

  async listConversations(uid: string, limit: number): Promise<ConversationRecord[]> {
    return [...this.conversations.entries()]
      .filter(([k]) => k.startsWith(`${uid}/`))
      .map(([, v]) => ({ ...v }))
      .sort((a, b) => b.startedAt.getTime() - a.startedAt.getTime())
      .slice(0, limit);
  }
}
