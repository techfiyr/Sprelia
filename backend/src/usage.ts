/**
 * Prototype usage ledger (in memory). Production: Firestore transaction on
 * users/{uid}/usage/{localDate} plus an append-only ledger for reconciliation.
 */
interface DailyUsage {
  reservedSeconds: number;
  consumedSeconds: number;
}

interface Reservation {
  uid: string;
  dayKey: string;
  reservedSeconds: number;
  startedAt: number;
  finalized: boolean;
}

const days = new Map<string, DailyUsage>();
const reservations = new Map<string, Reservation>();

function dayKey(uid: string, timezone = 'UTC'): string {
  const date = new Intl.DateTimeFormat('en-CA', { timeZone: timezone }).format(new Date());
  return `${uid}:${date}`;
}

export function getDaily(uid: string, limitSeconds: number) {
  const usage = days.get(dayKey(uid)) ?? { reservedSeconds: 0, consumedSeconds: 0 };
  const remaining = Math.max(0, limitSeconds - usage.consumedSeconds - usage.reservedSeconds);
  return { limitSeconds, ...usage, remainingSeconds: remaining };
}

/** Reserve up to the remaining allowance. Returns 0 when the user has no time left. */
export function reserve(uid: string, conversationId: string, limitSeconds: number): number {
  const key = dayKey(uid);
  const usage = days.get(key) ?? { reservedSeconds: 0, consumedSeconds: 0 };
  const hasActive = [...reservations.values()].some((r) => r.uid === uid && !r.finalized);
  if (hasActive) throw new Error('CONCURRENT_SESSION');

  const remaining = Math.max(0, limitSeconds - usage.consumedSeconds - usage.reservedSeconds);
  if (remaining < 15) return 0;
  usage.reservedSeconds += remaining;
  days.set(key, usage);
  reservations.set(conversationId, {
    uid,
    dayKey: key,
    reservedSeconds: remaining,
    startedAt: Date.now(),
    finalized: false,
  });
  return remaining;
}

/** Idempotent. Bills server-measured wall time, capped at the reservation. Never trusts client time. */
export function finalize(conversationId: string): number | null {
  const r = reservations.get(conversationId);
  if (!r) return null;
  if (r.finalized) return Math.min(r.reservedSeconds, Math.ceil((Date.now() - r.startedAt) / 1000));
  const used = Math.min(r.reservedSeconds, Math.ceil((Date.now() - r.startedAt) / 1000));
  const usage = days.get(r.dayKey)!;
  usage.reservedSeconds -= r.reservedSeconds;
  usage.consumedSeconds += used;
  r.finalized = true;
  return used;
}

export function reservationOwner(conversationId: string): string | undefined {
  return reservations.get(conversationId)?.uid;
}

/** Release reservations whose session must have ended (token expired) without an /end call. */
export function sweepExpired(maxAgeMs: (conversationId: string) => number | undefined) {
  for (const [id, r] of reservations) {
    const max = maxAgeMs(id);
    if (!r.finalized && max !== undefined && Date.now() - r.startedAt > max) finalize(id);
  }
}

/** Cancel a reservation without billing (e.g. the provider session could not be created). */
export function release(conversationId: string) {
  const r = reservations.get(conversationId);
  if (!r || r.finalized) return;
  days.get(r.dayKey)!.reservedSeconds -= r.reservedSeconds;
  r.finalized = true;
}
