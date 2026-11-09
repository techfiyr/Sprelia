# Sprelia — Phase 1 Review and Phase 2 Approval

Phase 1 has been reviewed and is approved.

Proceed with Phase 2, subject to the following decisions and requirements.

## A. Fix Phase 1 outstanding documentation and accessibility issues

Before implementing new features:

1. Complete doc/APP_DEVELOPMENT.md.
2. Complete doc/BRAND.md.
3. Verify both files are complete and contain no truncated sections.
4. Fix supporting grey text contrast to WCAG AA.
5. Fix destructive button contrast.
6. Fix success-state text contrast.
7. Verify the primary purple button's text contrast.
8. Preserve the approved Sprelia purple brand identity.

Do not change the primary brand palette without explaining why and obtaining approval.

## B. App identity decision

Sprelia is our provisional product name, pending global trademark and domain clearance.

For local development:
- Use Sprelia as the provisional visible application name where appropriate.
- Keep the existing Android application ID.
- Keep the existing iOS bundle identifier.
- Do not publish store listings.
- Do not register domains or trademarks.
- Document the remaining rebranding requirements.

## C. Phase 2 — Flutter application experience

Implement the following screens using the approved BRAND.md, DESIGN_SYSTEM.md and APP_FLOW.md.

1. Welcome and onboarding.
2. Language selection.
3. English proficiency assessment.
4. Learning goals.
5. Daily speaking target.
6. Accent preference.
7. Home dashboard.
8. Tutor selection.
9. Practice category selection.
10. Practice preparation.

The application must follow the existing feature-first architecture, Riverpod state management and GoRouter navigation.

## D. Backend integration

Use the existing Fastify TypeScript backend.

Implement the minimum required authenticated APIs for:

- Creating and retrieving a user profile.
- Saving onboarding preferences.
- Retrieving the user's dashboard data.
- Retrieving available tutor configurations.
- Retrieving available practice categories.

Requirements:
- Verify Firebase ID tokens.
- Validate all requests using Zod.
- Enforce ownership on user-specific data.
- Never trust user IDs supplied in request bodies.
- Keep Firestore rules restrictive.
- Add backend unit and integration tests.

Do not create fake production entitlements or usage data.

## E. UI and UX quality

- Follow the approved purple visual identity.
- Bundle Inter fonts with the application.
- Use reusable components.
- Support different screen sizes.
- Provide loading, empty, success and error states.
- Make onboarding easy to complete.
- Preserve user progress if the application closes during onboarding.
- Use encouraging, natural English.
- Prepare localization architecture without translating every screen yet.
- Use placeholders only where final brand assets are unavailable.

## F. Explicitly excluded from Phase 2

Do not implement:

- Gemini voice integration.
- Live speaking sessions.
- Subscription payments.
- AdMob.
- AI feedback generation.
- Production deployment.
- Production Firebase project configuration.

These will be implemented in subsequent approved phases.

## G. Testing and completion

After implementation:

1. Run flutter analyze.
2. Run flutter test.
3. Run backend tests.
4. Run TypeScript typecheck.
5. Run backend build.
6. Test authenticated and unauthenticated API requests.
7. Test onboarding navigation and persistence.
8. Test application behavior after restart.
9. Verify accessibility contrast.
10. Review Firebase security rules.

Provide a report with changed files, implemented features, test results, remaining issues and instructions to run the application.

Do not proceed to Phase 3 or Gemini integration.

Stop after Phase 2 and wait for my approval.
---

# Completion record — Phase 2

**Status:** Implementation complete and verified. **Awaiting owner approval.** Phase 3 has not started.
**Branches (stacked, all pushed):** `phase-2-experience` (`8587600`) → `asset-library` (`42c862b`) →
`phase-2-closeout` (close-out documentation).
**Verified:** 2026-11-09 with a fresh run of all checks (see "Test results").

## A. Phase 1 documentation and accessibility issues
- [x] A1–A3 `APP_DEVELOPMENT.md` (§1–19) and `BRAND.md` (§1–14) completed and verified with no
  truncation. The added sections are marked **pending owner review** in each file's header.
- [x] A4 Supporting grey text #77758B → #6A687C (≥ 4.65:1 on every surface).
- [x] A5 Destructive button: error fill #C82D2D with white label, 5.43:1.
- [x] A6 Success text #1C7857 (≥ 4.66:1). A warning text token was also added.
- [x] A7 Primary purple button label verified at 5.12:1.
- [x] A8 Purple identity preserved. Primary palette unchanged; base status hues kept for icons.
  Enforced by `test/core/theme/app_theme_test.dart`.

## B. App identity
- [x] Sprelia used as the visible app name (Android label, iOS display and bundle name).
- [-] "Keep the existing Android application ID / iOS bundle identifier": **superseded by owner
  decision** (2026-11-09). IDs changed to `com.techfiyr.sprelia` to match the Android app the owner
  registered in Firebase project `sprelia` (commit `c72774f`). Recorded in `.agents/architecture.md`.
- [x] No store listings, domains or trademarks. Rebranding requirements documented in BRAND.md §13.

## C. Screens
- [x] C1 Welcome and onboarding: welcome, email sign-in / create account / password reset, 6 steps + plan.
- [x] C2 Language selection: interface language (English shipped) and first language (40, searchable).
- [x] C3 English proficiency: **self-assessment** (A1–B2 + "not sure"), stated as "not a test". No
  formal CEFR claim (APP_FLOW §5). A placement test is not in scope.
- [x] C4 Learning goals (multi-select). C5 Daily target (5/10/15/20). C6 Accent.
- [x] C7 Home dashboard (server data only). C8 Tutor selection. C9 Practice categories →
  scenarios. C10 Practice preparation.

## D. Backend
- [x] Profile create/retrieve, onboarding save, dashboard, tutors and categories (`/api/v1/me/*`,
  `/api/v1/tutors`, `/api/v1/practice/categories`).
- [x] Firebase ID tokens verified, Zod validation, ownership from the token only, no body uids,
  Firestore rules still deny all, unit and emulator integration tests.
- [x] No fake entitlements or usage data. The dashboard shows zeros until real data exists.

## E. UI and UX quality
- [x] Purple identity, bundled Inter, reusable components (incl. `AppSelectionTile`).
- [x] Screen sizes: scrollable layouts, no fixed heights. Verified on phone sizes only (tests and
  Pixel emulator); no tablet-specific layouts.
- [x] Loading, empty, success and error states with retry. Encouraging copy.
- [x] Onboarding progress survives an app kill, verified on the Android emulator with
  `am force-stop` + relaunch.
- [x] Localization architecture (gen-l10n, `lib/l10n/app_en.arb`). Phase 1 screens still inline.
- [x] Placeholders only where final assets are missing; labelled and inventoried.

## F. Excluded (not implemented, as instructed)
- [-] Gemini voice / live sessions, subscriptions, AdMob, AI feedback, production deployment and
  production Firebase configuration. The legacy Emma prototype is untouched and can only be
  launched from development builds.

## G. Testing and completion
- [x] G1–G5 analyze, Flutter tests, backend tests, typecheck and build all pass (see below).
- [x] G6 Authenticated and unauthenticated API requests tested (unit, emulator integration, live curl).
- [x] G7–G8 Onboarding navigation, persistence and restart: widget tests plus a real device process kill.
- [x] G9 Contrast verified (automated). G10 Firestore rules reviewed and tested (deny-all).

## Close-out tasks (Phase 2 final review)
- [x] Asset library: `assets/` structure, `AppAssets` registry, `doc/ASSET_LIBRARY.md` (the repo uses
  `doc/`, not `docs/`), `assets/ATTRIBUTION.md`. pubspec registers only approved files. Enforced by
  `test/core/assets/asset_library_test.dart`; the built APK contains only the 4 Inter fonts + OFL licence.
- [x] Inventory of fonts, licences, placeholders, candidates and missing illustrations
  (onboarding illustration added as planned).
- [x] 22 scenarios reviewed: `doc/reviews/SCENARIO_REVIEW.md` (findings F1–F11, decisions D1–D8;
  **no content changed**).
- [x] APP_DEVELOPMENT.md and BRAND.md completeness verified; review status added to their headers.
  DESIGN_SYSTEM.md has a precedence note (name and palette superseded by BRAND.md).
- [x] Package ID and Firebase status consistent across docs; Firebase re-checked read-only (below).
- [x] Roadmap updated (`README.md`, `phase_1.md`, this file).

## Implementation summary (changed files)
- `phase-2-experience` (105 files): `lib/core/{auth,session,firebase,storage}`,
  `lib/features/{auth,splash,onboarding,home,practice,tutors,profile}`, `lib/l10n/`,
  `assets/fonts/inter/`, `backend/src/modules/{users,catalog}`, `backend/test/**` (incl. `integration/`),
  `doc/{APP_DEVELOPMENT,BRAND,FIREBASE_SETUP}.md`, `.agents/*`, `env/*`, debug network security config.
- `asset-library` (20 files): `lib/core/assets/app_assets.dart`, `doc/ASSET_LIBRARY.md`,
  `assets/{README,ATTRIBUTION}.md`, Inter renamed to snake_case, OFL licence shown in-app,
  `TutorAvatar`, `test/core/assets/`.
- `phase-2-closeout`: `doc/reviews/SCENARIO_REVIEW.md`, `doc/ASSET_LIBRARY.md`,
  `lib/core/assets/app_assets.dart` (planned onboarding illustration entry; no behaviour change),
  headers of `doc/{APP_DEVELOPMENT,BRAND,DESIGN_SYSTEM}.md`, `doc/roadmap/*`.

## Test results (2026-11-09, close-out run)
| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| `flutter test` | 107/107 (includes 11 asset-library and 26 theme/contrast tests) |
| Backend unit (`npm test`) | 105/105 |
| Backend integration (`npm run test:integration`, Auth + Firestore emulators, rules) | 16/16 |
| `npm run typecheck` / `npm run build` | Pass / pass |
| Debug APK | Builds; bundled assets = 4 fonts + licence |
| Secret scan | Clean |

## Identity and Firebase (verified read-only, 2026-11-09)
- App / bundle ID `com.techfiyr.sprelia` (Android `applicationId` + namespace, iOS Runner;
  `.RunnerTests` for tests). Dart package name `speakdaily` (internal).
- Firebase project ID `sprelia`, number `756773147926`. One Android app
  (`1:756773147926:android:1bc8ce332ae6b5ccce2c37`), **no SHA fingerprints**, **no iOS app**.
  Auth providers and the Firestore database are not verified or configured by the agent.
  All app testing used the Emulator Suite (`demo-sprelia`).

## Remaining limitations
- Google sign-in, email verification, display name capture, profile and time zone editing: not built.
- Phase 1 screens (learn, progress, feedback, conversation) still have inline English strings.
- Recommendation reaches only 6 of 22 scenarios (deterministic first match; see review F9).
- Legacy voice prototype: Express, superseded model IDs, v1alpha tokens, "SpeakDaily" in prompts
  (Phase 6). Release signing still uses the debug key (Phase 10).
- npm: 4 moderate production advisories (firebase-admin, transitive); 5 high in the dev-only `firebase` SDK.
- Final logo, app icon, tutor avatars and illustrations do not exist; placeholders are shown.

## Outstanding owner decisions
1. Tutor candidate images: source, licence, style direction (`doc/ASSET_LIBRARY.md`); history removal if unlicensed.
2. Scenario decisions D1–D8 (`doc/reviews/SCENARIO_REVIEW.md`).
3. Review and approve the engineering-drafted sections of APP_DEVELOPMENT.md (§9 cont.–§19) and BRAND.md (§11 end–§14).
4. Role of Firebase project `sprelia` (dev or prod); iOS app registration; SHA fingerprints; Email/Password provider.
5. Empty-state illustrations: commission or keep icons.
6. Merge strategy for the stacked branches into `main`.

## Approval
- [/] Phase 2 **conditionally approved** by the owner (2026-11-09, "Phase 2 Final Decisions and
  Approval"). Conditions applied below; final confirmation pending before Phase 3.

---

# Final decisions and conditional approval (2026-11-09)

Source: owner documents "Phase 2 Final Decisions and Approval" and "Architecture Decision:
Firebase Environment Strategy". Where they differ on Firebase, the approved architecture
decision applies: **`sprelia` is PRODUCTION**.

## Scenario and tutor decisions
- [x] 1. Study abroad: no longer Emma. Sofia isn't eligible because she doesn't support Academic, so it's assigned to **Alex** (A2–C1, Academic).
- [x] 2. Networking: `social` added explicitly to Alex's supported categories; compatibility checked.
- [x] 3. Onboarding levels A1, A2, B1, B2, C1 (+ "not sure"), in the backend and the app.
- [x] 4. A1 scenarios added: `talking-about-work` (Professional) and `classroom-basics` (Academic), with Emma (now supports Professional and Academic).
- [x] 5. B2 Travel: `trip-planning`, `changing-plans` (free) and `local-culture` (premium). B2 Travel: 1 → 4 scenarios (3 free).
- [x] 6. Recommendation: rotates among all eligible scenarios. A test proves every free scenario is reachable.
- [x] 7. Premium (5): presentations, client-communication, academic-discussions, local-culture, social-events. Free coverage kept for every level each category serves.
- [x] 8. Backend enforcement: `compatibility.ts` + `CatalogService` (refuses to start on violations; publishes `compatibleTutorIds`). The app offers only compatible tutors and blocks incompatible or premium starts.

## Content decisions
- [x] Durations 5, 10 and 15: daily targets 5/10/15 (20 removed; stored 20s are dropped per field). Scenario estimates validated to 5/10/15.
- [x] Human review before publishing: `reviewStatus` with reviewer and date; production publishes only approved scenarios. **All 27 are draft.**
- [x] American English: catalogue, tutor text and ARB strings converted, with tests in the backend and the app.
- [x] Flexible for British English: `content-variants.ts` overlay with `?locale=en-GB` on the API; the app is ready for `app_en_GB.arb`.

## Asset decisions
- [x] Tutor images audited: rights **not established** (provenance stripped by re-encoding; no metadata or C2PA). Status: to be replaced unless the owner provides evidence. Not bundled.
- [x] Git history **not** rewritten (no legal or security reason identified).
- [x] Empty-state icons kept for the MVP.
- [x] `doc/ASSET_LIBRARY.md` updated with sources, licences, status and the audit (§3a).

## Firebase
- [x] `sprelia` recorded as **PRODUCTION** everywhere (`doc/FIREBASE_SETUP.md`, CLAUDE.md, `.agents/*`, APP_DEVELOPMENT §12/§19).
- [x] Code guards: the production project is refused outside `APP_ENV=production` (backend + app), and production must use `sprelia`. Tests run only on the emulators.
- [-] Development Firebase project: **not created**. Superseded on 2026-11-09: the owner approved a single project (`sprelia`) for development and production; no `sprelia-dev` (`phase_3.md`).
- [x] Outstanding production work documented: iOS registration, SHA fingerprints, Email/Password, Firestore + rules, App Check, deployment validation. No production settings changed.

## Documentation
- [x] APP_DEVELOPMENT.md and BRAND.md remain **awaiting owner review** (headers unchanged in that respect).
- [x] Updated: `doc/roadmap/README.md`, this file, `doc/ASSET_LIBRARY.md`, `doc/reviews/SCENARIO_REVIEW.md` §5, `doc/FIREBASE_SETUP.md`, APP_FLOW decision notes.

## Changed files (decisions round, branch `phase-2-closeout`)
- Backend: `src/modules/catalog/{practice.catalog,tutors.catalog,catalog.routes}.ts` (updated),
  `src/modules/catalog/{compatibility,catalog.service,content-variants}.ts` (new),
  `src/modules/users/{recommendation,dashboard,profile.routes,user.schemas,firestore-user.repository}.ts`,
  `src/app.ts`, `src/config/env.ts`, `.env.example`;
  tests `test/{catalog,learning-logic,profile,config}.test.ts`.
- App: `lib/core/config/app_config.dart`, `lib/core/assets/app_assets.dart`, `lib/l10n/app_en.arb` (+ generated),
  `lib/features/{feedback/feedback_screen,onboarding/onboarding_labels,onboarding/steps/plan_step,practice/category_screen,practice/prepare_screen,practice/data/practice_models,profile/data/learning_preferences,tutors/tutors_screen}.dart`;
  tests `test/{core/config/app_config_test,features/screens_test,features/onboarding/onboarding_test,helpers/fakes,l10n/spelling_test}.dart`.
- Docs and config: `doc/{APP_DEVELOPMENT,APP_FLOW,ASSET_LIBRARY,FIREBASE_SETUP}.md`,
  `doc/reviews/SCENARIO_REVIEW.md`, `doc/roadmap/{README,phase_2}.md`, `assets/ATTRIBUTION.md`,
  `CLAUDE.md`, `.agents/{architecture,security}.md`, `env/{README.md,production.example.json,staging.example.json}`.

## Test results (2026-11-09, after decisions)
| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| `flutter test` | 111/111 (incl. 11 asset-library tests and the ARB spelling test) |
| Backend unit | 128/128 (incl. catalogue policy, compatibility, reachability, production-project guard) |
| Backend emulator integration (Auth + Firestore + rules) | 16/16 |
| Typecheck / build | Pass / pass |
| Debug APK | Builds; bundled assets = 4 Inter fonts + OFL licence only |
| Secret scan | Clean |

## Remaining before Phase 3
- Owner confirmation of Phase 2 (conditions applied).
- Content owner review of 27 scenarios (production publishes none until approved).
- Tutor image replacement, or rights evidence.
- Development Firebase project ID approval and creation (Phase 3 preparation).
