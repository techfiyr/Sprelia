import type { FastifyReply, FastifyRequest, preHandlerAsyncHookHandler } from 'fastify';
import { emailNotVerified, unauthenticated, invalidToken } from '../../common/errors.js';
import type { AuthenticatedUser, TokenVerifier } from './token-verifier.js';

declare module 'fastify' {
  interface FastifyRequest {
    /** Set by `authenticate`. Present on every route that uses it. */
    user?: AuthenticatedUser;
  }
}

/** Firebase ID tokens are ~1 KB; anything far larger is not a token. */
const MAX_TOKEN_LENGTH = 4096;
const JWT_SHAPE = /^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]*$/;

export function extractBearerToken(header: string | undefined): string {
  if (!header) throw unauthenticated();
  const match = /^Bearer ([^\s]+)$/.exec(header);
  if (!match) throw unauthenticated();
  const token = match[1]!;
  if (token.length > MAX_TOKEN_LENGTH || !JWT_SHAPE.test(token)) throw invalidToken();
  return token;
}

/**
 * Authentication middleware: requires `Authorization: Bearer <Firebase ID token>`,
 * verifies it and sets `request.user`. Attach to every protected route (or register
 * as an `onRequest`/`preHandler` hook on a protected plugin scope).
 */
export function authenticate(verifier: TokenVerifier): preHandlerAsyncHookHandler {
  return async function authenticateRequest(request: FastifyRequest, _reply: FastifyReply) {
    const token = extractBearerToken(request.headers.authorization);
    request.user = await verifier.verify(token);
  };
}

/**
 * Requires a verified email for email/password accounts (owner decision D1, recommended).
 * Federated providers (Google) assert verified emails themselves. Attach after `authenticate`.
 */
export function requireVerifiedEmail(enabled: boolean): preHandlerAsyncHookHandler {
  return async function verifiedEmail(request: FastifyRequest, _reply: FastifyReply) {
    if (!enabled) return;
    const user = requireUser(request);
    if (user.signInProvider === 'password' && !user.emailVerified) throw emailNotVerified();
  };
}

/** Returns the verified user or throws. Use inside handlers behind `authenticate`. */
export function requireUser(request: FastifyRequest): AuthenticatedUser {
  if (!request.user) throw unauthenticated();
  return request.user;
}
