# Sprelia (formerly SpeakDaily) — UI/UX Design System

> **Precedence note (2026-11-09):** the product name ("SpeakDaily"), tagline, teal/navy
> palette, logo and icon colours in this document are **superseded by `doc/BRAND.md`**
> (Sprelia, purple). Its type scale, spacing names, components, screen rules, animation
> and accessibility guidance remain in force (see `CLAUDE.md`, document precedence).

**Version:** 1.0 — Proposed  
**Product:** Sprelia (formerly SpeakDaily)  
**Tagline:** Practice English. Speak with confidence everywhere.  
**Design platform:** Flutter, Android first, iOS-ready  
**Theme:** Light

## 1. Brand identity

### Brand purpose
Help people communicate confidently in English through daily speaking practice.

### Brand personality
- Friendly, not childish.
- Intelligent, not intimidating.
- Modern, not overly futuristic.
- Encouraging, not judgmental.
- Premium, but accessible.

### Brand positioning
Sprelia is a personal AI English-speaking coach, not a generic chatbot or grammar-learning application.

## 2. Logo concept

### Recommended direction: The Speaking Wave

Create a distinctive symbol combining:
- A rounded speech bubble.
- A subtle sound wave.
- An abstract letter S.

The symbol should communicate speaking, listening, conversation and confidence.

### Logo variations
1. Primary horizontal logo: symbol + Sprelia wordmark (see BRAND.md).
2. App icon: symbol only.
3. Compact logo: symbol with shortened wordmark.
4. Monochrome logo: white or dark version.
5. Small favicon: simplified symbol.

### Logo requirements
- Recognizable at 24 × 24 px.
- App icon must work at Android adaptive icon sizes.
- No complicated gradients inside the symbol.
- Avoid generic microphone-only logos.
- Keep sufficient clear space around the logo.

## 3. Color system

Recommended primary palette: Teal + Deep Navy.

| Token | Hex | Usage |
|---|---|---|
| Primary | #0F9D91 | Main CTA, active states |
| Primary Dark | #087D74 | Pressed states |
| Primary Light | #E3F5F2 | Selected backgrounds |
| Secondary | #183B56 | Headings, brand depth |
| Accent | #F4B860 | Highlights, achievements |
| Background | #F7FAFC | Main app background |
| Surface | #FFFFFF | Cards and dialogs |
| Text Primary | #183044 | Main text |
| Text Secondary | #64748B | Supporting text |
| Border | #E2E8F0 | Dividers and outlines |
| Success | #16A36A | Success messages |
| Warning | #E6A23C | Warnings |
| Error | #DC5555 | Errors |

### Color usage rules
- Primary teal should identify important actions.
- Navy should establish visual hierarchy.
- Warm accent should be used sparingly.
- Most screens should have white or soft-white backgrounds.
- Never use color alone to communicate an error or success.

## 4. Typography

Recommended font: **Inter**.

Use:
- Bold for main headings.
- Semibold for section headings.
- Medium for buttons and labels.
- Regular for body content.

Typography scale:

| Style | Size | Weight |
|---|---:|---|
| Display | 32 | Bold |
| H1 | 28 | Bold |
| H2 | 24 | Semibold |
| H3 | 20 | Semibold |
| Body Large | 16 | Regular |
| Body | 14 | Regular |
| Caption | 12 | Regular |
| Button | 15 | Semibold |

Support dynamic text scaling and accessibility.

## 5. Spacing and layout

Use an 8-point spacing system.

| Token | Size |
|---|---:|
| XS | 4 px |
| SM | 8 px |
| MD | 12 px |
| LG | 16 px |
| XL | 24 px |
| XXL | 32 px |
| XXXL | 40 px |
| Section | 48 px |

### Corner radius
- Small controls: 8 px.
- Input fields: 12 px.
- Cards: 16 px.
- Large feature cards: 20 px.
- Bottom sheets: 24 px.

Use subtle borders and minimal shadows.

## 6. UI components

Create reusable Flutter components.

### Buttons
- Primary filled teal.
- Secondary outlined.
- Text-only action.
- Destructive action.
- Loading state.
- Disabled state.

### Cards
- Tutor card.
- Scenario card.
- Progress card.
- Vocabulary card.
- Mistake card.
- Subscription card.

### Inputs
- Text input.
- Password input.
- Search.
- Dropdown.
- Selection chips.

### Feedback
- Success notification.
- Error notification.
- Empty state.
- Loading skeleton.
- Confirmation dialog.

Every component must use centralized theme tokens.

## 7. App icon

Concept:
A simplified speech bubble with an S-shaped sound wave.

Background:
Primary teal or a subtle teal gradient.

Symbol:
White.

Style:
Minimal, recognizable, modern.

Do not include small text inside the icon.

Prepare:
- 1024 × 1024 master asset.
- Android adaptive foreground/background.
- iOS icon assets.
- Monochrome variant where supported.

## 8. Brand banner

### Main headline
Practice English. Speak with confidence.

### Supporting text
Your personal AI speaking coach. Practice real conversations, improve your English and build confidence every day.

### Visual direction
- Light background.
- Teal-to-deep-navy gradient accent.
- Friendly tutor illustration.
- Subtle speech-wave graphics.
- Clear logo placement.
- Strong headline hierarchy.

Avoid:
- Crowded text.
- Large decorative microphone imagery.
- Excessive gradients.
- Unrelated stock photography.

### Banner variants
1. Website hero: 1440 × 600 px.
2. App onboarding illustration: portrait.
3. Social media promotional banner: 1200 × 630 px.
4. Google Play feature graphic: 1024 × 500 px.

## 9. Illustration direction

Use friendly, expressive, polished illustrations.

Visual subjects:
- AI tutor personalities.
- Two people talking.
- Speech bubbles.
- Learning progress.
- Vocabulary and practice.

Use a consistent illustration style across all screens.

Tutor portraits must be visually distinguishable:
- Emma: warm and approachable.
- Alex: confident and professional.
- Sofia: expressive and friendly.

Do not mix unrelated illustration styles.

## 10. Screen-by-screen UI rules

### Splash
- Centered logo.
- Clean background.
- Minimal loading animation.

### Welcome
- Brand illustration.
- Main promise.
- Continue with Google.
- Continue with email.

### Onboarding
- One question per screen.
- Clear progress indicator.
- Large selection cards.
- Back and Continue actions.
- Skip optional questions.

### Home
- Friendly greeting.
- Daily speaking progress.
- Large Start Speaking action.
- Recommended tutor and scenario.
- Review mistakes and vocabulary.

### Tutor selection
- Large portraits.
- Personality description.
- Accent and voice information where available.
- Clear selected state.

### Practice discovery
- Category cards.
- Search and filters.
- Scenario difficulty and learning objectives.

### Voice conversation
- Minimal distractions.
- Large tutor visual.
- Clear listening and speaking states.
- Live transcript.
- Visible session timer.
- Mute and end controls.

The voice screen must never feel like an ordinary messaging screen.

### Feedback
- Clear session summary.
- Positive reinforcement.
- Original and improved sentence comparison.
- Explanation.
- Vocabulary cards.
- Save and practice actions.

### Mistake Vault
- Search and category filters.
- Original sentence.
- Improved sentence.
- Explanation.
- Review action.

### Vocabulary
- Word.
- Meaning.
- Example sentence.
- Review status.

### Progress
- Clear charts.
- Speaking minutes.
- Weekly activity.
- Vocabulary learned.
- Mistakes reviewed.

### Subscription
- Clear free and premium comparison.
- Transparent pricing.
- Clear trial and renewal terms where applicable.
- No misleading urgency.

### Profile
- Simple grouped settings.
- Account and privacy controls.
- Subscription management.

## 11. Animation guidelines

Use animations only when they improve understanding.

Recommended:
- Button feedback: 120–180 ms.
- Card transitions: 180–240 ms.
- Screen transitions: 200–300 ms.
- Voice activity animation: continuous but subtle.
- Progress animation: 300–500 ms.

Respect reduced-motion preferences.

## 12. Accessibility

- Maintain WCAG AA contrast for text where applicable.
- Minimum comfortable touch target: 44–48 px.
- Support screen readers.
- Support text scaling.
- Avoid color-only status indicators.
- Provide clear microphone permission explanations.
- Ensure all essential actions are accessible.

## 13. Flutter implementation requirements

Create centralized design tokens:

```text
lib/core/theme/
    app_colors.dart
    app_typography.dart
    app_spacing.dart
    app_radius.dart
    app_theme.dart
```

Create reusable components:

```text
lib/core/widgets/
    app_button.dart
    app_card.dart
    app_text_field.dart
    app_app_bar.dart
    app_bottom_navigation.dart
    app_loading.dart
    app_empty_state.dart
```

Requirements:
- No arbitrary hardcoded colors in feature widgets.
- No arbitrary font sizes where a design token exists.
- No duplicated button or card implementations.
- Keep theme configuration separate from business logic.
- Support light theme consistently.
- Keep future dark theme possible without redesigning features.

## 14. Design quality checklist

Before approving a screen:
- Does it follow the brand palette?
- Is the primary action obvious?
- Is the layout consistent?
- Is typography readable?
- Does it support small and large screens?
- Are loading and error states designed?
- Are touch targets accessible?
- Does it avoid unnecessary visual clutter?
- Does it match the product's speaking-first purpose?

**This design system is the source of truth for all Sprelia Flutter screens** (colors and name per BRAND.md).

