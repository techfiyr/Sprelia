# Sprelia Asset Library

**Status date:** 2026-11-09 (verified at Phase 2 close-out) · **Owner:** product/brand owner (approvals), engineering (registry)

> Location note: the guidelines name `docs/ASSET_LIBRARY.md`. This repository keeps all
> specifications in `doc/`, so the library lives at `doc/ASSET_LIBRARY.md`.

This document is the inventory and rulebook for every image, SVG, Lottie, font and
branding asset. It is enforced by `test/core/assets/asset_library_test.dart`. That test
fails if this file, `lib/core/assets/app_assets.dart`, `pubspec.yaml` and the files under
`assets/` disagree.

> No final branding exists yet. Sprelia is a provisional name (BRAND.md §1). Logo, app
> icon, tutor avatars and illustrations are **planned**, and the app shows clearly
> labelled **placeholders**. Never add invented final branding.

## 1. Rules

1. All assets live under `assets/`, grouped by purpose (§2).
2. No large images or base64 data in Dart code (enforced).
3. Code references assets only through `AppAssets` constants (e.g. `AppAssets.logoMark`,
   `AppAssets.tutorEmma`), never `'assets/...'` literals (enforced).
4. Only **available** and **licensed** assets are registered in `pubspec.yaml` and bundled
   (enforced). Register specific files or asset folders, never `assets/` as a whole, so
   README, attribution and unapproved files are not shipped.
5. Formats: **SVG** for logos and vector artwork; **WebP** for photos and illustrations;
   **PNG** where transparency or exact pixels matter (icon sources); **Lottie JSON** for
   animations; **TTF/OTF** for fonts. Bundled assets are never JPEG (enforced).
   Size budgets (enforced): WebP ≤ 300 KB, PNG ≤ 500 KB, SVG ≤ 100 KB, Lottie ≤ 300 KB,
   font ≤ 600 KB. Export rasters at the largest displayed size × 3 at most, or provide
   `2.0x/` and `3.0x/` variants.
6. Names: lowercase `snake_case` files and folders, `<subject>_<variant>.<ext>` (enforced),
   e.g. `emma_avatar.webp`, `sprelia_logo_mark.svg`.
7. Every asset has a licence or source recorded here and in `AppAssets`. Third-party
   licence texts are stored next to the asset and listed in `assets/ATTRIBUTION.md`.
   Bundled licences that require it are shown on the in-app licences page
   (`registerAssetLicenses()` in `lib/main.dart`).
8. Never use copyrighted illustrations, fonts or icons without a licence that allows app
   distribution. Assets of unknown origin are **placeholder (candidate)** and are not bundled.
9. No duplicates: one file, one registry entry, shared by all features (content hash is enforced).
10. Placeholders are allowed only while the final asset is unavailable. Each one is listed in §3.
11. Tutor avatars come from one illustration style and one spec (§4). They are rendered only
    by `TutorAvatar`, which crops every avatar identically.
12. Keep this document current. Changing an asset means updating `AppAssets`, this inventory,
    `pubspec.yaml` (if bundled) and `assets/ATTRIBUTION.md` (if third-party).

## 2. Folder structure

```text
assets/
  README.md                 (not bundled) folder guide
  ATTRIBUTION.md            (not bundled) third-party licences
  fonts/inter/              Inter TTFs + licence_ofl text
  branding/
    logo/                   SVG logo variants
    icons/                  app icon SOURCE files (platform icons are generated into android/ and ios/)
    marketing/              store/marketing graphics (never bundled)
  tutors/<tutor_id>/        approved tutor avatars, e.g. tutors/emma/emma_avatar.webp
  illustrations/            screen illustrations (WebP/SVG)
  animations/               Lottie JSON
```

## 3. Inventory

Status: **available** = approved, licensed, in the repo · **planned** = required, not
produced yet · **placeholder** = temporary stand-in (coded, or an unapproved file).

### Fonts

| Asset | File path | Format | Purpose | Status | Licence / source |
|---|---|---|---|---|---|
| `AppAssets.interRegular` | `assets/fonts/inter/inter_regular.ttf` | TTF | Inter 400, body | available, bundled | SIL OFL 1.1, rsms/inter v4.1 |
| `AppAssets.interMedium` | `assets/fonts/inter/inter_medium.ttf` | TTF | Inter 500, labels | available, bundled | SIL OFL 1.1, rsms/inter v4.1 |
| `AppAssets.interSemiBold` | `assets/fonts/inter/inter_semibold.ttf` | TTF | Inter 600, headings and buttons | available, bundled | SIL OFL 1.1, rsms/inter v4.1 |
| `AppAssets.interBold` | `assets/fonts/inter/inter_bold.ttf` | TTF | Inter 700, emphasis | available, bundled | SIL OFL 1.1, rsms/inter v4.1 |
| `AppAssets.interLicense` | `assets/fonts/inter/license_ofl.txt` | TXT | Licence text for the in-app licences page | available, bundled | SIL OFL 1.1 |

### Branding

| Asset | File path | Format | Purpose | Status | Licence / source |
|---|---|---|---|---|---|
| `AppAssets.logoHorizontal` | `assets/branding/logo/sprelia_logo_horizontal.svg` | SVG | Symbol + wordmark (BRAND §5) | planned | Original; needs brand clearance |
| `AppAssets.logoMark` | `assets/branding/logo/sprelia_logo_mark.svg` | SVG | Symbol only (welcome, splash) | planned | Original; needs brand clearance |
| `AppAssets.logoMonoDark` | `assets/branding/logo/sprelia_logo_mono_dark.svg` | SVG | Monochrome dark | planned | Original; needs brand clearance |
| `AppAssets.logoMonoWhite` | `assets/branding/logo/sprelia_logo_mono_white.svg` | SVG | Monochrome white | planned | Original; needs brand clearance |
| `AppAssets.appIconMaster` | `assets/branding/icons/app_icon_master_1024.png` | PNG | App icon master 1024×1024 (source, not bundled) | planned | Original; needs brand clearance |
| `AppAssets.appIconForeground` | `assets/branding/icons/app_icon_adaptive_foreground.png` | PNG | Android adaptive foreground 432×432, 66% safe zone (source) | planned | Original; needs brand clearance |
| `AppAssets.appIconMonochrome` | `assets/branding/icons/app_icon_monochrome.png` | PNG | Android 13+ themed icon (source) | planned | Original; needs brand clearance |
| `AppAssets.playFeatureGraphic` | `assets/branding/marketing/play_feature_graphic_1024x500.png` | PNG | Play Store feature graphic (never bundled) | planned | Original; needs brand clearance |
| `AppAssets.logoPlaceholder` | `lib/core/branding/brand_logo.dart` | code | Purple tile with a stock "graphic_eq" icon, labelled "logo (placeholder)" | placeholder | Material Icons, Apache 2.0 (via Flutter) |

Platform outputs (not under `assets/`): Android `mipmap-*` launcher icons and iOS
`AppIcon.appiconset` are still the **Flutter defaults**. Splash screens are the default
white launch theme. Both are regenerated from the icon sources once approved.

### Tutors

| Asset | File path | Format | Purpose | Status | Licence / source |
|---|---|---|---|---|---|
| `AppAssets.tutorEmma` | `assets/tutors/emma/emma_avatar.webp` | WebP | Emma avatar | planned | TBD; consistent style required |
| `AppAssets.tutorAlex` | `assets/tutors/alex/alex_avatar.webp` | WebP | Alex avatar | planned | TBD; consistent style required |
| `AppAssets.tutorSofia` | `assets/tutors/sofia/sofia_avatar.webp` | WebP | Sofia avatar | planned | TBD; consistent style required |
| `AppAssets.tutorAvatarPlaceholder` | `lib/features/tutors/tutor_avatar.dart` | code | Initial letter on a brand tint, labelled "(placeholder)" | placeholder | Rendered in code |
| `AppAssets.tutorEmmaCandidate` | `assets/tutors/img_tutor_emma.jpeg` | JPEG 1024², 54 KB | Unapproved Emma candidate | placeholder (candidate, **not bundled**) | **UNKNOWN**: owner to confirm |
| `AppAssets.tutorSofiaCandidate` | `assets/tutors/img_tutor_sofia.jpeg` | JPEG 1024², 62 KB | Unapproved "Sofia" candidate | placeholder (candidate, **not bundled**) | **UNKNOWN**: owner to confirm |

**Review of the two candidates (added to the repo on 2026-11-09):**
- No embedded metadata (author, tool, copyright), so the source and licence are unknown.
  They must not ship until the owner confirms commercial-use rights (rule 8).
- Inconsistent styles (rule 11, BRAND §6). Emma is a glossy 3D render with a rounded-square
  frame and gradient background baked in. "Sofia" is a monochrome purple 3D render on grey.
- Emma's baked-in frame and background conflict with the circular crop used everywhere.
  Final avatars need a clean subject on a transparent or flat lavender background.
- The "Sofia" image (blazer, headset) reads as the professional coach (Alex) rather than
  BRAND's relaxed everyday partner. The owner should confirm the intent.
- Both images were included in commit `7643ba5` (branch `phase-1-foundation`, pushed).
  If the licence turns out to be unsuitable, removing them from git history needs owner
  approval (it rewrites history).

### Illustrations and animations

| Asset | File path | Format | Purpose | Status | Licence / source |
|---|---|---|---|---|---|
| `AppAssets.welcomeIllustration` | `assets/illustrations/welcome_illustration.webp` | WebP | Friendly welcome illustration (APP_FLOW §3) | planned | TBD |
| `AppAssets.onboardingIllustration` | `assets/illustrations/onboarding_illustration.webp` | WebP | Portrait onboarding illustration (DESIGN_SYSTEM §8) | planned | TBD |
| `AppAssets.voiceActivity` | `assets/animations/voice_activity.json` | Lottie | Subtle voice activity indicator (conversation screen); respects reduced motion | planned | TBD |

### Missing illustrations by screen (Phase 2 close-out)

Screens that the specs say should carry illustrations or brand art, and what they show today:

| Screen | Spec | Shows today | Registry entry |
|---|---|---|---|
| Splash | DESIGN_SYSTEM §10: centred logo | `BrandLogo` placeholder | `logoMark` (planned) |
| Welcome | APP_FLOW §3: "friendly illustration" | Placeholder logo + text only | `welcomeIllustration` (planned) |
| Onboarding | DESIGN_SYSTEM §8: portrait onboarding illustration | None (text + selection cards) | `onboardingIllustration` (planned) |
| Learning plan | n/a | Material celebration icon | none needed |
| Tutor cards, preparation, conversation | BRAND §6: tutor portraits | Initial-letter placeholder | `tutorEmma` / `tutorAlex` / `tutorSofia` (planned) |
| Empty and error states | DESIGN_SYSTEM §9 lists illustration subjects, but no per-screen requirement | Material icons | **Open decision:** whether to commission empty-state art |
| Launcher icon / native splash | BRAND §5, DESIGN_SYSTEM §7 | Flutter defaults | `appIcon*` sources (planned) |

## 4. Specifications for planned assets

**Logo (BRAND §5):** speech bubble + voice wave + friendly shape. Approved purple palette
only, no gradients inside the symbol, legible at 24×24 px, with clear space equal to the
symbol's bubble height. Deliver optimized SVG (no embedded rasters or fonts; text outlined)
for each variant in §3. To render SVGs, add the `flutter_svg` package in the same change
that adds the first SVG.

**App icon:** symbol only (no wordmark or small text), purple-led background, 1024×1024
master. Android adaptive foreground and background with a 66% safe zone, plus a monochrome
layer. iOS has no transparency. Generate the platform icons from the sources and do not
hand-edit `mipmap-*`.

**Tutor avatars (BRAND §6, rule 11):**
- One illustrator or pipeline and one style for all three tutors: polished 3D-inspired or
  illustrative, soft lighting, natural expressions, consistent proportions, purple brand accents.
- 512×512 WebP (≤ 300 KB) per tutor, head-and-shoulders, face centred inside the inner 80%
  circle, transparent or flat `#F1EBFF` background, no baked-in frame or rounded corners.
- Optional large portrait (`<id>_portrait.webp`, 1024×1024) for preparation and conversation screens.
- Inclusive, respectful representation; Emma, Alex and Sofia must be distinguishable at 48 px.
- Licence must allow commercial distribution in apps and stores. If AI tools are used,
  record the tool and its terms, and confirm that commercial-use and likeness rights are clear.

**Illustrations:** same illustration language as the avatars; WebP; light backgrounds.
**Animations:** Lottie ≤ 300 KB, ≤ 60 fps, no flashing, and a static fallback when reduced
motion is on. Add the `lottie` package together with the first animation.

## 5. Adding or replacing an asset (checklist)

1. Confirm the licence or source and record it. Final branding also needs owner approval.
2. Export in the right format, size and name (rules 5–6). Place it in the right folder.
3. Update the `AppAssets` entry: path, `status: available`, licence, and `bundled: true` if shipped.
4. Register it in `pubspec.yaml` (bundled assets only).
5. Third-party: add the licence text next to the asset, list it in `assets/ATTRIBUTION.md`,
   and register it in `registerAssetLicenses()` if the licence requires display.
6. Update this inventory. Run `flutter test test/core/assets/`.
7. Remove the placeholder or candidate it replaces (with owner approval for candidate files).
