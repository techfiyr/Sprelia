const DAY_MS = 24 * 60 * 60 * 1000;

/** Local calendar date (YYYY-MM-DD) for an instant in an IANA time zone. */
export function localDate(timeZone: string, at: Date): string {
  // en-CA formats as YYYY-MM-DD.
  return new Intl.DateTimeFormat('en-CA', { timeZone, year: 'numeric', month: '2-digit', day: '2-digit' }).format(at);
}

/** Shifts a YYYY-MM-DD date by whole days (calendar arithmetic, DST-safe). */
export function addDays(date: string, days: number): string {
  const [y, m, d] = date.split('-').map(Number) as [number, number, number];
  return new Date(Date.UTC(y, m - 1, d) + days * DAY_MS).toISOString().slice(0, 10);
}

/** The last `n` local dates ending with today, newest first. */
export function lastLocalDates(timeZone: string, at: Date, n: number): string[] {
  const today = localDate(timeZone, at);
  return Array.from({ length: n }, (_, i) => addDays(today, -i));
}
