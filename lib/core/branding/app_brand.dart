/// Brand identity in one place.
///
/// "Hermione" is the owner-decided app name. It has not been cleared as a trademark, domain or
/// store name, and it is not affiliated with any book, film or game franchise. Never hardcode
/// the product name in features: use [AppBrand.name] so a rename touches this file only. The
/// app/bundle ID `com.techfiyr.sprelia` is permanent once published and deliberately unchanged.
abstract final class AppBrand {
  static const name = 'Hermione';
  static const headline = 'Learn English with Hermione';
  static const tagline = 'Learn smarter. Speak with confidence.';
  static const supportingText =
      'Friendly daily conversations with your personal AI English coach, with feedback after every chat.';
}
