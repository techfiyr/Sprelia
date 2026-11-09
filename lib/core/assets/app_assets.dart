/// Central asset registry (`doc/ASSET_LIBRARY.md`).
///
/// Rules:
/// - Every file under `assets/` has exactly one entry here, and every entry is in
///   the inventory in `doc/ASSET_LIBRARY.md`. `test/core/assets/asset_library_test.dart`
///   enforces both directions, plus naming, formats, sizes and pubspec registration.
/// - Features never use `'assets/...'` string literals; they use these constants.
/// - Only entries with [AssetStatus.available] **and** `bundled: true` may be loaded.
///   Check [AssetEntry.isUsable] and fall back to the coded placeholder otherwise.
/// - Never add invented final branding. Final brand assets need brand clearance and
///   owner approval (BRAND.md §5, §6, §14).
library;

enum AssetStatus {
  /// Approved file is in the repo and licensed for use.
  available,

  /// Required by the specs but not produced yet. The file must NOT exist.
  planned,

  /// Temporary stand-in. Either rendered in code (no file) or a file that is not
  /// approved, e.g. unknown provenance or licence. Never bundled as final branding.
  placeholder,
}

class AssetEntry {
  const AssetEntry({
    required this.path,
    required this.status,
    required this.purpose,
    required this.license,
    this.bundled = false,
  });

  /// Path relative to the project root, e.g. `assets/tutors/emma/emma_avatar.webp`.
  final String path;
  final AssetStatus status;
  final String purpose;

  /// Licence or source, e.g. "SIL OFL 1.1 (Inter project)" or "TBD: commissioned".
  final String license;

  /// Registered in pubspec.yaml and shipped inside the app bundle.
  final bool bundled;

  bool get isUsable => status == AssetStatus.available && bundled;

  String get format => path.split('.').last;
}

abstract final class AppAssets {
  // ---------------------------------------------------------------- Fonts ----
  static const _ofl = 'SIL Open Font License 1.1, (c) The Inter Project Authors (rsms/inter v4.1)';

  static const interRegular = AssetEntry(
    path: 'assets/fonts/inter/inter_regular.ttf',
    status: AssetStatus.available,
    purpose: 'Inter 400: body text',
    license: _ofl,
    bundled: true,
  );
  static const interMedium = AssetEntry(
    path: 'assets/fonts/inter/inter_medium.ttf',
    status: AssetStatus.available,
    purpose: 'Inter 500: labels',
    license: _ofl,
    bundled: true,
  );
  static const interSemiBold = AssetEntry(
    path: 'assets/fonts/inter/inter_semibold.ttf',
    status: AssetStatus.available,
    purpose: 'Inter 600: headings, buttons',
    license: _ofl,
    bundled: true,
  );
  static const interBold = AssetEntry(
    path: 'assets/fonts/inter/inter_bold.ttf',
    status: AssetStatus.available,
    purpose: 'Inter 700: emphasis',
    license: _ofl,
    bundled: true,
  );
  static const interLicense = AssetEntry(
    path: 'assets/fonts/inter/license_ofl.txt',
    status: AssetStatus.available,
    purpose: 'Inter licence text, shown on the in-app licences page',
    license: _ofl,
    bundled: true,
  );

  // ------------------------------------------------------------- Branding ----
  static const _brandTbd = 'TBD: original work for Sprelia; requires brand clearance';

  static const logoHorizontal = AssetEntry(
    path: 'assets/branding/logo/sprelia_logo_horizontal.svg',
    status: AssetStatus.planned,
    purpose: 'Primary logo: symbol + wordmark (BRAND §5)',
    license: _brandTbd,
  );
  static const logoMark = AssetEntry(
    path: 'assets/branding/logo/sprelia_logo_mark.svg',
    status: AssetStatus.planned,
    purpose: 'Symbol-only logo (welcome, splash)',
    license: _brandTbd,
  );
  static const logoMonoDark = AssetEntry(
    path: 'assets/branding/logo/sprelia_logo_mono_dark.svg',
    status: AssetStatus.planned,
    purpose: 'Monochrome dark logo',
    license: _brandTbd,
  );
  static const logoMonoWhite = AssetEntry(
    path: 'assets/branding/logo/sprelia_logo_mono_white.svg',
    status: AssetStatus.planned,
    purpose: 'Monochrome white logo (dark backgrounds)',
    license: _brandTbd,
  );
  static const appIconMaster = AssetEntry(
    path: 'assets/branding/icons/app_icon_master_1024.png',
    status: AssetStatus.planned,
    purpose: 'App icon master 1024×1024 (source for Android/iOS icons; not bundled)',
    license: _brandTbd,
  );
  static const appIconForeground = AssetEntry(
    path: 'assets/branding/icons/app_icon_adaptive_foreground.png',
    status: AssetStatus.planned,
    purpose: 'Android adaptive icon foreground 432×432 (source; not bundled)',
    license: _brandTbd,
  );
  static const appIconMonochrome = AssetEntry(
    path: 'assets/branding/icons/app_icon_monochrome.png',
    status: AssetStatus.planned,
    purpose: 'Android 13+ themed (monochrome) icon (source; not bundled)',
    license: _brandTbd,
  );
  static const playFeatureGraphic = AssetEntry(
    path: 'assets/branding/marketing/play_feature_graphic_1024x500.png',
    status: AssetStatus.planned,
    purpose: 'Google Play feature graphic (store listing only; not bundled)',
    license: _brandTbd,
  );

  /// Coded placeholder: `BrandLogo` (lib/core/branding/brand_logo.dart) draws a
  /// stock Material icon in a purple tile. No file exists.
  static const logoPlaceholder = AssetEntry(
    path: 'code:lib/core/branding/brand_logo.dart',
    status: AssetStatus.placeholder,
    purpose: 'Stand-in for the logo until logoMark/logoHorizontal are approved',
    license: 'Material Icons (Apache 2.0, via Flutter)',
  );

  // --------------------------------------------------------------- Tutors ----
  // Final avatars: one consistent illustration style (BRAND §6), 512×512 WebP,
  // subject centred inside a circular safe area, transparent or brand-lavender background.
  static const _tutorTbd = 'TBD: commissioned or licensed; consistent style required (BRAND §6)';

  static const tutorEmma = AssetEntry(
    path: 'assets/tutors/emma/emma_avatar.webp',
    status: AssetStatus.planned,
    purpose: 'Emma avatar (tutor cards, preparation, conversation)',
    license: _tutorTbd,
  );
  static const tutorAlex = AssetEntry(
    path: 'assets/tutors/alex/alex_avatar.webp',
    status: AssetStatus.planned,
    purpose: 'Alex avatar',
    license: _tutorTbd,
  );
  static const tutorSofia = AssetEntry(
    path: 'assets/tutors/sofia/sofia_avatar.webp',
    status: AssetStatus.planned,
    purpose: 'Sofia avatar',
    license: _tutorTbd,
  );

  /// Coded placeholder: `TutorAvatar` draws the tutor's initial on a brand tint.
  static const tutorAvatarPlaceholder = AssetEntry(
    path: 'code:lib/features/tutors/tutor_avatar.dart',
    status: AssetStatus.placeholder,
    purpose: 'Initial-letter avatar used until approved tutor avatars exist',
    license: 'n/a (rendered in code)',
  );

  /// Candidate images found in the repo (added 2026-11-09). Provenance and licence
  /// are UNKNOWN, there is no embedded metadata, and the two images use different
  /// visual styles. NOT bundled and NOT used until the owner confirms the licence
  /// and approves a consistent style.
  static const tutorEmmaCandidate = AssetEntry(
    path: 'assets/tutors/img_tutor_emma.jpeg',
    status: AssetStatus.placeholder,
    purpose: 'Unapproved Emma candidate (3D render, baked rounded-square frame)',
    license: 'UNKNOWN: owner to confirm source and licence',
  );
  static const tutorSofiaCandidate = AssetEntry(
    path: 'assets/tutors/img_tutor_sofia.jpeg',
    status: AssetStatus.placeholder,
    purpose: 'Unapproved "Sofia" candidate (monochrome 3D render; style differs from Emma)',
    license: 'UNKNOWN: owner to confirm source and licence',
  );

  // -------------------------------------------------------- Illustrations ----
  static const welcomeIllustration = AssetEntry(
    path: 'assets/illustrations/welcome_illustration.webp',
    status: AssetStatus.planned,
    purpose: 'Friendly welcome illustration (APP_FLOW §3)',
    license: 'TBD: commissioned or licensed',
  );

  static const onboardingIllustration = AssetEntry(
    path: 'assets/illustrations/onboarding_illustration.webp',
    status: AssetStatus.planned,
    purpose: 'Portrait onboarding illustration (DESIGN_SYSTEM §8, banner variant 2)',
    license: 'TBD: commissioned or licensed',
  );

  // ----------------------------------------------------------- Animations ----
  static const voiceActivity = AssetEntry(
    path: 'assets/animations/voice_activity.json',
    status: AssetStatus.planned,
    purpose: 'Subtle voice activity animation (Lottie) for the conversation screen; must respect reduced motion',
    license: 'TBD: commissioned or licensed',
  );

  /// Every registered asset, for tooling and tests.
  static const all = <AssetEntry>[
    interRegular,
    interMedium,
    interSemiBold,
    interBold,
    interLicense,
    logoHorizontal,
    logoMark,
    logoMonoDark,
    logoMonoWhite,
    appIconMaster,
    appIconForeground,
    appIconMonochrome,
    playFeatureGraphic,
    logoPlaceholder,
    tutorEmma,
    tutorAlex,
    tutorSofia,
    tutorAvatarPlaceholder,
    tutorEmmaCandidate,
    tutorSofiaCandidate,
    welcomeIllustration,
    onboardingIllustration,
    voiceActivity,
  ];

  /// Approved avatar for a tutor id, or null (use the coded placeholder).
  static AssetEntry? tutorAvatar(String tutorId) {
    final entry = switch (tutorId) {
      'emma' => tutorEmma,
      'alex' => tutorAlex,
      'sofia' => tutorSofia,
      _ => null,
    };
    return entry != null && entry.isUsable ? entry : null;
  }
}
