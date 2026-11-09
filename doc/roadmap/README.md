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

**Last updated:** 2026-11-09 (Phase 2 final decisions applied)
**Location note:** these instructions refer to `docs/roadmap/`. The repository keeps all
documentation in `doc/`, so the roadmap lives in `doc/roadmap/`. The folder was not renamed,
to avoid breaking existing references.

| Phase | Scope | Status | Branch / commits | Record |
|---|---|---|---|---|
| 1 | Project foundation and guardrails | `[x]` Completed and approved | `phase-1-foundation` (`7643ba5`, `c72774f`) | `phase_1.md` |
| 2 | Application experience: onboarding, home, tutors, practice; profile/onboarding/dashboard/catalogue APIs; asset library; final decisions | `[x]` Complete. **Conditionally approved** 2026-11-09; conditions applied; final confirmation pending | `phase-2-experience` (`8587600`) → `asset-library` (`42c862b`) → `phase-2-closeout` | `phase_2.md` |
| 3 | Backend foundation and production Firebase preparation (plan first, then approval) | `[ ]` Not started (needs approval) | none | none |
| 4 | Firebase Auth hardening, App Check, Firestore owner rules | `[ ]` Not started | none | none |
| 5 | Onboarding and profile management (editing, deletion) | `[ ]` Not started | none | none |
| 6 | Gemini real-time speaking | `[ ]` Not started | none | none |
| 7 | Sessions and daily quotas | `[ ]` Not started | none | none |
| 8 | AI feedback, vocabulary, Mistake Vault | `[ ]` Not started | none | none |
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
| 2026-11-09 | **Firebase `sprelia` = PRODUCTION** (final); separate dev project; emulators for tests; production project refused outside production (code guard) | Owner architecture decision; `doc/FIREBASE_SETUP.md` |
| 2026-11-09 | Tutor–scenario compatibility enforced on the backend; Study abroad → Alex; Alex supports Social; Emma supports Professional and Academic (A1 content) | Owner decisions 1, 2, 4, 8; `doc/reviews/SCENARIO_REVIEW.md` §5 |
| 2026-11-09 | Levels A1–C1; daily targets and durations 5/10/15 | Owner decisions |
| 2026-11-09 | 5 Premium scenarios; recommendation rotates among all eligible scenarios | Owner decisions 6, 7 |
| 2026-11-09 | Human review required before publishing scenarios (production serves approved only) | Owner content decision |
| 2026-11-09 | American English for the initial release; British via overlays and ARB later | Owner content decision |
| 2026-11-09 | Tutor images: rights not established → replace; no history rewrite; keep empty-state icons | Owner asset decisions; `doc/ASSET_LIBRARY.md` §3a |
| 2026-11-09 | Stacked PRs preserved: Phase 1 → Phase 2 → Asset library → Close-out; no automatic merges | Owner git decision |
