import { Timestamp, type Firestore } from 'firebase-admin/firestore';
import type { SubscriptionRepository, SubscriptionState } from './subscription.repository.js';

const toDate = (v: unknown) => (v instanceof Timestamp ? v.toDate() : null);

export class FirestoreSubscriptionRepository implements SubscriptionRepository {
  constructor(private readonly db: Firestore) {}

  private ref(uid: string) {
    return this.db.collection('users').doc(uid).collection('subscription').doc('current');
  }

  async get(uid: string): Promise<SubscriptionState | null> {
    const snap = await this.ref(uid).get();
    if (!snap.exists) return null;
    const d = snap.data()!;
    return {
      active: d.active === true,
      entitlementId: String(d.entitlementId ?? ''),
      expiresAt: toDate(d.expiresAt),
      productId: typeof d.productId === 'string' ? d.productId : null,
      store: typeof d.store === 'string' ? d.store : null,
      updatedAt: toDate(d.updatedAt) ?? new Date(0),
      lastEventId: typeof d.lastEventId === 'string' ? d.lastEventId : null,
    };
  }

  async set(uid: string, s: SubscriptionState): Promise<boolean> {
    return this.db.runTransaction(async (tx) => {
      const user = await tx.get(this.db.collection('users').doc(uid));
      if (!user.exists) return false;
      tx.set(this.ref(uid), {
        ...s,
        expiresAt: s.expiresAt ? Timestamp.fromDate(s.expiresAt) : null,
        updatedAt: Timestamp.fromDate(s.updatedAt),
        schemaVersion: 1,
      });
      return true;
    });
  }
}
