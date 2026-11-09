# Practice Scenario Catalogue Review

**Date:** 2026-11-09 · **Scope:** the 22 scenarios in
`backend/src/modules/catalog/practice.catalog.ts`, checked against APP_FLOW §5, §7 and §8,
`tutors.catalog.ts` and `recommendation.ts`.
**Status:** review only. **No content was changed.** Each finding that needs a product
decision is listed in §4 for the owner.

The catalogue content (descriptions, objectives, vocabulary, durations) was drafted by
engineering in Phase 2 and has not yet been approved by a learning or content owner.

## 1. Inventory

| # | Category | ID | Title | CEFR | Suggested tutor (range) | Min | Obj. | Vocab | Premium | Findings |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | Everyday | `introductions` | Introductions | A1–B1 | Emma (A1–B1) | 5 | 2 | 3 | no | none |
| 2 | Everyday | `daily-routines` | Daily routines | A1–B1 | Emma (A1–B1) | 5 | 2 | 4 | no | none |
| 3 | Everyday | `hobbies` | Hobbies | A1–B2 | Sofia (A1–B2) | 5 | 2 | 3 | no | none |
| 4 | Everyday | `shopping` | Shopping | A1–B1 | Sofia (A1–B2) | 5 | 2 | 4 | no | none |
| 5 | Everyday | `food-restaurants` | Food and restaurants | A1–B2 | Sofia (A1–B2) | 5 | 3 | 4 | no | none |
| 6 | Professional | `job-interviews` | Job interviews | A2–C1 | Alex (A2–C1) | 8 | 3 | 4 | no | F3, F6 |
| 7 | Professional | `office-conversations` | Office conversations | A2–B2 | Alex (A2–C1) | 5 | 2 | 3 | no | none |
| 8 | Professional | `meetings` | Meetings | B1–C1 | Alex (A2–C1) | 8 | 2 | 3 | no | F3, F6 |
| 9 | Professional | `presentations` | Presentations | B1–C1 | Alex (A2–C1) | 8 | 2 | 3 | no | F3, F6 |
| 10 | Professional | `client-communication` | Client communication | B1–C1 | Alex (A2–C1) | 5 | 2 | 3 | no | F3 |
| 11 | Academic | `classroom-discussion` | Classroom discussion | A2–B2 | Alex (A2–C1) | 5 | 2 | 3 | no | none |
| 12 | Academic | `study-abroad` | Study abroad | A2–B2 | Emma (A1–B1) | 5 | 2 | 3 | no | **F1** |
| 13 | Academic | `explaining-ideas` | Explaining ideas | B1–C1 | Alex (A2–C1) | 5 | 2 | 3 | no | F3 |
| 14 | Academic | `academic-discussions` | Academic discussions | B2–C1 | Alex (A2–C1) | 8 | 2 | 3 | no | F3, F6 |
| 15 | Travel | `airport` | At the airport | A1–B1 | Emma (A1–B1) | 5 | 2 | 4 | no | none |
| 16 | Travel | `hotel-check-in` | Hotel check-in | A1–B1 | Sofia (A1–B2) | 5 | 2 | 3 | no | none |
| 17 | Travel | `asking-directions` | Asking for directions | A1–B1 | Emma (A1–B1) | 5 | 2 | 4 | no | none |
| 18 | Travel | `travel-problems` | Travel problems | A2–B2 | Sofia (A1–B2) | 5 | 2 | 3 | no | none |
| 19 | Social | `making-friends` | Making friends | A1–B2 | Sofia (A1–B2) | 5 | 2 | 3 | no | none |
| 20 | Social | `networking` | Networking | B1–C1 | Alex (A2–C1) | 5 | 2 | 3 | no | **F2**, F3 |
| 21 | Social | `small-talk` | Small talk | A1–B2 | Sofia (A1–B2) | 5 | 2 | 3 | no | none |
| 22 | Social | `social-events` | Social events | A2–B2 | Sofia (A1–B2) | 5 | 2 | 3 | no | none |

**Completeness (APP_FLOW §8):** every scenario has a title, description, CEFR
recommendation, learning objectives, estimated duration, suggested tutor and vocabulary.
All 22 APP_FLOW scenarios are present in the specified five categories (5/5/4/4/4).
Titles match APP_FLOW except "Airport" → "At the airport".

## 2. Level coverage

Count of scenarios available at each self-reported onboarding level ("Not sure" is treated as A2):

| Category | A1 | A2 | B1 | B2 |
|---|---:|---:|---:|---:|
| Everyday | 5 | 5 | 5 | 2 |
| Professional | **0** | 2 | 5 | 5 |
| Academic | **0** | 2 | 3 | 4 |
| Travel | 3 | 4 | 4 | **1** |
| Social | 2 | 3 | 4 | 4 |

## 3. Findings

- **F1 — Tutor level mismatch (study abroad).** The scenario is A2–B2, but the suggested tutor
  Emma is A1–B1 and isn't tagged for the Academic category. B2 learners are routed to a tutor
  positioned below their level.
- **F2 — Tutor category mismatch (networking).** Alex is suggested but is tagged only for
  Professional and Academic. Sofia's range (A1–B2) can't cover the scenario's C1 ceiling, so
  either the ceiling or Alex's tags would need to change.
- **F3 — C1 ceilings vs. onboarding.** Seven scenarios reach C1, but onboarding offers only A1–B2
  (APP_FLOW §5). This is fine as headroom, but C1 is never selectable or recommended.
  `academic-discussions` starts at B2.
- **F4 — No A1 entry in Professional or Academic.** An A1 learner with career, business or
  academic goals gets no recommended scenario. The recommendation falls back to free
  conversation with Emma. This is safe, but the "Suggested practice" category may then show
  no suitable scenario for that learner.
- **F5 — Thin B2 coverage in Travel (1) and Everyday (2).** Upper-intermediate travel learners
  get little variety.
- **F6 — 8-minute scenarios vs. the 10-minute free allowance.** Four scenarios use 80% of a free
  user's daily time. Durations are estimates; the server enforces the real limit.
- **F7 — Content is not level-differentiated.** Objectives and vocabulary are the same at every
  level in a range (e.g. job interviews A2–C1). Adapting to level is left to the tutor during the
  conversation (Phase 6 prompts). The written objectives may read as too hard for A2 or too easy for C1.
- **F8 — Content depth.** 2–3 objectives and 3–4 vocabulary items per scenario. This is
  deliberately short for the MVP, but it hasn't been reviewed by a learning owner.
- **F9 — Recommendation reach.** The deterministic recommendation picks the *first*
  level-appropriate scenario in each category, so only 6 of 22 scenarios are ever recommended
  (introductions, hobbies, job-interviews, airport, travel-problems, classroom-discussion).
  Variety and personalization are planned for Phase 8 (mistakes, history).
- **F10 — No premium scenarios.** All 22 are free. APP_FLOW §16 lists "Advanced scenarios" as a
  Premium benefit, and the "premium-only scenario" paywall trigger can't occur yet.
- **F11 — Language conventions.** Content uses British spelling ("practise" as a verb) and curly
  apostrophes consistently, which matches the app's ARB strings. BRAND §8 asks for "simple
  international English" and doesn't pick a spelling standard.

Consistency checks that passed: every suggested tutor exists; IDs are unique kebab-case;
categories match tutor focus areas except F1 and F2; descriptions are one sentence in second
person; no scenario is marked premium without a premium plan.

## 4. Decisions requested (owner)

| # | Decision | Options |
|---|---|---|
| D1 (F1) | Study abroad tutor | (a) suggest Alex, (b) narrow to A2–B1 and tag Emma for Academic, (c) keep |
| D2 (F2) | Networking tutor | (a) tag Alex for Social, (b) cap at B2 and suggest Sofia, (c) keep |
| D3 (F3) | Offer C1 in onboarding? | (a) add "C1 Advanced" (APP_FLOW change), (b) keep A1–B2 and treat C1 as headroom |
| D4 (F4/F5) | Add A1-friendly Professional/Academic and more B2 Travel/Everyday scenarios? | content additions |
| D5 (F6) | 8-minute durations for free users | keep, or cap free-plan estimates at 5 min |
| D6 (F7/F8) | Content owner review and level-specific objectives and vocabulary | assign a reviewer |
| D7 (F10) | Which scenarios become Premium? | product/pricing decision (Phase 9) |
| D8 (F11) | Spelling standard (British, American or international) | brand decision |
