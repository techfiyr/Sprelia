---
name: Hermione Marketing Site (Sing-along stage)
description: A violet karaoke stage where practice lines light up word by word in sun yellow.
colors:
  stage: "#3b1fa8"
  stage-deep: "#25106b"
  stage-lift: "#5033c9"
  lit-sun: "#ffd166"
  unlit-lavender: "#bfb1f5"
  on-stage: "#f1ecff"
  on-stage-2: "#d4c9fa"
  sun-ink: "#2a1650"
  bubble-coral: "#ff7a6b"
  paper: "#f4f0ff"
  paper-ink-2: "#4a3d73"
  correction-red: "#c4402f"
typography:
  display:
    fontFamily: "ui-rounded, SF Pro Rounded, Arial Rounded MT Bold, Nunito, Trebuchet MS, system-ui, sans-serif"
    fontSize: "clamp(2.5rem, 8.4vw, 4.75rem)"
    fontWeight: 800
    lineHeight: 1.04
    letterSpacing: "-0.02em"
  headline:
    fontFamily: "ui-rounded, SF Pro Rounded, Arial Rounded MT Bold, Nunito, Trebuchet MS, system-ui, sans-serif"
    fontSize: "clamp(2rem, 6vw, 3.4rem)"
    fontWeight: 800
    lineHeight: 1.04
    letterSpacing: "-0.02em"
  title:
    fontFamily: "ui-rounded, SF Pro Rounded, Arial Rounded MT Bold, Nunito, Trebuchet MS, system-ui, sans-serif"
    fontSize: "clamp(1.6rem, 5.4vw, 3rem)"
    fontWeight: 800
    lineHeight: 1.12
    letterSpacing: "-0.015em"
  body:
    fontFamily: "ui-rounded, Nunito, Segoe UI, system-ui, -apple-system, Roboto, Noto Sans, Arial, sans-serif"
    fontSize: "1.1rem"
    fontWeight: 400
    lineHeight: 1.6
  label:
    fontFamily: "ui-rounded, Nunito, Segoe UI, system-ui, -apple-system, Roboto, Noto Sans, Arial, sans-serif"
    fontSize: "0.9rem"
    fontWeight: 700
    lineHeight: 1.6
rounded:
  caption: "6px"
  mark: "4px"
  card: "1.25rem"
  panel: "28px"
  pill: "999px"
spacing:
  xs: "0.25rem"
  sm: "0.75rem"
  md: "1.25rem"
  lg: "2rem"
  section: "clamp(3rem, 8vw, 6rem)"
components:
  button-sun:
    backgroundColor: "{colors.lit-sun}"
    textColor: "{colors.sun-ink}"
    rounded: "{rounded.pill}"
    padding: "0.9rem 1.6rem"
    height: "48px"
  practice-line:
    backgroundColor: "{colors.stage-deep}"
    textColor: "{colors.lit-sun}"
    typography: "{typography.title}"
    rounded: "{rounded.card}"
    padding: "1rem 1.25rem"
  caption-bar-chip:
    backgroundColor: "rgba(0, 0, 0, 0.55)"
    textColor: "#ffffff"
    rounded: "{rounded.caption}"
    padding: "0.25rem 0.8rem"
  transcript-card:
    backgroundColor: "#ffffff"
    textColor: "{colors.sun-ink}"
    rounded: "{rounded.card}"
    padding: "1.5rem"
---

# Design System: Hermione Marketing Site (Sing-along stage)

Scope: the landing page (`<body class="stage">`) in `backend/netlify/public/assets/site.css`. The policy pages keep the older light cream and plum styles and are not part of this system. The Flutter app (`lib/core/branding`) uses a separate warm cream and plum palette and is not part of this system yet.

## Overview

**Creative North Star: "The Sing-along Stage"**

A lyric-video stage. Saturated violet is the ground, deeper ink-violet is the pit, and words are lit sun-yellow as if voiced. The page proves speaking by making it visible: the hero lines sing in word by word on load, later lines sing as they scroll into view, and any practice line replays on tap or Enter. The mascot is the small "singer" at stage right, kept in its own colours.

Density is generous: huge lyric lines, wide bands, one action. Reading-heavy content (feedback, plans, privacy) drops to a quiet pale-lavender "paper" band so the stage never carries small print. The mood is warm and low-pressure for adults, not nightlife.

Constraints that shape the build: first-party only, no inline scripts or styles, no network fonts. Content is fully visible and lit without JavaScript. Under reduced motion every word is lit and nothing animates.

**Key Characteristics:**
- Violet bands alternate stage, lift, and deep; paper bands interrupt for reading.
- Sun yellow is reserved for lit words, act labels, the one primary action, links on stage, and focus rings.
- Display voice is a heavy rounded system stack at weight 800, tight tracking.
- Pills for controls, large rounded rows for practice lines, subtitle-bar chips for captions.
- Depth is tonal; shadows are soft and rare.

## Colors

A drenched violet field with one hot yellow, one small coral accent, and a pale lavender reading surface.

### Primary
- **Stage Violet** (`stage`): the ground for hero, lesson, and finale bands, and the page background.
- **Lit Sun** (`lit-sun`): lit words, the primary button fill, act labels, on-stage links, selection, scrollbar thumb, focus ring, and the status dot.

### Secondary
- **Bubble Coral** (`bubble-coral`): only the speech-bubble beside the mascot. Hard-coded in the rule, not a variable.

### Neutral
- **Pit Violet** (`stage-deep`): header, footer, caption bar, tutors band, and the row fill behind practice lines.
- **Lifted Violet** (`stage-lift`): the practice band, one step lighter than the stage.
- **Unlit Lavender** (`unlit-lavender`): words before they are lit (JS only; solid tint, not opacity).
- **Stage White and Mist** (`on-stage`, `on-stage-2`): body copy and secondary copy on violet.
- **Sun Ink** (`sun-ink`): text on yellow and on paper.
- **Paper Lavender** (`paper`) with **Paper Ink** (`paper-ink-2`): quiet reading bands.
- **Correction Red** (`correction-red`): the strike-through on a learner's wrong phrase only.

### Named Rules
**The One Lit Colour Rule.** Yellow means voiced or actionable: a lit word, the primary action, an act label, or focus. Never decorative fill.

**The Quiet Paper Rule.** Paragraphs longer than two lines on the page live on paper bands in dark ink, not on violet.

## Typography

**Display Font:** system rounded stack: ui-rounded, SF Pro Rounded, Arial Rounded MT Bold, Nunito, Trebuchet MS, system-ui, sans-serif.
**Body Font:** ui-rounded, Nunito, Segoe UI, system-ui stack (the shared site stack).

**Character:** Friendly, heavy, rounded. Because the display face resolves to whatever the device has, appearance varies by platform. No font file could be self-hosted offline; a drop-in of an OFL rounded face such as Fredoka (self-hosted, first-party) is the recommended follow-up and would replace the display stack without changing sizes.

### Hierarchy
- **Display** (800, clamp(2.5rem, 8.4vw, 4.75rem), 1.04): the hero lyric lines; lit words, white otherwise.
- **Headline** (800, clamp(2rem, 6vw, 3.4rem), 1.04): section titles on stage; smaller on paper (clamp(1.7rem, 4.6vw, 2.7rem)); finale up to 5.5rem.
- **Title** (800, clamp(1.6rem, 5.4vw, 3rem), 1.12): practice lines. Act labels and tutor names use the same face at 2 to 3.6rem.
- **Sub** (800, clamp(1.35rem, 4.2vw, 2.1rem), 1.15): the lit subtitle under the hero.
- **Body** (400, 1.1 to 1.15rem, 1.6): ledes capped near 34 to 38rem.
- **Label** (700, 0.85 to 0.95rem): transcript captions, tags, caption chips.

### Named Rules
**The Lyric Line Rule.** Display type is set as lines made of word spans so each word can light independently; headlines never wrap inside a word (`nowrap` per word).

## Layout

One centred container (max 72rem, 1.25rem side padding). The hero is a two-column grid at 56rem and up (copy 1.3fr, mascot 0.7fr), stacked below. Section bands use vertical padding `clamp(3rem, 8vw, 6rem)`; the finale is larger (`clamp(4rem, 10vw, 8rem)`). The lesson setlist and tutors list are ruled rows (2px translucent white top borders) that become two columns (16rem label, text) at 48rem. Feedback and plans are two-column at 52rem. Rhythm is rem-based in 0.25 / 0.75 / 1.25 / 2rem steps. Interactive minimum height is 44 to 48px.

## Elevation & Depth

Mostly tonal: depth comes from stepping stage, lift, and pit violets. Shadows exist in two places only: the yellow button (`0 10px 22px rgba(0,0,0,0.28)`) and the white transcript card on paper (`0 12px 28px rgba(37,16,107,0.14)`). Both are soft blurred shadows with no hard offsets.

### Named Rules
**The Tonal Bands Rule.** Separate sections by background step, not by borders or shadows.

## Shapes

Pills (999px) for buttons and chips; large soft rows (1.25rem) for practice lines and cards; 28px for the oldest panel; 6px for subtitle chips (deliberately like a caption box) and 4px for highlight marks. Rows in lists are separated by 2px translucent rules rather than boxed.

## Components

### Buttons
- **Primary (sun pill):** yellow fill, Sun Ink text, weight 800, 1.1rem, min-height 48px, soft shadow. Hover lifts 2px, active presses 2px, 0.2s ease-out (cubic-bezier 0.22, 1, 0.36, 1). One per view.
- **Focus:** 3px yellow ring, 3px offset on stage; 3px violet ring on paper.

### Practice Lines (signature)
Full-width buttons on Pit Violet, display type, words lit yellow. Tap or Enter replays the word-by-word light-up (0.26s stagger per word, 0.42s ease-out colour and a small rise) and announces "Playing: ..." in a polite live region. Hover nudges 0.4rem right.

### Caption Bar
A pit-violet band with a centred chip: white bold text on 55% black, 6px radius, like a subtitle.

### Speech Bubble and Mascot
Coral rounded bubble with three pulsing white dots near the mascot; the mascot bobs 0.6rem on a 3.2s loop. Both stop under reduced motion.

### Transcript Card
White card on paper: the learner's phrase struck through in red, the corrected phrase with changed words in yellow `mark` highlights (Sun Ink text, 4px radius).

### Navigation
Header on Pit Violet, white rounded wordmark with logo mark, nav links in Stage White, current page underlined in yellow (3px). Footer is Pit Violet with yellow links.

## Do's and Don'ts

### Do:
- **Do** render every lyric as `.line` with `.w` word spans; lit is the default state and the JS-enhanced unlit state is the exception.
- **Do** keep all words lit and static under `prefers-reduced-motion`.
- **Do** keep scripts and styles first-party and external; no inline script or style.
- **Do** put small print, legal, and pricing prose on paper bands.
- **Do** set one yellow primary action per view.

### Don't:
- **Don't** use yellow for decoration or for body text on paper (it fails contrast there).
- **Don't** put long paragraphs on the violet stage.
- **Don't** add network fonts, analytics, or third-party embeds.
- **Don't** apply this system to the policy pages or the Flutter app without an explicit decision; they use separate palettes.
