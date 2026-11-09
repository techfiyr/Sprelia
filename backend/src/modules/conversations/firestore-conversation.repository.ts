import { FieldValue, Timestamp, type DocumentData, type Firestore, type Transaction } from 'firebase-admin/firestore';
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

const SCHEMA_VERSION = 1;

function toDate(v: unknown): Date | null {
  return v instanceof Timestamp ? v.toDate() : v instanceof Date ? v : null;
}
const num = (v: unknown) => (typeof v === 'number' && Number.isFinite(v) && v > 0 ? Math.floor(v) : 0);

function toRecord(id: string, d: DocumentData): ConversationRecord {
  return {
    id,
    status: d.status === 'ended' || d.status === 'failed' ? d.status : 'active',
    tutorId: String(d.tutorId ?? ''),
    scenarioId: typeof d.scenarioId === 'string' ? d.scenarioId : null,
    localDate: String(d.localDate ?? ''),
    startedAt: toDate(d.startedAt) ?? new Date(0),
    expiresAt: toDate(d.expiresAt) ?? new Date(0),
    reservedSeconds: num(d.reservedSeconds),
    billedSeconds: typeof d.billedSeconds === 'number' ? num(d.billedSeconds) : null,
    endedAt: toDate(d.endedAt),
    endReason: typeof d.endReason === 'string' ? (d.endReason as EndReason) : null,
  };
}

export class FirestoreConversationRepository implements ConversationRepository {
  constructor(private readonly db: Firestore) {}

  private user(uid: string) {
    return this.db.collection('users').doc(uid);
  }
  private convo(uid: string, id: string) {
    return this.user(uid).collection('conversations').doc(id);
  }

  /**
   * Prepares billing [c] inside [tx]. It performs no reads (increments only), so it is safe to
   * call after the caller's reads; `write()` must be called once, after all reads.
   */
  private billInTx(tx: Transaction, uid: string, c: ConversationRecord, reason: EndReason, now: Date) {
    const billed = billableSeconds(c, now > c.expiresAt ? c.expiresAt : now);
    const usageRef = this.user(uid).collection('usage').doc(c.localDate);
    const progressRef = this.user(uid).collection('dailyProgress').doc(c.localDate);
    return {
      billed,
      write: () => {
        const at = Timestamp.fromDate(now);
        tx.update(this.convo(uid, c.id), { status: 'ended', billedSeconds: billed, endedAt: at, endReason: reason });
        tx.set(usageRef, { consumedSeconds: FieldValue.increment(billed), updatedAt: at, schemaVersion: SCHEMA_VERSION }, { merge: true });
        tx.set(
          progressRef,
          {
            speakingSeconds: FieldValue.increment(billed),
            sessionsCompleted: FieldValue.increment(billed > 0 ? 1 : 0),
            updatedAt: at,
            schemaVersion: SCHEMA_VERSION,
          },
          { merge: true },
        );
        tx.create(this.user(uid).collection('usageLedger').doc(), {
          conversationId: c.id,
          localDate: c.localDate,
          seconds: billed,
          reason,
          at,
          schemaVersion: SCHEMA_VERSION,
        });
      },
    };
  }

  async startSession(uid: string, input: StartSessionInput): Promise<ConversationRecord> {
    // The transaction returns the outcome instead of throwing for "limit reached", so that the
    // cleanup of a stale session (billing it, clearing the active marker) is still committed.
    const outcome = await this.db.runTransaction(async (tx) => {
      const userSnap = await tx.get(this.user(uid));
      if (!userSnap.exists) throw new ProfileNotFoundError();
      const activeId = userSnap.get('activeConversationId');
      let stale: ConversationRecord | null = null;
      if (typeof activeId === 'string') {
        const snap = await tx.get(this.convo(uid, activeId));
        if (snap.exists) {
          const c = toRecord(snap.id, snap.data()!);
          if (c.status === 'active' && input.now < c.expiresAt) throw new SessionActiveError(c.id);
          if (c.status === 'active') stale = c;
        }
      }
      const usageSnap = await tx.get(this.user(uid).collection('usage').doc(input.localDate));
      // All reads are done; writes follow.
      let consumed = num(usageSnap.get('consumedSeconds'));
      if (stale) {
        const bill = this.billInTx(tx, uid, stale, 'expired', input.now);
        bill.write();
        if (stale.localDate === input.localDate) consumed += bill.billed;
      }
      const remaining = Math.max(0, input.allowanceSeconds - consumed);
      if (remaining < input.minSessionSeconds) {
        if (stale) tx.update(this.user(uid), { activeConversationId: null });
        return { limit: remaining, record: null };
      }
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
      tx.create(this.convo(uid, input.id), {
        ...record,
        startedAt: Timestamp.fromDate(record.startedAt),
        expiresAt: Timestamp.fromDate(record.expiresAt),
        schemaVersion: SCHEMA_VERSION,
      });
      tx.update(this.user(uid), { activeConversationId: input.id });
      return { limit: null, record };
    });
    if (outcome.record === null) throw new DailyLimitReachedError(outcome.limit ?? 0);
    return outcome.record;
  }

  async endSession(uid: string, id: string, reason: EndReason, now: Date): Promise<ConversationRecord> {
    return this.db.runTransaction(async (tx) => {
      const snap = await tx.get(this.convo(uid, id));
      if (!snap.exists) throw new ConversationNotFoundError();
      const c = toRecord(id, snap.data()!);
      if (c.status !== 'active') return c;
      const userSnap = await tx.get(this.user(uid));
      const bill = this.billInTx(tx, uid, c, reason, now);
      bill.write();
      if (userSnap.get('activeConversationId') === id) tx.update(this.user(uid), { activeConversationId: null });
      return { ...c, status: 'ended', billedSeconds: bill.billed, endedAt: now, endReason: reason };
    });
  }

  async failSession(uid: string, id: string, now: Date): Promise<void> {
    await this.db.runTransaction(async (tx) => {
      const snap = await tx.get(this.convo(uid, id));
      const userSnap = await tx.get(this.user(uid));
      if (!snap.exists || snap.get('status') !== 'active') return;
      tx.update(this.convo(uid, id), { status: 'failed', billedSeconds: 0, endedAt: Timestamp.fromDate(now), endReason: 'start_failed' });
      if (userSnap.get('activeConversationId') === id) tx.update(this.user(uid), { activeConversationId: null });
    });
  }

  async getConversation(uid: string, id: string): Promise<ConversationRecord | null> {
    const snap = await this.convo(uid, id).get();
    return snap.exists ? toRecord(id, snap.data()!) : null;
  }

  async listConversations(uid: string, limit: number): Promise<ConversationRecord[]> {
    const snap = await this.user(uid).collection('conversations').orderBy('startedAt', 'desc').limit(limit).get();
    return snap.docs.map((d) => toRecord(d.id, d.data()));
  }
}
