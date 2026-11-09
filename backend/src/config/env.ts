import { z } from 'zod';

/**
 * Environment-based configuration for the API server.
 *
 * - All values come from process env (Cloud Run env vars / Secret Manager mounts in
 *   deployed environments, `backend/.env` locally). Nothing secret is hardcoded.
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

    /** Number of proxy hops to trust for client IP (Cloud Run = 1). */
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
  };
}
