# Website and legal drafts: review items

The landing page and the policy drafts in `backend/netlify/public/` are based on the documented
product (`APP_DEVELOPMENT.md`, `APP_FLOW.md`, `BRAND.md`, `.agents/security.md`) as of 2026-11-09.
They are **drafts, not legal advice**, marked "Draft for review", `noindex`, and blocked by
`robots.txt` until approved. A qualified professional must review them before publication.

## Placeholders for facts only the owner or counsel can supply (`[Review: …]` on the pages)
| Item | Pages |
|---|---|
| Legal name and registered address of the operator | All (footer), Privacy, Terms |
| Contact, privacy and support emails / in-app reporting channel | All (footer), Privacy, Terms, AI disclaimer, Content policy |
| Effective date | All policy drafts |
| Data protection officer or EU/UK representative, if required | Privacy |
| Legal bases per jurisdiction | Privacy |
| Gemini API terms and data-use settings for the paid tier | Privacy |
| Data processing agreements and international transfer safeguards | Privacy |
| Retention of server logs and backups | Privacy |
| Rights and complaint authority per jurisdiction | Privacy |
| Warranty disclaimer and limitation of liability | Terms |
| Governing law, venue and dispute resolution | Terms |

## Policy choices not yet approved (marked "Pending decision")
| Choice | Current state |
|---|---|
| Account deletion behavior | Implemented as immediate hard delete (recommendation D2, not approved) |
| Transcript retention period | Open (`APP_DEVELOPMENT.md` §19) |
| Age confirmation (18+) | Open |
| Premium prices, trials, renewal and refunds | Test prices only ($5.99 / $39.99), not final |
| Ad personalization and ad consent | Open (AdMob planned, free plan only) |
| In-app analytics/advertising identifier consent | Open (Firebase Analytics/Crashlytics planned) |

## Stated as facts (from approved or implemented decisions)
Adults 18+; email/password (verified) and Google sign-in; data categories actually stored by the
API; Firestore in the United States (`us-east5`, Ohio); Gemini as AI provider; raw voice not stored by
default; no transcripts/audio in analytics or crash reports; 10 free minutes per local day; ads
never during a conversation; Premium via the app store; in-app account deletion with re-sign-in;
Netlify hosting; feedback after the conversation; no pronunciation scoring; self-reported levels.
Features not yet built (voice, Premium, ads, analytics) are described as planned or "when available".

## Cookies
The site sets no cookies and loads no third-party scripts. Only the consent choice is stored, in
`localStorage` (`sprelia.consent`, versioned record, strictly necessary). Reject all, accept all and
manage preferences are offered; optional categories (analytics, marketing) are unused and default
off. Any future optional script must check `window.SpreliaConsent.has(...)` and bump the consent
version when categories change.
