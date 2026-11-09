import type { FastifyPluginAsync } from 'fastify';
import { reauthRequired } from '../../common/errors.js';
import { authenticate, requireUser } from '../auth/authenticate.js';
import type { TokenVerifier } from '../auth/token-verifier.js';
import type { UserRepository } from '../users/user.repository.js';
import type { IdentityAdmin } from './identity-admin.js';

export interface AccountRoutesOptions {
  verifier: TokenVerifier;
  users: UserRepository;
  identity: IdentityAdmin;
  /** Maximum age of the caller's last sign-in for sensitive operations. */
  recentAuthMaxAgeSeconds: number;
  now: () => Date;
}

/**
 * DELETE /me: permanently deletes the caller's account.
 *
 * POLICY STATUS: immediate hard delete (no grace period, no retained copies) is the
 * engineering RECOMMENDATION (decision D2). It is NOT confirmed by the owner, and the
 * published retention policy required by APP_FLOW §17 does not exist yet. Both are
 * release blockers (doc/roadmap/phase_3.md). Change this behavior only with that decision.
 *
 * - Only the verified caller's own uid is ever used; there is no uid parameter.
 * - Requires a recent sign-in (`auth_time`), otherwise 403 REAUTH_REQUIRED, so a stolen
 *   long-lived session cannot delete an account.
 * - Deletes all Firestore data under users/{uid} first, then the Auth user. Both steps are
 *   idempotent, so a retry after a partial failure completes the deletion.
 * - Email verification is NOT required: anyone may delete their own account.
 */
export const accountRoutes: FastifyPluginAsync<AccountRoutesOptions> = async (app, opts) => {
  app.delete('/me', { preHandler: authenticate(opts.verifier) }, async (request, reply) => {
    const user = requireUser(request);
    const ageSeconds = opts.now().getTime() / 1000 - user.authTime;
    if (!(ageSeconds >= -300 && ageSeconds <= opts.recentAuthMaxAgeSeconds)) throw reauthRequired();

    await opts.users.deleteUserData(user.uid);
    await opts.identity.deleteUser(user.uid);
    request.log.info({ uid: user.uid, event: 'account_deleted' }, 'account deleted');
    reply.header('cache-control', 'private, no-store');
    return reply.status(204).send();
  });
};
