# SpeakDaily — App Development & Architecture Specification

**Document version:** 1.0  
**Date:** November 2026  
**Product:** SpeakDaily — AI English Speaking & Communication Coach  
**Platforms:** Android first, iOS-ready  
**Development approach:** Flutter + Firebase + Node.js + Gemini API  
**Completeness:** complete (§1–§19, verified 2026-11-09; no truncated sections)  
**Review status:** §1 to the start of §9 are the owner's original text. §9 (continued) to §19
were drafted by engineering on 2026-11-09 and are **pending owner review**.  
**Name note:** the product's provisional name is now **Sprelia** (owner decision,
`doc/roadmap/phase_2.md` §B; BRAND.md §1, §13). "SpeakDaily" in this document refers to the
same product. The app ID is `com.techfiyr.sprelia`.

---

# 1. Project Overview

SpeakDaily is a global AI-powered English speaking and communication coach.

**Product promise:** Practice English every day. Speak with confidence everywhere.

The application helps learners improve their spoken English through real-time AI voice conversations, practical roleplay scenarios, personalized feedback, vocabulary development and progress tracking.

The application must prioritize:
- Natural real-time voice conversations.
- Friendly and supportive AI tutors.
- Practical English communication.
- Personalized learning.
- Measurable progress.
- Secure user data and AI usage.
- Sustainable AI operating costs.

# 2. Approved Product Decisions

These decisions are already approved and must not be changed without explicit authorization.

| Area | Decision |
|---|---|
| Product name | SpeakDaily, now provisionally **Sprelia** (owner decision, roadmap phase 2 §B; pending clearance) |
| Target market | Global |
| Initial audience | Adults, 18+ |
| Mobile framework | Flutter |
| Initial platform | Android |
| Future platform | iOS |
| UI theme | Light |
| AI provider | Google Gemini |
| Voice experience | Real-time audio conversation |
| Free allowance | 10 minutes per local calendar day |
| AI tutors | Multiple personalities and voices |
| Correction timing | After the conversation |
| Backend | Node.js + TypeScript |
| Database | Cloud Firestore |
| Authentication | Firebase Authentication |
| Subscription | RevenueCat |
| Advertising | Google AdMob |

Do not introduce mid-conversation grammar corrections. The tutor should maintain natural conversation and provide corrections after the session.

# 3. Technology Stack

## Mobile application

- Flutter / Dart.
- Riverpod for state management.
- GoRouter for navigation.
- Dio for REST API requests.
- Firebase Authentication.
- Cloud Firestore.
- Firebase Analytics.
- Firebase Crashlytics.
- Firebase Cloud Messaging.
- Firebase App Check.
- Google Mobile Ads.
- RevenueCat.
- Gemini Live API integration through a supported realtime audio transport.

Use maintained, compatible package versions. Verify package compatibility before adding dependencies.

## Backend

- Node.js.
- TypeScript.
- NestJS or modular Fastify architecture.
- Firebase Admin SDK.
- ~~Cloud Run~~ **Netlify Functions** (owner hosting decision 2026-11-09; free plan, default function region (US East); Firestore in `us-east5`; see `doc/DEPLOYMENT_NETLIFY.md`).
- Cloud Firestore.
- Google Cloud Secret Manager.
- Gemini API.
- RevenueCat webhooks.

The backend is the authority for authentication, user entitlements, AI session authorization, usage accounting and learning data processing.

## Development tools

- Git and GitHub.
- Flutter SDK.
- Android Studio.
- Xcode for iOS builds.
- Codemagic or GitHub Actions.
- Firebase CLI.
- Google Cloud CLI.

# 4. Repository Architecture

Use a feature-first architecture.

Recommended initial repository:

```text
speakdaily/
├── .agents/
│   ├── AGENTS.md
│   ├── architecture.md
│   ├── flutter.md
│   ├── firebase.md
│   ├── backend.md
│   ├── security.md
│   ├── app-flow.md
│   └── protected-files.md
│
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── config/
│   │   ├── constants/
│   │   ├── errors/
│   │   ├── routing/
│   │   ├── services/
│   │   ├── theme/
│   │   ├── utils/
│   │   └── widgets/
│   │
│   ├── features/
│   │   ├── auth/
│   │   ├── onboarding/
│   │   ├── home/
│   │   ├── tutors/
│   │   ├── scenarios/
│   │   ├── practice/
│   │   ├── feedback/
│   │   ├── mistakes/
│   │   ├── vocabulary/
│   │   ├── progress/
│   │   ├── subscription/
│   │   └── profile/
│   │
│   └── data/
│       ├── models/
│       ├── repositories/
│       └── providers/
│
├── backend/
│   ├── src/
│   │   ├── modules/
│   │   ├── common/
│   │   ├── config/
│   │   ├── middleware/
│   │   ├── providers/
│   │   └── main.ts
│   ├── test/
│   └── package.json
│
├── assets/
│   ├── images/
│   ├── icons/
│   ├── animations/
│   └── fonts/
│
├── test/
├── integration_test/
├── firebase.json
├── firestore.rules
├── firestore.indexes.json
├── pubspec.yaml
└── README.md
```

Do not create every file immediately. Build incrementally and maintain a working application after each milestone.

# 5. Flutter Architecture Rules

Use the following architecture:

Presentation → Controller/Notifier → Repository → Service/API.

Responsibilities:

**Presentation**
- Screens and reusable widgets.
- UI state rendering.
- User interactions.
- No direct business logic.

**Controller / Notifier**
- Coordinates feature operations.
- Manages loading, error and success states.
- Calls repositories.

**Repository**
- Provides a consistent data interface.
- Coordinates remote and local data sources.
- Does not contain widget code.

**Services**
- Firebase services.
- API client.
- Audio services.
- Gemini session transport.
- Analytics.
- Subscription services.

Requirements:
- Use Riverpod consistently.
- Use immutable models.
- Keep widgets small and reusable.
- Avoid business logic inside widgets.
- Handle loading, empty, offline and error states.
- Avoid duplicated API calls.
- Add tests for important business logic.

# 6. Firebase Architecture

Firebase is a core infrastructure component.

## Firebase services

### Firebase Authentication

Support:
- Google sign-in.
- Email/password sign-in.
- Email verification where appropriate.
- Account sign-out.
- Account deletion.

Use Firebase Authentication as the identity provider.

The mobile client must obtain Firebase ID tokens and send them to the backend using:

`Authorization: Bearer <Firebase ID token>`

The backend must verify every token using Firebase Admin SDK.

Never trust a user ID supplied by the client without verifying it against the authenticated identity.

### Cloud Firestore

Use Firestore for:
- User profiles.
- Learning preferences.
- Tutor configuration.
- Learning scenarios.
- Conversation records.
- Transcripts, subject to retention policy.
- Post-session feedback.
- Mistake Vault.
- Vocabulary.
- Daily learning progress.

Suggested schema:

```text
users/{uid}
    profile fields

users/{uid}/preferences/{preferenceId}

users/{uid}/conversations/{conversationId}
    session metadata

users/{uid}/conversations/{conversationId}/messages/{messageId}

users/{uid}/conversations/{conversationId}/feedback/{feedbackId}

users/{uid}/mistakes/{mistakeId}

users/{uid}/vocabulary/{vocabularyId}

users/{uid}/dailyProgress/{YYYY-MM-DD}

users/{uid}/usage/{YYYY-MM-DD}

users/{uid}/subscription/current

tutors/{tutorId}

scenarios/{scenarioId}

appConfig/{configId}
```

Use the user's configured timezone to calculate local daily progress and quota boundaries.

### Firebase Cloud Messaging

Use FCM for:
- Optional daily practice reminders.
- Learning reminders.
- Weekly progress notifications.
- Important account notifications.

Never send unnecessary or manipulative notifications.

### Firebase Analytics

Track product events without sending raw transcripts, audio, sensitive personal information or API credentials.

### Firebase Crashlytics

Track:
- App crashes.
- Non-fatal exceptions.
- Audio session failures.
- Realtime connection failures.
- Important integration errors.

Never attach raw conversations or secrets to crash reports.

### Firebase App Check

Enable App Check for supported Firebase resources.

Use appropriate Android Play Integrity and iOS App Attest or supported alternatives.

App Check complements authentication and authorization; it does not replace them.

# 7. Firebase Security Rules

Security must be implemented before production data is introduced.

Default policy: deny access unless explicitly authorized.

Requirements:

1. Users can access only their own user data.
2. A user must not read another user's private conversations.
3. Clients cannot modify subscription entitlements.
4. Clients cannot modify authoritative AI usage records.
5. Clients cannot modify server-generated feedback or trusted learning analysis.
6. Clients cannot modify application configuration.
7. Tutor and scenario catalogue data should be read-only for clients.
8. Validate allowed fields and types for permitted writes.
9. Avoid broad wildcard write permissions.
10. Backend uses Firebase Admin SDK with explicit authorization and validation because Admin SDK bypasses Firestore Security Rules.

Important: authenticated access does not automatically mean unrestricted read/write access.

Implement and test Firestore rules using Firebase Emulator Suite before deployment.

# 8. Backend Architecture

The backend owns all trusted business logic.

Recommended modules:

```text
backend/src/modules/
├── auth/
├── users/
├── onboarding/
├── tutors/
├── scenarios/
├── conversations/
├── gemini/
├── learning-analysis/
├── mistakes/
├── vocabulary/
├── progress/
├── usage/
├── subscription/
├── webhooks/
└── health/
```

Backend responsibilities:
- Firebase ID token verification.
- User authorization.
- AI provider communication.
- Session creation and termination.
- Temporary credential management.
- Daily usage enforcement.
- Subscription entitlement verification.
- Learning feedback generation.
- Firestore writes for trusted data.
- Request validation.
- Rate limiting.
- Idempotency.
- AI usage and cost monitoring.

Never place permanent Gemini API keys in Flutter or publicly accessible Firebase documents.

Use Google Cloud Secret Manager for production secrets.

# 9. Gemini AI Integration

Google Gemini is the initial AI provider.

Use a provider abstraction:

```text
AIProvider
    ├── createRealtimeSession()
    ├── endRealtimeSession()
    ├── analyzeConversation()
    └── healthCheck()
```

Implement:

```text
GeminiProvider
```

Do not couple the entire application to Gemini-specific data models.

Model IDs must be configurable in backend environment variables.

Before implementation:
- Verify the exact Live API model ID.
- Verify current API availability.
- Verify supported audio formats and sample rates.
- Verify session duration limits, reconnection and session resumption behaviour.
- Verify the supported client authentication mechanism (ephemeral tokens).
- Verify current pricing, rate limits and quotas.

> **Sections 9 (continued) to 19** were drafted on 2026-11-09 by engineering from the
> approved decisions in §2, `APP_FLOW.md` and the verified provider documentation.
> They are pending owner review. Where a decision is still open it is marked
> **Open decision**.

## Verified Gemini Live facts (2026-11-09)

Re-verify against the official documentation before implementation and record the date.

| Topic | Verified fact |
|---|---|
| Default Live model | `gemini-3.8-live` (GA since 2026-09-15). `gemini-3.1-flash-live-preview` is legacy. |
| Superseded | `gemini-2.5-flash-native-audio-preview-09-2025` (used by the prototype) |
| Text analysis models | `gemini-3.8-flash` or `gemini-3.5-flash-lite`. `gemini-2.5-flash` is deprecated and reroutes from 2026-12-01. |
| Audio input | Raw PCM16, little-endian, 16 kHz mono |
| Audio output | Raw PCM16, little-endian, 24 kHz mono |
| Connection lifetime | About 10 minutes, announced by a `GoAway` message. Audio-only sessions last 15 minutes without context compression. |
| Session resumption | Supported. Handles are valid for 2 hours after the session ends. |
| Client authentication | Ephemeral tokens (preview, Live API only, `v1beta`), passed as the `access_token` query parameter or `Authorization: Token <token>` |
| Token defaults | `uses: 1`, 1 minute to start a session, 30 minutes total |

## Realtime transport decision

- The mobile app connects **directly** to the Live API WebSocket using a short-lived,
  single-use ephemeral token minted by the backend for one conversation.
- The token locks the model, system instructions, voice and transcription settings
  (`liveConnectConstraints`), so a modified client cannot change persona or model.
- The token's expiry bounds the session to the server-reserved allowance.
- Proxying audio through the backend was rejected for the MVP because it adds latency
  and hosting cost. Reconsider only if server-side transcripts become mandatory.
- Ephemeral tokens can be extracted from a mobile app. They limit, but do not
  eliminate, abuse. Quotas are therefore always enforced on the server.

## Post-session analysis

- Runs on the backend only, after the conversation ends.
- Uses structured JSON output validated with Zod before storage.
- Corrections include a confidence value. Low-confidence items, which may be speech
  recognition artefacts, are discarded. Never fabricate corrections.
- No pronunciation scoring until a validated assessment system exists.
- Transcripts are treated as untrusted data, never as instructions, in analysis prompts.

## AI cost controls

- Per-user daily allowance enforced server-side (§10).
- One active realtime session per user.
- Session expiry and reconciliation even when the app closes unexpectedly.
- Per-uid rate limits on session creation and analysis.
- Usage and cost metrics per model, with budget alerts in Google Cloud.

# 10. Usage and Quota Accounting

- Free plan: 10 minutes of AI speaking per **local calendar day**. Premium uses a higher
  limit stored in server configuration (**Open decision**: premium allowance).
- The day boundary uses the timezone stored on the user profile by the server.
  Timezone changes are rate-limited to prevent quota farming.
- Session start reserves the remaining allowance atomically in a Firestore transaction
  (`users/{uid}/usage/{YYYY-MM-DD}` plus an append-only ledger).
- Session end bills server-measured time, capped at the reservation. `end` is idempotent.
- Unfinished sessions are reconciled when their token expires.
- Clients may display remaining time but can never write or report authoritative usage.

# 11. Subscriptions and Advertising

## RevenueCat
- The RevenueCat app user ID equals the Firebase uid.
- Entitlements are written only by the backend after a RevenueCat webhook (authenticated
  with a shared secret) and a server-side REST verification. They are stored in
  `users/{uid}/subscription/current`.
- Never unlock premium because the client reports a successful purchase.
- Test prices: $5.99 monthly and $39.99 annual (APP_FLOW §16). Not final.

## Google AdMob
- Free plan only. Never during an active conversation and never before a paywall decision.
- If rewarded ads grant extra minutes (**Open decision**), the grant requires AdMob
  server-side verification callbacks; client reports are never trusted.

# 12. Environments and Configuration

| Environment | Firebase project | Backend | Flutter config |
|---|---|---|---|
| Local and automated tests | Emulator Suite (`demo-sprelia`) | `npm run dev` | `env/development.json` |
| Development (pre-launch) | **`sprelia`** (756773147926), test accounts only | local `npm run dev` | `env/development-firebase.local.json` |
| Staging / production | **`sprelia`** | Netlify Functions (default region) | `env/staging.json`, `env/production.json` |

Owner architecture decision (2026-11-09): **one Firebase project, `sprelia`**, for development,
integration testing where appropriate, and eventual production. It supersedes the separate
`sprelia-dev` proposal. Automated tests run only on the emulators (the config refuses any real
project with `APP_ENV=test`). No public release until the readiness checklist in
`doc/roadmap/phase_3.md` §5 passes (`doc/FIREBASE_SETUP.md`).

- Backend configuration is validated at startup. Locally, credentials come from Application Default Credentials. On Netlify, secrets come from environment variables marked secret; including the service-account key `FIREBASE_SERVICE_ACCOUNT_JSON` (owner authorized 2026-11-09).
- Flutter configuration is compiled in, so it never contains secrets.
- Emulator usage is refused outside development, in both the backend and the app.
- Production deployment always requires explicit owner approval.

# 13. Security Requirements

The binding, detailed rules are in `.agents/security.md`. In summary:
- Firebase ID token verification on every protected endpoint. Identity only from the token.
- App Check on supported resources as an additional layer.
- Default-deny Firestore rules, tested on the Emulator Suite.
- Server-authoritative usage, entitlements and learning analysis.
- Zod validation on every request and strict schemas on writes.
- No secrets in the app, in git or in logs.

# 14. Privacy and Data Retention

- Raw voice recordings are **not stored** by default.
- Transcripts are stored only as needed for feedback and the Mistake Vault, subject to a
  published retention period (**Open decision**: retention length).
- Analytics and crash reports never contain transcripts, audio or personal data.
- Account deletion removes or anonymizes all user data (Firestore, Auth, RevenueCat
  customer) according to the published policy.
- Gemini API usage must be on a billing-enabled tier with appropriate data-use terms;
  disclose AI processing in the privacy policy.
- Initial audience: adults 18+ (**Open decision**: how age is confirmed).

# 15. Testing Strategy

| Layer | Tooling | Required coverage |
|---|---|---|
| Flutter unit | `flutter_test` | Config, models, controllers, error mapping |
| Flutter widget | `flutter_test` | Components, navigation, onboarding persistence, state views |
| Flutter integration | `integration_test` | Critical journeys on a device or emulator (from Phase 10) |
| Backend unit | Vitest + `fastify.inject` | Every route: unauthenticated, invalid token, invalid input, success, ownership |
| Backend integration | Vitest + Firebase Emulator Suite | Real token verification and Firestore repositories |
| Security rules | `@firebase/rules-unit-testing` on the emulator | Every allow and deny path |

Tests never use real credentials or call production services.

# 16. Observability and Error Handling

- Backend: structured JSON logs (Cloud Logging format), request IDs, no bodies or tokens.
- App: Crashlytics for crashes and non-fatal errors, including audio and realtime failures.
  Users see friendly messages only.
- Alerts: error rate, latency, AI cost and quota anomalies.

# 17. CI/CD and Deployment

> **Owner hosting decision (2026-11-09):** Netlify (API as a Netlify Function, website as static files). Where this section mentions Cloud Run or workload identity, `doc/DEPLOYMENT_NETLIFY.md` applies instead.

- GitHub Actions (or Codemagic for mobile builds): analyze, test, typecheck and build on
  every pull request.
- ~~Cloud Run deploys from CI using workload identity federation~~ Netlify deploys from the connected Git repository after owner approval (`doc/DEPLOYMENT_NETLIFY.md`).
- Mobile release signing keys are stored only in CI secrets.
- Production deploys and store releases require explicit owner approval.

# 18. Delivery Phases

1. Project foundation and development guardrails.
2. Flutter application experience: onboarding, home, tutors, practice discovery.
3. Backend foundation: remaining modules and the AI provider abstraction.
4. Firebase Authentication, App Check, Firestore rules and secure API communication.
5. Onboarding and profile management (complete).
6. Gemini real-time speaking integration.
7. Speaking session management and daily quotas.
8. AI feedback, vocabulary and Mistake Vault.
9. RevenueCat subscriptions and AdMob.
10. Testing, security review and production readiness.

The application must remain buildable after every phase.

# 19. Open Decisions

| Decision | Owner |
|---|---|
| Final product name (trademark, domain and store clearance) | Product owner |
| ~~Role of Firebase project `sprelia`~~: **decided** 2026-11-09: the single project for development and production (no separate development project). | Product owner |
| Premium daily allowance | Product owner |
| Transcript retention period | Product owner / legal |
| Guest mode (recommended: none for the MVP) | Product owner |
| Rewarded ads granting minutes | Product owner |
| Age confirmation approach for 18+ | Product owner / legal |
| Interface languages at launch (content: American English decided 2026-11-09) | Product owner |
| ~~Cloud Run region~~ **Decided 2026-11-09:** hosting on Netlify Functions (free plan, default region, US East); Firestore in `us-east5` (Columbus, Ohio; recreated by the owner, replacing `asia-southeast1`) | Owner |

**End of app development specification.**
