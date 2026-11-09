import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

extension L10nContext on BuildContext {
  /// Localized strings (`lib/l10n/app_*.arb`). English is the only shipped
  /// locale for now; add an ARB file per language to localize the app.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
