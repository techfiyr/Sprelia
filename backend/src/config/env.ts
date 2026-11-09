import { z } from 'zod';

/**
 * Environment-based configuration for the API server.
 *
 * - All values come from process env (Netlify environment variables when deployed,
 *   `backend/.env` locally). Nothing secret is hardcoded.
 * - Parsing fails fast at startup with a list of invalid keys (never their values).
 * - Unsafe combinations are rejected for staging/production (see `superRefine`).
 */

/**
 * The single approved Firebase project (owner architecture decision 2026-11-09, which
 * supersedes the earlier separate development project). It serves development and
 * eventual production. No other real project is accepted.
 *
 * - `production` and `staging` must use exactly this project.
 * - `development` may use it (with test accounts only) or a `demo-*` emulator project.
 * - `test` (automated tests) must use a `demo-*` project on the emulators: fail closed.
 */
export const FIREBASE_PROJECT_ID = 'sprelia';

export const APP_CHECK_MODES = ['off', 'monitor', 'enforce'] as const;

/**
 * Service-account credential parsed from the FIREBASE_SERVICE_ACCOUNT_JSON secret (hosts without
 * Google Cloud workload identity, e.g. Netlify; owner hosting decision 2026-11-09).
 * `privateKey` is NON-ENUMERABLE so JSON serialization and structured logging never include it.
 */
export interface FirebaseServiceAccount {
  readonly projectId: string;
  readonly clientEmail: string;
  readonly privateKey: string;
}

const MAX_SERVICE_ACCOUNT_JSON_LENGTH = 16 * 1024;
const SERVICE_ACCOUNT_EMAIL = /^[a-z0-9][a-z0-9-]{4,61}@[a-z][a-z0-9-]{4,28}[a-z0-9]\.iam\.gserviceaccount\.com$/;

/**
 * Strictly validates a service-account JSON document. Never returns or echoes any part of the
 * input in errors (JSON.parse messages can quote the input, so they are discarded).
 */
export function parseServiceAccountJson(
  raw: string,
  expectedProjectId: string,
): { ok: true; value: FirebaseServiceAccount } | { ok: false; reason: string } {
  if (raw.length > MAX_SERVICE_ACCOUNT_JSON_LENGTH) return { ok: false, reason: 'is too large to be a service account key' };
  let doc: unknown;
  try {
    doc = JSON.parse(raw);
  } catch {
    return { ok: false, reason: 'must be the service account key file content as one valid JSON value' };
  }
  if (typeof doc !== 'object' || doc === null || Array.isArray(doc)) return { ok: false, reason: 'must be a JSON object' };
  const d = doc as Record<string, unknown>;
  if (d.type !== 'service_account') return { ok: false, reason: 'must be a service account key (type service_account)' };
  if (d.project_id !== expectedProjectId) return { ok: false, reason: 'belongs to a different project than FIREBASE_PROJECT_ID' };
  if (typeof d.client_email !== 'string' || !SERVICE_ACCOUNT_EMAIL.test(d.client_email)) {
    return { ok: false, reason: 'has a missing or invalid client_email' };
  }
  if (!d.client_email.endsWith(`@${expectedProjectId}.iam.gserviceaccount.com`)) {
    return { ok: false, reason: 'client_email belongs to a different project' };
  }
  const key = d.private_key;
  if (typeof key !== 'string' || !key.includes('-----BEGIN PRIVATE KEY-----') || !key.includes('-----END PRIVATE KEY-----')) {
    return { ok: false, reason: 'has a missing or malformed private_key' };
  }
  const value = { projectId: expectedProjectId, clientEmail: d.client_email } as FirebaseServiceAccount;
  Object.defineProperty(value, 'privateKey', { value: key, enumerable: false, writable: false });
  return { ok: true, value: Object.freeze(value) };
}
export type AppCheckMode = (typeof APP_CHECK_MODES)[number];

const booleanString = z
  .enum(['true', 'false'])
  .transform((v) => v === 'true');

const EnvSchema = z
  .object({
    APP_ENV: z.enum(['development', 'test', 'staging', 'production']).default('development'),
    PORT: z.coerce.number().int().min(1).max(65535).default(8080),
    HOST: z.string().min(1).default('0.0.0.0'),
    LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent']).default('info'),

    /** Firebase / Google Cloud project that issues the ID tokens we accept. */
    FIREBASE_PROJECT_ID: z
      .string()
      .regex(/^[a-z][a-z0-9-]{4,28}[a-z0-9]$/, 'must be a Firebase project ID (not the project number)'),

    /**
     * Local development only. When set, firebase-admin accepts tokens from the Auth
     * emulator (which are unsigned). Forbidden outside development/test.
     */
    FIREBASE_AUTH_EMULATOR_HOST: z.string().min(1).optional(),

    /** Local development only: use the Firestore emulator. Forbidden outside development/test. */
    FIRESTORE_EMULATOR_HOST: z.string().min(1).optional(),

    /** Free plan AI speaking allowance per local day (APP_DEVELOPMENT §2: 10 minutes). */
    FREE_DAILY_SECONDS: z.coerce.number().int().min(0).max(24 * 3600).default(600),

    /** Also reject tokens revoked via revokeRefreshTokens (one extra Auth API call). */
    AUTH_CHECK_REVOKED: booleanString.default(true),

    /** Number of proxy hops to trust for client IP (Netlify: must be 0; the adapter uses context.ip). */
    TRUST_PROXY_HOPS: z.coerce.number().int().min(0).max(5).default(0),

    /** Requests per minute per client IP across /api. */
    RATE_LIMIT_PER_MINUTE: z.coerce.number().int().min(1).max(10_000).default(120),

    /**
     * Serve scenarios that have not passed human review. Defaults to true outside
     * production; forced false in production (owner decision: review before publishing).
     */
    CATALOG_INCLUDE_DRAFTS: booleanString.optional(),

    /**
     * Firebase App Check on protected routes. `off`: not checked. `monitor`: verified when
     * present, failures logged but allowed. `enforce`: missing or invalid tokens rejected.
     * Defaults: production enforce (required), staging monitor, otherwise off.
     */
    APP_CHECK_MODE: z.enum(APP_CHECK_MODES).optional(),

    /** Email/password accounts must verify their email before using /me resources. */
    REQUIRE_EMAIL_VERIFICATION: booleanString.default(true),

    /**
     * SECRET (optional). The full service-account key JSON, for hosts without Google Cloud
     * workload identity (Netlify; owner authorized as a Netlify environment secret).
     * When unset, Application Default Credentials are used (local
     * `gcloud auth application-default login`, or the attached service account on Google Cloud).
     * Never logged; validation errors never include its content.
     */
    FIREBASE_SERVICE_ACCOUNT_JSON: z.string().min(1).optional(),

    /** Sensitive operations (account deletion) need a sign-in at most this many seconds ago. */
    RECENT_AUTH_MAX_AGE_SECONDS: z.coerce.number().int().min(60).max(3600).default(300),
  })
  .superRefine((env, ctx) => {
    const deployed = env.APP_ENV === 'staging' || env.APP_ENV === 'production';
    if (deployed && env.FIREBASE_AUTH_EMULATOR_HOST) {
      ctx.addIssue({
        code: 'custom',
        path: ['FIREBASE_AUTH_EMULATOR_HOST'],
        message: 'must not be set in staging/production (emulator tokens are unsigned)',
      });
    }
    if (deployed && env.FIRESTORE_EMULATOR_HOST) {
      ctx.addIssue({
        code: 'custom',
        path: ['FIRESTORE_EMULATOR_HOST'],
        message: 'must not be set in staging/production',
      });
    }
    const project = env.FIREBASE_PROJECT_ID;
    const demo = project.startsWith('demo-');
    if (deployed && project !== FIREBASE_PROJECT_ID) {
      ctx.addIssue({
        code: 'custom',
        path: ['FIREBASE_PROJECT_ID'],
        message: `staging/production must use the approved project (${FIREBASE_PROJECT_ID})`,
      });
    }
    if (env.APP_ENV === 'test' && !demo) {
      // Automated tests never touch a real project (fail closed).
      ctx.addIssue({ code: 'custom', path: ['FIREBASE_PROJECT_ID'], message: 'APP_ENV=test requires a demo-* emulator project' });
    }
    if (!demo && project !== FIREBASE_PROJECT_ID) {
      ctx.addIssue({
        code: 'custom',
        path: ['FIREBASE_PROJECT_ID'],
        message: `only the approved project (${FIREBASE_PROJECT_ID}) or a demo-* emulator project is allowed`,
      });
    }
    if (demo && !env.FIREBASE_AUTH_EMULATOR_HOST && env.APP_ENV !== 'test') {
      ctx.addIssue({ code: 'custom', path: ['FIREBASE_AUTH_EMULATOR_HOST'], message: 'demo-* projects only work with the emulators' });
    }
    if (env.APP_ENV === 'production' && env.APP_CHECK_MODE !== undefined && env.APP_CHECK_MODE !== 'enforce') {
      ctx.addIssue({ code: 'custom', path: ['APP_CHECK_MODE'], message: 'must be enforce in production' });
    }
    if (env.FIREBASE_SERVICE_ACCOUNT_JSON !== undefined) {
      if (env.APP_ENV === 'test' || demo || env.FIREBASE_AUTH_EMULATOR_HOST || env.FIRESTORE_EMULATOR_HOST) {
        ctx.addIssue({
          code: 'custom',
          path: ['FIREBASE_SERVICE_ACCOUNT_JSON'],
          message: 'must not be set with the emulators, demo projects or APP_ENV=test',
        });
      } else {
        const parsed = parseServiceAccountJson(env.FIREBASE_SERVICE_ACCOUNT_JSON, project);
        if (!parsed.ok) ctx.addIssue({ code: 'custom', path: ['FIREBASE_SERVICE_ACCOUNT_JSON'], message: parsed.reason });
      }
    }
    if (deployed && !env.REQUIRE_EMAIL_VERIFICATION) {
      ctx.addIssue({ code: 'custom', path: ['REQUIRE_EMAIL_VERIFICATION'], message: 'must be true in staging/production' });
    }
    if (env.APP_ENV === 'production' && env.CATALOG_INCLUDE_DRAFTS === true) {
      ctx.addIssue({
        code: 'custom',
        path: ['CATALOG_INCLUDE_DRAFTS'],
        message: 'unreviewed scenarios cannot be published in production',
      });
    }
    if (deployed && !env.AUTH_CHECK_REVOKED) {
      ctx.addIssue({
        code: 'custom',
        path: ['AUTH_CHECK_REVOKED'],
        message: 'must be true in staging/production',
      });
    }
  });

export interface AppConfig {
  appEnv: 'development' | 'test' | 'staging' | 'production';
  port: number;
  host: string;
  logLevel: 'fatal' | 'error' | 'warn' | 'info' | 'debug' | 'trace' | 'silent';
  firebaseProjectId: string;
  firebaseAuthEmulatorHost?: string;
  firestoreEmulatorHost?: string;
  freeDailySeconds: number;
  authCheckRevoked: boolean;
  trustProxyHops: number;
  rateLimitPerMinute: number;
  catalogIncludeDrafts: boolean;
  appCheckMode: AppCheckMode;
  requireEmailVerification: boolean;
  recentAuthMaxAgeSeconds: number;
  /** Set only when FIREBASE_SERVICE_ACCOUNT_JSON is provided (its private key is non-enumerable). */
  firebaseServiceAccount?: FirebaseServiceAccount;
}

export class ConfigError extends Error {
  constructor(public readonly issues: string[]) {
    super(`Invalid configuration:\n  - ${issues.join('\n  - ')}`);
    this.name = 'ConfigError';
  }
}

/** Parses and validates configuration. Error messages name keys, never values. */
export function loadConfig(env: NodeJS.ProcessEnv = process.env): AppConfig {
  const parsed = EnvSchema.safeParse(env);
  if (!parsed.success) {
    throw new ConfigError(
      parsed.error.issues.map((i) => `${i.path.join('.') || '(root)'}: ${i.message}`),
    );
  }
  const e = parsed.data;
  return {
    appEnv: e.APP_ENV,
    port: e.PORT,
    host: e.HOST,
    logLevel: e.LOG_LEVEL,
    firebaseProjectId: e.FIREBASE_PROJECT_ID,
    firebaseAuthEmulatorHost: e.FIREBASE_AUTH_EMULATOR_HOST,
    firestoreEmulatorHost: e.FIRESTORE_EMULATOR_HOST,
    freeDailySeconds: e.FREE_DAILY_SECONDS,
    authCheckRevoked: e.AUTH_CHECK_REVOKED,
    trustProxyHops: e.TRUST_PROXY_HOPS,
    rateLimitPerMinute: e.RATE_LIMIT_PER_MINUTE,
    catalogIncludeDrafts: e.CATALOG_INCLUDE_DRAFTS ?? e.APP_ENV !== 'production',
    appCheckMode: e.APP_CHECK_MODE ?? (e.APP_ENV === 'production' ? 'enforce' : e.APP_ENV === 'staging' ? 'monitor' : 'off'),
    requireEmailVerification: e.REQUIRE_EMAIL_VERIFICATION,
    recentAuthMaxAgeSeconds: e.RECENT_AUTH_MAX_AGE_SECONDS,
    firebaseServiceAccount: serviceAccount(e.FIREBASE_SERVICE_ACCOUNT_JSON, e.FIREBASE_PROJECT_ID),
  };
}

function serviceAccount(raw: string | undefined, projectId: string): FirebaseServiceAccount | undefined {
  if (raw === undefined) return undefined;
  const parsed = parseServiceAccountJson(raw, projectId);
  // Already validated in the schema; this cannot fail here.
  if (!parsed.ok) throw new ConfigError([`FIREBASE_SERVICE_ACCOUNT_JSON: ${parsed.reason}`]);
  return parsed.value;
}
