import type { FastifyPluginAsync } from 'fastify';
import { authenticate, requireUser } from '../auth/authenticate.js';
import type { TokenVerifier } from '../auth/token-verifier.js';

export interface MeRoutesOptions {
  verifier: TokenVerifier;
}

/**
 * GET /me returns the identity from the verified ID token. Read-only: there is
 * no client write path for user data in Phase 1.
 */
export const meRoutes: FastifyPluginAsync<MeRoutesOptions> = async (app, { verifier }) => {
  app.get('/me', { preHandler: authenticate(verifier) }, async (request, reply) => {
    const user = requireUser(request);
    reply.header('cache-control', 'private, no-store');
    return {
      uid: user.uid,
      email: user.email ?? null,
      emailVerified: user.emailVerified,
      signInProvider: user.signInProvider ?? null,
    };
  });
};
