import 'dart:ui';

import '../../l10n/app_localizations.dart';

/// A language option with its English and native (endonym) names.
class LanguageOption {
  const LanguageOption(this.code, this.englishName, this.nativeName);

  /// ISO 639 code, optionally with region (`pt-BR`). Validated by the backend.
  final String code;
  final String englishName;
  final String nativeName;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    return q.isEmpty || englishName.toLowerCase().contains(q) || nativeName.toLowerCase().contains(q) || code == q;
  }
}

/// App interface languages = locales with ARB translations.
List<LanguageOption> interfaceLanguages() => [
      for (final locale in AppLocalizations.supportedLocales)
        nativeLanguages.firstWhere(
          (l) => l.code == locale.languageCode,
          orElse: () => LanguageOption(locale.languageCode, locale.languageCode, locale.languageCode),
        ),
    ];

bool isSupportedInterfaceLanguage(String? code) =>
    code != null && AppLocalizations.supportedLocales.any((l) => l.languageCode == code);

Locale? localeFor(String? code) => isSupportedInterfaceLanguage(code) ? Locale(code!) : null;

/// First languages offered in onboarding (global audience, APP_DEVELOPMENT §2).
const nativeLanguages = <LanguageOption>[
  LanguageOption('ar', 'Arabic', 'العربية'),
  LanguageOption('bn', 'Bengali', 'বাংলা'),
  LanguageOption('zh', 'Chinese', '中文'),
  LanguageOption('nl', 'Dutch', 'Nederlands'),
  LanguageOption('en', 'English', 'English'),
  LanguageOption('fil', 'Filipino', 'Filipino'),
  LanguageOption('fr', 'French', 'Français'),
  LanguageOption('de', 'German', 'Deutsch'),
  LanguageOption('el', 'Greek', 'Ελληνικά'),
  LanguageOption('gu', 'Gujarati', 'ગુજરાતી'),
  LanguageOption('he', 'Hebrew', 'עברית'),
  LanguageOption('hi', 'Hindi', 'हिन्दी'),
  LanguageOption('hu', 'Hungarian', 'Magyar'),
  LanguageOption('id', 'Indonesian', 'Bahasa Indonesia'),
  LanguageOption('it', 'Italian', 'Italiano'),
  LanguageOption('ja', 'Japanese', '日本語'),
  LanguageOption('kn', 'Kannada', 'ಕನ್ನಡ'),
  LanguageOption('ko', 'Korean', '한국어'),
  LanguageOption('ms', 'Malay', 'Bahasa Melayu'),
  LanguageOption('ml', 'Malayalam', 'മലയാളം'),
  LanguageOption('mr', 'Marathi', 'मराठी'),
  LanguageOption('ne', 'Nepali', 'नेपाली'),
  LanguageOption('fa', 'Persian', 'فارسی'),
  LanguageOption('pl', 'Polish', 'Polski'),
  LanguageOption('pt-BR', 'Portuguese (Brazil)', 'Português (Brasil)'),
  LanguageOption('pt', 'Portuguese', 'Português'),
  LanguageOption('pa', 'Punjabi', 'ਪੰਜਾਬੀ'),
  LanguageOption('ro', 'Romanian', 'Română'),
  LanguageOption('ru', 'Russian', 'Русский'),
  LanguageOption('si', 'Sinhala', 'සිංහල'),
  LanguageOption('es', 'Spanish', 'Español'),
  LanguageOption('sw', 'Swahili', 'Kiswahili'),
  LanguageOption('ta', 'Tamil', 'தமிழ்'),
  LanguageOption('te', 'Telugu', 'తెలుగు'),
  LanguageOption('th', 'Thai', 'ไทย'),
  LanguageOption('tr', 'Turkish', 'Türkçe'),
  LanguageOption('uk', 'Ukrainian', 'Українська'),
  LanguageOption('ur', 'Urdu', 'اردو'),
  LanguageOption('uz', 'Uzbek', 'Oʻzbekcha'),
  LanguageOption('vi', 'Vietnamese', 'Tiếng Việt'),
];
