# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Stack
Static HTML/CSS/vanilla JS published by Netlify from `backend/netlify/public` (owner decision, existing). The product itself is a Flutter Android app (iOS later) with a Node/Firebase backend; this record covers the marketing website. Binding site rules, enforced by an existing test: first-party resources only (no external URLs, no inline scripts, no inline `style=` attributes or event handlers), no analytics or advertising code, one `<h1>` per page, skip link, `lang="en"`.

## Users
Adult (18+) learners of English as an additional language who want to practise speaking out loud, privately and daily, without a human tutor. Confirmed for this round: the page's main action is trying the free guest lesson. (Inferred from product docs: beginner to advanced, A1 to C1; Android-first markets.)

## Product Purpose
Hermione is an AI English speaking coach. Learners hold real-time voice conversations with AI tutors (Emma, Alex, Sofia), practise practical scenarios, and get corrections and suggestions after the session rather than mid-conversation. A daily practice target and streak support habit. Success: a visitor tries the free lesson and later subscribes.

## Positioning
Speaking-first practice with a friendly AI tutor and feedback delivered after the conversation, so the learner can stay in flow and build confidence instead of being interrupted.

## Operating Context
Free guest sample lesson (no account) → create an account → active subscription unlocks everything else (server-verified). Free plan voice time was 10 minutes/day in the backend; prices, trials and Premium allowance are not final. Non-subscribers see a bottom banner ad area in the app. Website pages: landing, privacy, terms, AI disclaimer, content policy, cookies, 404, consent banner.

## Capabilities and Constraints
- Android first; iOS later; the app is not published yet ("In development: not yet available" must stay true).
- All tutors are AI, never real people; the AI disclaimer link must stay near tutor content.
- Voice recordings are not stored by default; account and learning data can be deleted in the app.
- Purchases (RevenueCat) and ads (AdMob) are not configured; the page must not imply they work today.
- Policy pages are drafts with `[Review: …]` operator placeholders; keep them clearly marked.

## Brand Commitments
Name: Hermione (owner decision; provisional, no trademark, domain or store-name clearance). Not affiliated with any book, film or game franchise: no franchise imagery, characters, costumes, symbols, fonts or art. Headline "Learn English with Hermione"; subtitle "Learn smarter. Speak with confidence." The original generic tutor mascot (bun, rectangular glasses, teal cardigan, open book) and the speech-bubble-with-book logo (`assets/logo-mark.svg`, `assets/mascot.svg`) are kept.

## Evidence on Hand
None of: testimonials, user counts, ratings, press, benchmarks, pricing. Do not fabricate any. The progress infographic must stay labelled as an example. Real assets: logo mark, mascot SVG, favicon, tutor names and roles, the guest lesson flow (Meet the tutor, say a phrase, two multiple-choice questions, build a sentence).

## Product Principles
1. Honest about status: in development, AI tutors, prices not final; never imply live purchases, ads or users.
2. Speaking first: every section should make the act of speaking feel doable and low-pressure.
3. Warm, not childish: playful and welcoming for adults, never infantilising.
4. One action: the free lesson leads; everything else supports the decision to try it.
5. Original identity: nothing borrowed from any franchise.

## Accessibility & Inclusion
WCAG AA contrast, visible focus, reduced-motion respected (existing rule), works at 390 px width and up, keyboard-operable, no content hidden by animation by default. Learners are non-native English speakers: plain, short sentences.
