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