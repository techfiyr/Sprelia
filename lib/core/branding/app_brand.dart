/// Brand identity in one place (`doc/BRAND.md` §1).
///
/// "Sprelia" is PROVISIONAL (no trademark, domain or store-name clearance).
/// Never hardcode the product name in features: use [AppBrand.name] so a
/// rename touches this file only. Also renamed on a brand change: AndroidManifest
/// `android:label`, iOS `CFBundleDisplayName`/`CFBundleName`, and the app/bundle
/// ID `com.techfiyr.sprelia` (the ID is permanent once published). See BRAND.md §13.
abstract final class AppBrand {
  static const name = 'Sprelia';
  static const tagline = 'Find your voice. Speak with confidence.';
  static const supportingText =
      'Build confidence through daily conversations with your personal AI English coach.';
}
