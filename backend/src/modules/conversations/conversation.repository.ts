/**
 * Voice sessions and the daily allowance ledger (APP_DEVELOPMENT §10). Every method is keyed by
 * the verified caller's uid. Usage is measured and written by the server only.
 *
 * Firestore layout:
 *   users/{uid}                                activeConversationId (one active session per user)
 *   users/{uid}/conversations/{id}             session record (status, reservation, billing)
 *   users/{uid}/usage/{YYYY-MM-DD}             consumedSeconds (authoritative daily usage)
 *   users/{uid}/usageLedger/{auto}             append-only billing entries
 *   users/{uid}/dailyProgress/{YYYY-MM-DD}     speakingSeconds, sessionsCompleted
 */
export type ConversationStatus = 'active' | 'ended' | 'failed';
export const END_REASONS = ['user_ended', 'time_limit', 'connection_lost', 'error', 'app_closed'] as const;
export type EndReason = (typeof END_REASONS)[number] | 'expired' | 'start_failed';

export interface ConversationRecord {
  id: string;
  status: ConversationStatus;
  tutorId: string;
  scenarioId: string | null;
  /** Local calendar day (user's time zone) the session is billed to. */
  localDate: string;
  startedAt: Date;
  /** Reservation end: the session cannot run (or be billed) past this. */
  expiresAt: Date;
  reservedSeconds: number;
  billedSeconds: number | null;
  endedAt: Date | null;
  endReason: EndReason | null;
}

export interface StartSessionInput {
  id: string;
  tutorId: string;
  scenarioId: string | null;
  localDate: string;
  allowanceSeconds: number;
  maxSessionSeconds: number;
  minSessionSeconds: number;
  now: Date;
}

export interface ConversationRepository {
  /**
   * Atomically: closes a stale (expired) active session, checks the daily allowance, and reserves
   * min(remaining, maxSessionSeconds). Throws SessionActiveError, DailyLimitReachedError.
   */
  startSession(uid: string, input: StartSessionInput): Promise<ConversationRecord>;

  /**
   * Bills server-measured time (now − startedAt, capped at the reservation) once. Idempotent:
   * ending an ended session returns it unchanged. Throws ConversationNotFoundError.
   */
  endSession(uid: string, id: string, reason: EndReason, now: Date): Promise<ConversationRecord>;

  /** Marks a session that never started (e.g. provider failure) as failed, billing nothing. */
  failSession(uid: string, id: string, now: Date): Promise<void>;

  getConversation(uid: string, id: string): Promise<ConversationRecord | null>;

  /** Most recent first. */
  listConversations(uid: string, limit: number): Promise<ConversationRecord[]>;
}

export class SessionActiveError extends Error {
  constructor(public readonly conversationId: string) {
    super('a session is already active');
    this.name = 'SessionActiveError';
  }
}

export class DailyLimitReachedError extends Error {
  constructor(public readonly remainingSeconds: number) {
    super('daily allowance used');
    this.name = 'DailyLimitReachedError';
  }
}

export class ConversationNotFoundError extends Error {
  constructor() {
    super('conversation not found');
    this.name = 'ConversationNotFoundError';
  }
}

/** Server-measured billable seconds for a session ending at [now]. */
export function billableSeconds(c: Pick<ConversationRecord, 'startedAt' | 'reservedSeconds'>, now: Date): number {
  const elapsed = Math.floor((now.getTime() - c.startedAt.getTime()) / 1000);
  return Math.max(0, Math.min(elapsed, c.reservedSeconds));
}
