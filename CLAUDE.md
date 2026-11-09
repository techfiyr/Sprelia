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

- **Phases 1 and 2 are complete and merged to `main`.** Phase 3 (Firebase integration and
  account management) is code complete and verified locally (commit `1db48eb`, pushed), but
  blocked on owner-only Firebase, signing and policy items; see `doc/roadmap/phase_3.md`.
- **Work directly on `main`** (owner decision, 2026-11-09). Do not create feature or phase
  branches unless the owner asks. Commit and push only when asked; never force-push.
- **Hosting: Netlify** (owner decision, 2026-11-09): free plan, default function region; API as a
  Netlify Function, website and policy drafts from `backend/netlify/public`. The Firebase key is
  authorized only as the `FIREBASE_SERVICE_ACCOUNT_JSON` Netlify secret, entered by the owner;
  agents never read or upload it. See `doc/DEPLOYMENT_NETLIFY.md`.
- The roadmap and per-phase records live in `doc/roadmap/` (follow `doc/roadmap/README.md`).
  Open owner decisions are listed in the current phase record.
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
- Firebase project `sprelia` (number 756773147926) is the **single** project for development
  and eventual production (owner decision 2026-11-09; do not create another project).
  Automated tests use only the emulators (`demo-sprelia`); manual checks on `sprelia` use
  test accounts only. Never change Firebase settings, deploy, or delete data without an
  approved plan. See `doc/roadmap/phase_3.md` and `doc/FIREBASE_SETUP.md`.
- **Explicit approval is required** before: destructive operations (deleting files
  or data, force pushes, history rewrites), creating/modifying Firebase or Google
  Cloud resources, any deployment, editing protected files, or adding paid services.
- Keep the project buildable after every change: `flutter analyze`, `flutter test`,
  `npm run typecheck`, `npm test` must pass (see `.agents/development.md`).
