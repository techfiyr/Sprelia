import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import {
  assertFails,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { deleteDoc, doc, getDoc, getDocs, collection, setDoc, updateDoc } from 'firebase/firestore';
import { afterAll, beforeAll, describe, it } from 'vitest';
import { assertEmulatorOnly, EMULATOR_PROJECT_ID } from './emulator-guard.js';

/**
 * Firestore security rules (repo-root firestore.rules) on the emulator.
 *
 * Phase 2 policy: clients have NO direct Firestore access. All user data flows
 * through the authenticated API (Admin SDK). These tests prove that even the
 * owner of a document cannot read or write it directly, and that server-only
 * collections (usage, subscription, appConfig) are unreachable.
 */
const RULES_PATH = fileURLToPath(new URL('../../../firestore.rules', import.meta.url));

describe('firestore.rules', () => {
  let env: RulesTestEnvironment;

  beforeAll(async () => {
    const [host, port] = assertEmulatorOnly().firestoreHost.split(':');
    env = await initializeTestEnvironment({
      projectId: EMULATOR_PROJECT_ID,
      firestore: { rules: readFileSync(RULES_PATH, 'utf8'), host: host!, port: Number(port) },
    });
    await env.clearFirestore();
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, 'users/alice'), { uid: 'alice', onboardingStatus: 'completed' });
      await setDoc(doc(db, 'users/alice/preferences/learning'), { level: 'B1' });
      await setDoc(doc(db, 'users/alice/usage/2026-11-09'), { consumedSeconds: 120 });
      await setDoc(doc(db, 'users/alice/subscription/current'), { entitlement: 'free' });
      await setDoc(doc(db, 'tutors/emma'), { name: 'Emma' });
      await setDoc(doc(db, 'appConfig/public'), { freeDailySeconds: 600 });
    });
  });

  afterAll(async () => {
    await env?.cleanup();
  });

  const OWNER_PATHS = [
    'users/alice',
    'users/alice/preferences/learning',
    'users/alice/usage/2026-11-09',
    'users/alice/subscription/current',
  ];

  it.each(OWNER_PATHS)('owner cannot read %s directly', async (path) => {
    await assertFails(getDoc(doc(env.authenticatedContext('alice').firestore(), path)));
  });

  it.each(OWNER_PATHS)('owner cannot write %s directly', async (path) => {
    const db = env.authenticatedContext('alice').firestore();
    await assertFails(setDoc(doc(db, path), { hacked: true }));
    await assertFails(updateDoc(doc(db, path), { hacked: true }));
    await assertFails(deleteDoc(doc(db, path)));
  });

  it('owner cannot grant themselves premium or extra usage', async () => {
    const db = env.authenticatedContext('alice').firestore();
    await assertFails(setDoc(doc(db, 'users/alice/subscription/current'), { entitlement: 'premium', active: true }));
    await assertFails(setDoc(doc(db, 'users/alice/usage/2026-11-10'), { consumedSeconds: 0 }));
  });

  it('other users and anonymous clients are denied', async () => {
    await assertFails(getDoc(doc(env.authenticatedContext('mallory').firestore(), 'users/alice')));
    await assertFails(getDocs(collection(env.authenticatedContext('mallory').firestore(), 'users')));
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), 'users/alice')));
    await assertFails(setDoc(doc(env.unauthenticatedContext().firestore(), 'users/mallory'), { uid: 'mallory' }));
  });

  it('learning data from Phases 6–9 is server-only (owner cannot read or write it directly)', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, 'users/alice/conversations/c1'), { status: 'ended', billedSeconds: 60 });
      await setDoc(doc(db, 'users/alice/conversations/c1/private/transcript'), { lines: [] });
      await setDoc(doc(db, 'users/alice/conversations/c1/feedback/analysis'), { status: 'completed' });
      await setDoc(doc(db, 'users/alice/mistakes/m1'), { original: 'x' });
      await setDoc(doc(db, 'users/alice/vocabulary/word'), { term: 'word' });
      await setDoc(doc(db, 'users/alice/usageLedger/l1'), { seconds: 60 });
    });
    const owner = env.authenticatedContext('alice').firestore();
    for (const path of [
      'users/alice/conversations/c1',
      'users/alice/conversations/c1/private/transcript',
      'users/alice/conversations/c1/feedback/analysis',
      'users/alice/mistakes/m1',
      'users/alice/vocabulary/word',
      'users/alice/usageLedger/l1',
    ]) {
      await assertFails(getDoc(doc(owner, path)));
      await assertFails(setDoc(doc(owner, path), { hacked: true }));
    }
    // Clients cannot fake billing, feedback or a conversation.
    await assertFails(setDoc(doc(owner, 'users/alice/conversations/c2'), { status: 'ended', billedSeconds: 0 }));
    await assertFails(getDocs(collection(owner, 'users/alice/mistakes')));
  });

  it('the connectivity canary collection is not client-accessible', async () => {
    const owner = env.authenticatedContext('alice').firestore();
    await assertFails(setDoc(doc(owner, '__connectivity_canary/x'), { a: 1 }));
    await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), '__connectivity_canary/x')));
  });

  it('catalogue and app configuration are not client-writable', async () => {
    const db = env.authenticatedContext('alice').firestore();
    await assertFails(setDoc(doc(db, 'tutors/emma'), { name: 'Hacked' }));
    await assertFails(setDoc(doc(db, 'appConfig/public'), { freeDailySeconds: 999999 }));
    await assertFails(setDoc(doc(db, 'scenarios/new'), { title: 'x' }));
  });
});
