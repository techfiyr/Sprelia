import type { AppCheck } from 'firebase-admin/app-check';
import type { FastifyReply, FastifyRequest, preHandlerAsyncHookHandler } from 'fastify';
import { appCheckFailed } from '../../common/errors.js';
import type { AppCheckMode } from '../../config/env.js';

/** Header set by the Flutter client (`firebase_app_check` token). Redacted in logs. */
export const APP_CHECK_HEADER = 'x-firebase-appcheck';

/** App Check tokens are JWTs of a few hundred bytes; anything far larger is not one. */
const MAX_TOKEN_LENGTH = 4096;
const JWT_SHAPE = /^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$/;

export interface AppCheckVerifier {
  /** Resolves with the Firebase app ID the token belongs to; throws if invalid. */
  verify(token: string): Promise<{ appId: string }>;
}

/** Verifies tokens with the Admin SDK (`AppCheck.verifyToken`: signature, expiry, project). */
export class FirebaseAppCheckVerifier implements AppCheckVerifier {
  constructor(private readonly appCheck: AppCheck) {}

  async verify(token: string): Promise<{ appId: string }> {
    const result = await this.appCheck.verifyToken(token);
    return { appId: result.appId };
  }
}

declare module 'fastify' {
  interface FastifyRequest {
    /** Firebase app ID from a verified App Check token (absent when unchecked or failed in monitor mode). */
    appCheckAppId?: string;
  }
}

/**
 * App Check guard for protected routes (an extra layer; the ID token stays mandatory).
 * - `off`: nothing is checked.
 * - `monitor`: tokens are verified when present; missing or invalid ones are logged and allowed.
 * - `enforce`: missing or invalid tokens are rejected with 403 APP_CHECK_FAILED (fail closed,
 *   including when verification itself fails).
 * Tokens are never logged.
 */
export function appCheckGuard(mode: AppCheckMode, verifier?: AppCheckVerifier): preHandlerAsyncHookHandler {
  if (mode !== 'off' && !verifier) throw new Error(`APP_CHECK_MODE=${mode} requires an App Check verifier`);
  return async function checkApp(request: FastifyRequest, _reply: FastifyReply) {
    if (mode === 'off') return;
    const raw = request.headers[APP_CHECK_HEADER];
    const token = typeof raw === 'string' ? raw : undefined;
    let failure: 'missing' | 'malformed' | 'invalid' | undefined;
    if (!token) failure = 'missing';
    else if (token.length > MAX_TOKEN_LENGTH || !JWT_SHAPE.test(token)) failure = 'malformed';
    else {
      try {
        request.appCheckAppId = (await verifier!.verify(token)).appId;
      } catch {
        failure = 'invalid';
      }
    }
    if (!failure) return;
    if (mode === 'enforce') throw appCheckFailed();
    request.log.warn({ appCheck: failure }, 'app check failed (monitor mode, request allowed)');
  };
}
