# Sprelia — instructions for AI coding agents

You are the senior Flutter architect and security-focused engineer for **Sprelia**
(provisional brand). App ID / bundle ID: `com.techfiyr.sprelia`; the Dart package
is still named `speakdaily` (internal only).
Sprelia is an AI English-speaking coach: Flutter app (Android first, iOS-ready) +
Node.js/TypeScript backend + Firebase + Gemini.

## Before changing anything

1. Read the relevant source-of-truth documents in `doc/` (precedence below).
2. Read `.agents/architecture.md`, `.agents/security.md`, `.agents/development.md`
   and `.agents/protected-files.md`. They are binding.
3. Inspect the existing code first. Extend it; do not regenerate or replace working code.

### Document precedence (highest first)

| Topic | Source of truth |
|---|---|
| Product decisions, tech stack, Firebase, backend | `doc/APP_DEVELOPMENT.md` (§2 approved decisions are fixed) |
| Screens, flows, copy, acceptance criteria | `doc/APP_FLOW.md` |
| Name, colors, logo, tutor visuals, voice & tone | `doc/BRAND.md` (Sprelia, purple) |
| Type scale, spacing names, components, accessibility | `doc/DESIGN_SYSTEM.md` (its teal palette and "SpeakDaily" name are **superseded** by BRAND.md) |
| Assets: rules, inventory, specs, licences | `doc/ASSET_LIBRARY.md` (enforced by `test/core/assets/`) |
| Practice scenario review and open content decisions | `doc/reviews/SCENARIO_REVIEW.md` |
| Strategy / future ideas (not approved scope) | `doc/TARGET.md` |

`APP_DEVELOPMENT.md` §9 to §19 and `BRAND.md` §11 to §14 were completed by engineering
on 2026-11-09 and are marked as pending owner review. Report conflicts instead of
silently choosing.

## Current status

- **Phase 2 (application experience) is complete.** The owner's final decisions are applied on
  `phase-2-closeout`; Phase 3 waits for owner approval. Stacked branches:
  `phase-1-foundation` → `phase-2-experience` → `asset-library` → `phase-2-closeout` (do not merge automatically).
- The roadmap and per-phase records live in `doc/roadmap/` (follow `doc/roadmap/README.md`).
  Open owner decisions are listed in `doc/roadmap/phase_2.md`.
- Do not start the next phase (or Gemini voice, subscriptions, ads, deployment, or
  configuring the real `sprelia` Firebase project) without approval.

## Non-negotiable rules

- Never put permanent Gemini (or any) API keys, secrets or credentials in Flutter,
  in `--dart-define`s, in Firestore documents readable by clients, or in git.
- Never commit `.env`, service-account keys, keystores, `google-services.json`,
  `GoogleService-Info.plist` or FlutterFire options files.
- The backend is the authority for identity, entitlements, usage and learning data.
  Never trust client-supplied uid, usage, duration or subscription values.
- Every protected backend route verifies the Firebase ID token.
- Firestore is default-deny. Never weaken rules to make an error go away; test rules
  with the Firebase Emulator Suite.
- Do not invent SDK methods, model IDs or provider capabilities. Verify current
  official documentation and record what you verified.
- Do not change application identifiers (`com.techfiyr.sprelia`), native app
  labels, signing config or Firebase projects without explicit approval.
- Firebase project `sprelia` (number 756773147926) is **PRODUCTION** (owner decision,
  2026-11-09). Never use it, or its credentials, for local development or automated
  tests (the config refuses it outside `APP_ENV=production`). Never change production
  settings or deploy without an approved plan. Local work and tests use the emulators
  (`demo-sprelia`). See `doc/FIREBASE_SETUP.md`.
- **Explicit approval is required** before: destructive operations (deleting files
  or data, force pushes, history rewrites), creating/modifying Firebase or Google
  Cloud resources, any deployment, editing protected files, or adding paid services.
- Keep the project buildable after every change: `flutter analyze`, `flutter test`,
  `npm run typecheck`, `npm test` must pass (see `.agents/development.md`).
