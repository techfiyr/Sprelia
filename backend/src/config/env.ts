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
 * The PRODUCTION Firebase project (owner decision 2026-11-09, final unless the owner
 * changes it). Local development and automated tests must never use it; production
 * deployments must use exactly this project.
 */
export const PRODUCTION_FIREBASE_PROJECT_ID = 'sprelia';

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
    if (env.APP_ENV === 'production' && env.FIREBASE_PROJECT_ID !== PRODUCTION_FIREBASE_PROJECT_ID) {
      ctx.addIssue({
        code: 'custom',
        path: ['FIREBASE_PROJECT_ID'],
        message: `production must use the production project (${PRODUCTION_FIREBASE_PROJECT_ID})`,
      });
    }
    if (env.APP_ENV !== 'production' && env.FIREBASE_PROJECT_ID === PRODUCTION_FIREBASE_PROJECT_ID) {
      ctx.addIssue({
        code: 'custom',
        path: ['FIREBASE_PROJECT_ID'],
        message: 'the production project must not be used outside APP_ENV=production',
      });
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
  };
}
