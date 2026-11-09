# Sprelia — Brand Guidelines & Implementation Specification

**Document:** `BRAND.md`  
**Brand:** Sprelia  
**Status:** Provisional — pending trademark, domain and app-store clearance  
**Version:** 1.0 (+ engineering additions 2026-11-09)  
**Completeness:** complete (§1–§14, verified 2026-11-09; no truncated sections)  
**Review status:** §1 to §11 rule 7 are the owner's original text. The end of §11 and
§12–§14 (accessibility tokens, rebranding requirements, asset status) were drafted by
engineering and are **pending owner review**. §4's palette table records the contrast fix requested
in roadmap phase 2 §A (text secondary #77758B → #6A687C).  
**Purpose:** Source of truth for AI coding agents, designers and developers.

---

## 1. Brand Overview

### Brand name

**Sprelia**

Pronunciation: SPREE-lee-ah

Sprelia is an AI-powered English-speaking companion that helps people improve their spoken English through natural conversations, personalized AI tutors and practical speaking exercises.

### Brand tagline

**Find your voice. Speak with confidence.**

### Product positioning

Sprelia is a friendly, intelligent and encouraging AI English-speaking coach.

It should feel like speaking with a supportive language companion rather than attending a traditional classroom or interacting with a robotic chatbot.

### Brand promise

Help users become more confident English speakers through consistent, practical and enjoyable conversation practice.

### Brand status and naming restrictions

- Sprelia is the selected provisional brand direction.
- It has NOT received formal global trademark clearance.
- Domain availability has not been confirmed.
- Google Play and Apple App Store name availability has not been confirmed.
- Do not claim that Sprelia is trademarked, registered or legally exclusive.
- Do not purchase domains, submit trademark applications or publish store listings without explicit authorization.
- Keep the brand name configurable so a future name change does not require rewriting the application.

---

## 2. Target Audience

Sprelia serves a global audience.

Primary users:
- People learning English as a second language.
- Students and university graduates.
- Professionals who need English at work.
- People preparing for job interviews.
- People who want to improve everyday communication.
- People who understand English but lack confidence speaking it.

The experience must welcome all genders, ages and cultural backgrounds.

### User emotional goals

Users should feel:

1. Comfortable speaking without fear of judgment.
2. Encouraged when they make mistakes.
3. Proud of their daily progress.
4. Motivated to return for another conversation.
5. Confident using English in real situations.

---

## 3. Brand Personality

The brand should communicate these characteristics:

| Attribute | Direction |
|---|---|
| Friendly | Warm and welcoming |
| Feminine-inspired | Soft, elegant and approachable |
| Intelligent | Helpful and capable |
| Encouraging | Positive without being childish |
| Modern | Technology-driven and polished |
| Inclusive | Welcoming to everyone |
| Trustworthy | Honest about AI capabilities |

### Brand character

Imagine a friendly, confident female language coach who listens patiently, encourages the learner and helps them improve naturally.

The brand must not look like:
- A children's educational game.
- A traditional school management system.
- A robotic AI assistant.
- A generic corporate SaaS dashboard.
- A dating or social networking application.

---

## 4. Visual Identity

### Primary color palette

Use purple as the dominant brand color.

| Token | Hex | Usage |
|---|---|---|
| Primary | `#7656D9` | Main buttons, active navigation, brand |
| Primary dark | `#5235A8` | Strong emphasis, headings on tinted surfaces |
| Primary light | `#F1EBFF` | Cards, backgrounds, soft highlights |
| Accent coral | `#FF827A` | Important highlights and friendly details |
| Background | `#FAF9FF` | Main light-theme background |
| Surface | `#FFFFFF` | Cards, dialogs and panels |
| Text primary | `#20213A` | Main text |
| Text secondary | `#6A687C` | Supporting text (darkened from `#77758B` for WCAG AA; see §12) |
| Border | `#EAE7F2` | Dividers and card outlines |
| Success | `#249B70` | Positive progress icons and fills (text uses Success text `#1C7857`, §12) |
| Warning | `#E9A23B` | Decorative warning accents (text uses Warning text `#945E11`, §12) |
| Error | `#D95757` | Error icons and borders (text and destructive fills use Error text `#C82D2D`, §12) |

### Color usage rules

- Purple is the primary identity.
- White and very light lavender should dominate the main interface.
- Coral should be used sparingly.
- Do not use multiple saturated colors in the same component without a clear reason.
- Maintain accessible contrast for text and interactive elements.
- Never use color alone to communicate status.

### Typography

Preferred typeface: **Inter**.

Fallback:
- Android: system sans-serif.
- iOS: system sans-serif.
- Web: Inter, system-ui, sans-serif.

Typography hierarchy:

| Element | Recommended size |
|---|---:|
| Large hero heading | 30–36 px |
| Screen title | 24–28 px |
| Section title | 18–22 px |
| Body | 14–16 px |
| Supporting text | 12–14 px |
| Button | 14–16 px |

Use medium and semibold weights for headings. Body text should remain comfortable to read.

### Shape language

- Cards: 16–20 px radius.
- Primary buttons: 14–18 px radius.
- Input fields: 12–16 px radius.
- Avatar containers: circular or softly rounded.
- Use consistent spacing based on a 4 px grid.
- Prefer subtle shadows and light borders over heavy shadows.

---

## 5. Logo Direction

### Primary logo concept

Create an original logo combining:

1. A speech bubble.
2. A sound-wave or voice-wave element.
3. A subtle, friendly shape that represents communication.

The wordmark should read:

**Sprelia**

The logo should communicate conversation, voice, confidence and approachability.

### Logo variants

Required variants:

- Full horizontal logo with symbol and wordmark.
- Symbol-only logo.
- App icon.
- Monochrome dark logo.
- Monochrome white logo.
- Light-background version.
- Dark-background version.

### Logo rules

- Use the approved purple palette.
- Preserve consistent proportions.
- Do not distort the logo.
- Do not add unnecessary gradients, outlines or decorative elements.
- Keep the logo legible at small sizes.
- Do not use an existing company's logo or imitate a competitor's visual identity.

### App icon

Design a recognizable symbol that works at small sizes.

Requirements:
- Square artwork.
- No tiny text.
- Clear silhouette.
- Purple-led background.
- Speech-wave concept.
- Suitable for Android adaptive icons and Apple icon requirements.
- Maintain adequate safe zones for platform cropping.

Do not use the complete wordmark as the only app icon design.

---

## 6. AI Tutor Visual Identity

Sprelia uses multiple AI tutors.

Each tutor should have a recognizable personality while maintaining one consistent illustration style.

### Emma — Beginner Coach

Personality:
- Warm.
- Patient.
- Supportive.
- Encouraging.

Teaching level: A1–B1.

Visual direction: Friendly female tutor, gentle expression, soft purple clothing and approachable appearance.

### Alex — Professional Coach

Personality:
- Confident.
- Professional.
- Clear communicator.

Teaching level: A2–C1.

Focus:
- Workplace English.
- Job interviews.
- Professional communication.
- Presentations.

Visual direction: Professional, modern and confident tutor.

### Sofia — Everyday Conversation Coach

Personality:
- Cheerful.
- Natural.
- Relaxed.
- Friendly.

Teaching level: A1–B2.

Focus:
- Daily conversations.
- Travel.
- Social situations.
- Natural expressions.

Visual direction: Friendly female tutor with an expressive and welcoming appearance.

### Avatar requirements

- Consistent 3D-inspired or polished illustrative style.
- High-quality rendering.
- Soft lighting.
- Natural expressions.
- Consistent proportions.
- Purple brand accents.
- Inclusive and respectful representation.

Do not generate unrelated visual styles for different tutors.

---

## 7. User Interface Design Principles

The application should use a light theme by default.

### Main navigation

The five primary destinations are:

1. Home
2. Practice
3. Learn
4. Progress
5. Profile

### Home screen

The home screen should communicate:

- Welcome message.
- Daily speaking goal.
- Daily practice progress.
- Start speaking action.
- Recommended tutor.
- Continue learning.
- Recent achievements.

The primary action should be immediately visible.

### Practice experience

The conversation screen should feel immersive and distraction-free.

Required elements:
- Tutor avatar.
- Tutor name.
- Connection status.
- Microphone controls.
- Conversation timer.
- Live conversation state.
- End session action.

Do not interrupt live conversations with grammar corrections. Corrections are presented after the conversation.

### Session feedback

After a session, present:
- Speaking summary.
- Grammar corrections.
- Better sentence suggestions.
- Useful vocabulary.
- Pronunciation feedback when supported by reliable analysis.
- Positive achievements.
- Recommended next practice.

Feedback must be constructive and encouraging, never humiliating.

### Learn screen

Include:
- Mistake Vault.
- Vocabulary collection.
- Saved expressions.
- Previous corrections.
- Learning exercises.

### Progress screen

Use simple visualizations to show:
- Speaking minutes.
- Daily streak.
- Practice consistency.
- Vocabulary growth.
- Learning progress.
- Session history.

Never invent progress statistics.

---

## 8. Brand Voice and Writing Style

### Tone

Friendly, clear, encouraging and conversational.

Use simple international English.

Avoid unnecessarily complex expressions.

### Preferred examples

Instead of:
"Your linguistic proficiency has improved."

Use:
"You're getting better at expressing yourself!"

Instead of:
"Incorrect grammatical construction."

Use:
"Here's a more natural way to say it."

Instead of:
"Session terminated."

Use:
"Great practice! Your session is complete."

### Microcopy principles

- Encourage users to speak.
- Celebrate effort, not just perfect results.
- Explain mistakes without judgment.
- Use concise button labels.
- Avoid excessive emojis.
- Avoid exaggerated AI promises.
- Never promise guaranteed fluency.

---

## 9. Marketing and Google Play Identity

### Proposed Google Play title

`Sprelia: English Speaking`

This is a proposed ASO title, subject to name availability and final character-count validation.

### Proposed short description

"Speak English confidently with AI tutors. Practice real conversations every day."

### Proposed long description opening

"Find your voice and speak English with confidence.

Sprelia is your friendly AI English-speaking companion. Practice natural conversations, improve your communication skills, learn useful vocabulary and receive personalized feedback after every session."

### Keyword themes

Primary:
- English speaking practice
- Speak English
- English conversation practice

Secondary:
- AI English tutor
- English speaking app
- Spoken English
- English fluency
- English pronunciation
- Business English
- English interview practice
- Daily English practice

Do not keyword-stuff metadata.

Validate current platform limits, localized keywords and competitor positioning before publishing.

### Marketing banner direction

The main banner should include:

- Sprelia logo.
- One or more friendly tutor avatars.
- Main tagline.
- Short product benefit.
- Purple/lavender visual environment.
- Clear visual hierarchy.

Avoid filling banners with paragraphs or too many feature claims.

---

## 10. Product Brand Experience

The brand should be consistent throughout:

- Android application.
- iOS application.
- Website.
- Landing page.
- Google Play listing.
- Apple App Store listing.
- Notifications.
- Emails.
- Subscription paywall.
- Social media.
- Help and support pages.

Use the same logo, colors, typography and writing style across all touchpoints.

### Notifications

Examples:

"Ready for a little English practice?"

"Your speaking goal is waiting for you."

"Five minutes today can make a difference."

"You're building a great speaking habit!"

Avoid aggressive or guilt-inducing notifications.

---

## 11. Flutter Implementation Requirements

The brand system must be implemented centrally, not scattered across individual screens.

Suggested structure:

```text
lib/
  core/
    theme/
      app_theme.dart
      app_colors.dart
      app_typography.dart
      app_spacing.dart
      app_radius.dart
    branding/
      app_brand.dart
      brand_assets.dart
  shared/
    widgets/
      brand_logo.dart
      tutor_avatar.dart
      primary_button.dart
      app_card.dart

assets/
  branding/
    logo/
    icons/
    banners/
  tutors/
    emma/
    alex/
    sofia/
```

### Implementation rules

1. Use centralized color and typography tokens.
2. Never hardcode brand colors in individual feature screens.
3. Use reusable brand components.
4. Keep assets organized by purpose.
5. Use scalable SVG or vector assets where appropriate.
6. Use optimized raster assets for illustrations and avatars.
7. Support different screen sizes and pixel densities (vector assets, or 1x/2x/3x raster variants).
8. Keep the brand name in one configurable place (`lib/core/branding/app_brand.dart`).
9. Mark every temporary asset clearly as a placeholder until the approved asset exists.
10. Respect the accessibility rules in §12.

> **Sections 11 (end) to 14** were completed on 2026-11-09 by engineering from the
> approved brand direction and Phase 2 requirements. They are pending owner review.

### Typeface delivery

Inter (SIL Open Font License 1.1) is bundled with the app in `assets/fonts/inter/`
(Regular 400, Medium 500, SemiBold 600, Bold 700). Fonts are never downloaded at runtime.

---

## 12. Accessibility and Color Contrast

All text must meet **WCAG 2.2 AA**: at least 4.5:1, or 3:1 for large text (24 px, or
18.66 px bold). Non-text UI elements (icons, borders that convey meaning) need at least 3:1.

### Accessible text tokens

The original palette kept the purple identity, but four colors failed AA when used as
text. The fix keeps every hue and only darkens it where the color is used for text.

| Token | Hex | Use | Contrast |
|---|---|---|---|
| Text secondary | `#6A687C` (was `#77758B`) | Supporting text on any surface | 5.16 on background, 5.41 on white, 4.65 on primary light |
| Error text | `#C82D2D` | Error messages and destructive button fills (white label) | 5.43 with white |
| Success text | `#1C7857` | Positive text such as an improved sentence | 5.42 on white |
| Warning text | `#945E11` | Warning text | 5.43 on white |

The base Error `#D95757` and Success `#249B70` remain the brand colors for icons,
borders and decorative fills, where they pass 3:1 against white. Warning `#E9A23B` is
decorative only (2.17:1) and must always be paired with text.

### Verified pairs

| Pair | Ratio | Result |
|---|---:|---|
| White text on Primary `#7656D9` (primary button) | 5.12 | Pass |
| Text primary on background / white | 15.4 / 16.1 | Pass |
| Primary dark on primary light (tinted surfaces) | 7.42 | Pass |
| Primary `#7656D9` text on primary light | 4.40 | Fail. Use Primary dark on tinted surfaces. |
| Text primary on Accent coral | 6.51 | Pass. Never use white text on coral. |

### Rules
- Never use color alone to convey status. Pair it with text or an icon.
- Minimum touch target: 48 × 48 px.
- Support system text scaling. Layouts must not clip at 200% text size.
- Automated tests in `test/core/theme/` enforce these ratios.

---

## 13. Provisional Name and Rebranding Requirements

Sprelia is provisional. It must not be presented as trademarked, and no store listing,
domain purchase or trademark filing happens without explicit authorization.

Current identity (local development):

| Item | Value |
|---|---|
| Visible app name | Sprelia (Android `android:label`, iOS `CFBundleDisplayName`, `CFBundleName`) |
| Android application ID / namespace | `com.techfiyr.sprelia` |
| iOS bundle ID | `com.techfiyr.sprelia` (tests: `com.techfiyr.sprelia.RunnerTests`) |
| Firebase project | `sprelia` (project number 756773147926) |
| Dart package name | `speakdaily` (internal, not user-visible) |
| Repository | `techfiyr/Sprelia` |

If the name changes **before** the first store upload, update all of the following:
1. `lib/core/branding/app_brand.dart` (name, tagline).
2. Android `android:label`, and iOS `CFBundleDisplayName` and `CFBundleName`.
3. Application and bundle IDs (they are **permanent after the first store upload**), the
   Kotlin `MainActivity` package path, and the Firebase app registrations and config files.
4. Firebase project display name. Project IDs cannot be renamed, so create new projects if the ID must change.
5. Permission strings (microphone usage text), notification copy and email templates.
6. Logo, app icon, splash and banners (`assets/branding/`).
7. Store listings, privacy policy, terms, website and support pages.
8. Backend user-facing strings, the AI tutor system prompts ("Sprelia English tutor") and analytics property names.
9. This document and `doc/DESIGN_SYSTEM.md`.

If the name changes **after** publication: the application ID stays the same, and only the
visible name, assets and listings change.

---

## 14. Asset Status

| Asset | Status |
|---|---|
| Logo (all variants) | **Not designed.** The app shows a labelled placeholder (`BrandLogo`). |
| App icon | **Not designed.** Flutter default icon. |
| Tutor portraits (Emma, Alex, Sofia) | **Not designed.** Initial-letter placeholders (`TutorAvatar`). |
| Marketing banners | Not designed |
| Inter typeface | Bundled (v4.1, OFL) |

Do not generate or ship invented final assets. Replace each placeholder only with an approved asset.
The full inventory, specs and licence status are in `doc/ASSET_LIBRARY.md`.

**End of brand guidelines.**
