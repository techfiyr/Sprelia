import type { Auth } from 'firebase-admin/auth';

/** Server-side identity operations (Firebase Auth Admin). Keyed by the verified caller's uid only. */
export interface IdentityAdmin {
  /** Deletes the Auth user. Succeeds if the user no longer exists (idempotent). */
  deleteUser(uid: string): Promise<void>;
}

export class FirebaseIdentityAdmin implements IdentityAdmin {
  constructor(private readonly auth: Auth) {}

  async deleteUser(uid: string): Promise<void> {
    try {
      await this.auth.deleteUser(uid);
    } catch (err) {
      const code = typeof err === 'object' && err !== null && 'code' in err ? (err as { code: unknown }).code : undefined;
      if (code === 'auth/user-not-found') return;
      throw err;
    }
  }
}
