import type { InMemoryUserRepository } from '../users/memory-user.repository.js';
import type { SubscriptionRepository, SubscriptionState } from './subscription.repository.js';

export class InMemorySubscriptionRepository implements SubscriptionRepository {
  readonly states = new Map<string, SubscriptionState>();
  constructor(private readonly users: InMemoryUserRepository) {}
  async get(uid: string) {
    const s = this.states.get(uid);
    return s ? { ...s } : null;
  }
  async set(uid: string, state: SubscriptionState) {
    if (!this.users.profiles.has(uid)) return false;
    this.states.set(uid, { ...state });
    return true;
  }
}
