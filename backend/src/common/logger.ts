import { pino, type DestinationStream, type Logger } from 'pino';
import type { AppConfig } from '../config/env.js';

/**
 * Structured JSON logger compatible with Google Cloud Logging:
 * `severity` instead of numeric `level`, `message` instead of `msg`.
 *
 * Credentials and personal data must never be logged. Known sensitive paths are
 * redacted as a safety net; request/response bodies are not logged at all.
 */
export const REDACT_PATHS = [
  'req.headers.authorization',
  'req.headers.cookie',
  'req.headers["x-firebase-appcheck"]',
  'headers.authorization',
  'authorization',
  'token',
  'idToken',
  '*.token',
  '*.idToken',
  '*.password',
  '*.apiKey',
  'privateKey',
  '*.privateKey',
  'private_key',
  '*.private_key',
  'firebaseServiceAccount',
  '*.firebaseServiceAccount',
  'FIREBASE_SERVICE_ACCOUNT_JSON',
  '*.FIREBASE_SERVICE_ACCOUNT_JSON',
];

const SEVERITY: Record<string, string> = {
  trace: 'DEBUG',
  debug: 'DEBUG',
  info: 'INFO',
  warn: 'WARNING',
  error: 'ERROR',
  fatal: 'CRITICAL',
};

export function createLogger(config: Pick<AppConfig, 'logLevel' | 'appEnv'>, destination?: DestinationStream): Logger {
  return pino(
    {
      level: config.logLevel,
      messageKey: 'message',
      base: { env: config.appEnv },
      redact: { paths: REDACT_PATHS, censor: '[REDACTED]' },
      formatters: {
        level: (label) => ({ severity: SEVERITY[label] ?? 'DEFAULT' }),
      },
      serializers: {
        // Log only what is needed to trace a request. No query string (may contain
        // tokens in some clients), no body, no IP beyond what rate limiting needs.
        req: (req: { id: string; method: string; routeOptions?: { url?: string }; url: string }) => ({
          id: req.id,
          method: req.method,
          route: req.routeOptions?.url ?? req.url.split('?')[0],
        }),
        res: (res: { statusCode: number }) => ({ statusCode: res.statusCode }),
      },
      timestamp: pino.stdTimeFunctions.isoTime,
    },
    destination,
  );
}
