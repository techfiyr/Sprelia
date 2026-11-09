/**
 * The identity established by a verified Firebase ID token. This is the ONLY source
 * of the caller's uid; never accept a uid from the request body, query or headers.
 */
export interface AuthenticatedUser {
  uid: string;
  email?: string;
  emailVerified: boolean;
  /** e.g. "google.com", "password", "anonymous". */
  signInProvider?: string;
  /** Seconds since epoch when the user last signed in. */
  authTime: number;
}

/**
 * Verifies a bearer token and returns the authenticated user.
 *
 * Implementations MUST throw `invalidToken()` for any token that is malformed,
 * expired, revoked, issued for another project, or belongs to a disabled user,
 * and `authUnavailable()` when verification could not be completed.
 */
export interface TokenVerifier {
  verify(token: string): Promise<AuthenticatedUser>;
}
