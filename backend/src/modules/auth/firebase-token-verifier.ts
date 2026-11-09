import type { Auth } from 'firebase-admin/auth';
import { authUnavailable, invalidToken } from '../../common/errors.js';
import type { AuthenticatedUser, TokenVerifier } from './token-verifier.js';

/** firebase-admin auth error codes that mean "this token must be rejected". */
const REJECTED_TOKEN_CODES = [
  'auth/argument-error', // malformed / wrong audience / wrong issuer / bad signature
  'auth/invalid-id-token',
  'auth/id-token-expired',
  'auth/id-token-revoked',
  'auth/user-disabled',
  'auth/user-not-found',
];

function errorCode(err: unknown): string | undefined {
  if (typeof err === 'object' && err !== null && 'code' in err) {
    const code = (err as { code: unknown }).code;
    return typeof code === 'string' ? code : undefined;
  }
  return undefined;
}

/**
 * Verifies Firebase ID tokens with the Admin SDK: signature, expiry, audience
 * (= project ID) and issuer are checked by `verifyIdToken`; with `checkRevoked`
 * it also rejects revoked sessions and disabled users.
 */
export class FirebaseTokenVerifier implements TokenVerifier {
  constructor(
    private readonly auth: Auth,
    private readonly options: { checkRevoked: boolean },
  ) {}

  async verify(token: string): Promise<AuthenticatedUser> {
    try {
      const decoded = await this.auth.verifyIdToken(token, this.options.checkRevoked);
      return {
        uid: decoded.uid,
        email: decoded.email,
        emailVerified: decoded.email_verified === true,
        signInProvider: decoded.firebase?.sign_in_provider,
        authTime: decoded.auth_time,
      };
    } catch (err) {
      const code = errorCode(err);
      if (code && REJECTED_TOKEN_CODES.includes(code)) throw invalidToken(err);
      // Network failure fetching public keys, Auth API outage, etc.
      throw authUnavailable(err);
    }
  }
}
