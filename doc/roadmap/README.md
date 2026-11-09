# Roadmap Progress Tracking Instructions

The project roadmap is maintained in `docs/roadmap/`.

Files:
- `docs/roadmap/README.md` — overall project roadmap and status
- `docs/roadmap/phase_1.md` — Phase 1 tasks and completion record
- `docs/roadmap/phase_2.md` — Phase 2 tasks and completion record
- Create subsequent phase files using the same structure.

## Rules

1. Read the roadmap before starting any development task.
2. Follow phases sequentially. Do not start a later phase without explicit approval.
3. Update the relevant phase file whenever a task is started, completed, deferred, or blocked.
4. Track each task with one status:
   - `[ ]` Not started
   - `[/]` In progress
   - `[x]` Completed
   - `[!]` Blocked
   - `[-]` Deferred
5. Record implementation details, changed files, test results, and unresolved issues.
6. Never mark a task complete without verifying its implementation and tests.
7. Record important architecture, security, and product decisions.
8. Update `README.md` whenever phase status changes.
9. Preserve previous progress and decisions. Never silently remove completed work.
10. At the end of each phase, prepare a completion report and wait for my approval before proceeding.

## Current instruction

Inspect Phase 1 and Phase 2 roadmap files and compare them against the actual repository.

Report:
- Verified completed tasks
- Incomplete tasks
- Missing tasks
- Blockers and risks
- Recommended next steps

Do not modify application code or begin a new phase during this audit. Update only roadmap tracking information after verification.
---

# Roadmap status

**Last updated:** 2026-11-09 (Phase 3 audit and plan; single Firebase project decision)
**Location note:** these instructions refer to `docs/roadmap/`. The repository keeps all
documentation in `doc/`, so the roadmap lives in `doc/roadmap/`. The folder was not renamed,
to avoid breaking existing references.

| Phase | Scope | Status | Branch / commits | Record |
|---|---|---|---|---|
| 1 | Project foundation and guardrails | `[x]` Completed and approved | merged to `main` (PR #1) | `phase_1.md` |
| 2 | Application experience: onboarding, home, tutors, practice; profile/onboarding/dashboard/catalogue APIs; asset library; final decisions | `[x]` Complete; merged to `main` (PR #2 and merge `bbe720a`) | `main` | `phase_2.md` |
| 3 | Firebase integration and account management: single `sprelia` project, Google sign-in, email verification, account deletion, App Check, Firestore | `[/]` **Code complete and verified locally; blocked on owner items** (Firebase Console, signing, retention policy); not committed | `main` | `phase_3.md` |
| 4 | ~~Firebase Auth hardening, App Check, Firestore owner rules~~ (merged into Phase 3) | n/a | none | none |
| 5 | Profile and settings: edit preferences, display name, time zone (1/day), preferred tutor, reminder opt-in, data export | `[x]` Implemented and verified locally; reminder delivery needs FCM (owner) | `main` | `phase_5.md` |
| 6 | Gemini real-time speaking (backend grants, personas, app voice client) | `[x]` Implemented and verified locally, incl. a live Gemini token + session-setup check | `main` | `phase_6_7.md` |
| 7 | Sessions and daily quotas (server reservation, billing, ledger, reconciliation) | `[x]` Implemented and verified locally (emulator transactions) | `main` | `phase_6_7.md` |
| 8 | AI feedback, Mistake Vault, vocabulary, Learn and Progress tabs | `[x]` Implemented and verified locally, incl. a live analysis check; transcript retention period still an owner decision | `main` | `phase_8.md` |
| 9 | RevenueCat and AdMob | `[ ]` Not started | none | none |
| 10 | Testing, security review, production readiness | `[ ]` Not started | none | none |

## Audit result (Phase 1 and 2 vs. repository, 2026-11-09)
- **Verified completed:** every Phase 1 task, and every Phase 2 task except the one superseded by
  an owner decision (keep the old app IDs → changed to `com.techfiyr.sprelia`). Details and evidence
  are in the phase files.
- **Incomplete or deferred:** Phase 2 §F items (excluded by design). Google sign-in, email
  verification, display name, profile editing; inline strings on Phase 1 screens.
- **Missing tasks found:** none required by `phase_2.md`. Close-out additions: asset library,
  scenario review, document review status.
- **Blockers / risks:** tutor candidate images without established rights (to be replaced; history
  kept); engineering-drafted spec sections and all 27 scenarios awaiting human review (production
  would publish no scenarios); development Firebase project not created; the voice prototype is
  still legacy; release signing is not configured.
- **Recommended next steps:** owner decisions listed in `phase_2.md` → approve Phase 2 → merge the
  stacked branches into `main` → start Phase 3.

## Key decisions log
| Date | Decision | Source |
|---|---|---|
| 2026-11-09 | Brand Sprelia (provisional), purple palette; DESIGN_SYSTEM palette and name superseded | Owner, roadmap phase 2 §B; CLAUDE.md |
| 2026-11-09 | Backend framework: Fastify 5 | Phase 1 (`.agents/architecture.md`) |
| 2026-11-09 | App ID `com.techfiyr.sprelia` (overrides phase 2 §B "keep IDs") | Owner answer during Phase 2 setup |
| 2026-11-09 | Firebase project `sprelia` (ID) / 756773147926 (number); local work uses the emulators | Owner; FIREBASE_SETUP.md |
| 2026-11-09 | Contrast fixes keep the primary purple; text tokens darkened | Phase 2 §A; BRAND §12 |
| 2026-11-09 | Clients have no direct Firestore access in Phase 2 (API only) | `.agents/security.md` |
| 2026-11-09 | Unapproved/unlicensed assets are never bundled | `doc/ASSET_LIBRARY.md` |
| 2026-11-09 | ~~Firebase `sprelia` = PRODUCTION only; separate dev project~~ (superseded below) | Owner architecture decision |
| 2026-11-09 | **Single Firebase project `sprelia`** for development, integration testing where appropriate, and eventual production. No `sprelia-dev`. Automated tests stay on the emulators; test accounts only; no public release until readiness | Owner architecture decision; `phase_3.md` |
| 2026-11-09 | Tutor–scenario compatibility enforced on the backend; Study abroad → Alex; Alex supports Social; Emma supports Professional and Academic (A1 content) | Owner decisions 1, 2, 4, 8; `doc/reviews/SCENARIO_REVIEW.md` §5 |
| 2026-11-09 | Levels A1–C1; daily targets and durations 5/10/15 | Owner decisions |
| 2026-11-09 | 5 Premium scenarios; recommendation rotates among all eligible scenarios | Owner decisions 6, 7 |
| 2026-11-09 | Human review required before publishing scenarios (production serves approved only) | Owner content decision |
| 2026-11-09 | American English for the initial release; British via overlays and ARB later | Owner content decision |
| 2026-11-09 | Tutor images: rights not established → replace; no history rewrite; keep empty-state icons | Owner asset decisions; `doc/ASSET_LIBRARY.md` §3a |
| 2026-11-09 | **Hosting: Netlify** (API as Netlify Function on the free plan, default region; website from `backend/netlify/public`); supersedes Cloud Run. Firebase credential: service-account key as Netlify secret (owner authorized) | Owner; `doc/DEPLOYMENT_NETLIFY.md` |
| 2026-11-09 | Public landing page and draft Privacy, Terms, AI disclaimer, Content policy and Cookies pages; first-party consent manager, no tracking | Owner; `doc/reviews/LEGAL_PAGES_REVIEW.md` |
| 2026-11-09 | ~~Stacked PRs~~ superseded: everything merged to `main`; **work directly on `main`** from Phase 3 | Owner git decision |
