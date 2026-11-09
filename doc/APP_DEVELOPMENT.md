# SpeakDaily — App Development & Architecture Specification

**Document version:** 1.0  
**Date:** November 2026  
**Product:** SpeakDaily — AI English Speaking & Communication Coach  
**Platforms:** Android first, iOS-ready  
**Development approach:** Flutter + Firebase + Node.js + Gemini API

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
| Product name | SpeakDaily |
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
- Cloud Run.
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
- Verify supported audio