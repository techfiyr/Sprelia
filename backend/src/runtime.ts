import type { FastifyBaseLogger, FastifyInstance } from 'fastify';
import { buildApp } from './app.js';
import type { AppConfig } from './config/env.js';
import { firebaseAppCheck, firebaseAuth, firestore, initFirebaseAdmin } from './firebase/admin.js';
import { FirebaseIdentityAdmin } from './modules/account/identity-admin.js';
import { FirebaseAppCheckVerifier } from './modules/app-check/app-check.js';
import { FirebaseTokenVerifier } from './modules/auth/firebase-token-verifier.js';
import { FirestoreConversationRepository } from './modules/conversations/firestore-conversation.repository.js';
import { createAIProvider } from './modules/conversations/gemini-provider.js';
import { createAnalyzer } from './modules/feedback/analysis.js';
import { FirestoreFeedbackRepository } from './modules/feedback/firestore-feedback.repository.js';
import { FirestoreSubscriptionRepository } from './modules/subscriptions/firestore-subscription.repository.js';
import { HttpRevenueCatClient } from './modules/subscriptions/revenuecat.js';
import { FirestoreUserRepository } from './modules/users/firestore-user.repository.js';

/**
 * Wires the real (Firebase-backed) dependencies into the HTTP app. Shared by the long-running
 * server (`main.ts`) and the Netlify Functions entry point, so routes and behavior are identical.
 */
export async function createRuntimeApp(config: AppConfig, logger: FastifyBaseLogger): Promise<FastifyInstance> {
  const firebase = initFirebaseAdmin(config);
  const auth = firebaseAuth(firebase);
  const db = firestore(firebase);
  return buildApp({
    config,
    logger,
    verifier: new FirebaseTokenVerifier(auth, { checkRevoked: config.authCheckRevoked }),
    users: new FirestoreUserRepository(db),
    conversations: new FirestoreConversationRepository(db),
    // Without GEMINI_API_KEY voice is unavailable (503 VOICE_UNAVAILABLE), never a crash.
    ai: createAIProvider(config),
    feedback: new FirestoreFeedbackRepository(db),
    analyzer: createAnalyzer(config),
    subscriptions: new FirestoreSubscriptionRepository(db),
    revenueCat: config.revenueCatSecretApiKey ? new HttpRevenueCatClient(config.revenueCatSecretApiKey) : undefined,
    identity: new FirebaseIdentityAdmin(auth),
    appCheck: config.appCheckMode === 'off' ? undefined : new FirebaseAppCheckVerifier(firebaseAppCheck(firebase)),
  });
}
