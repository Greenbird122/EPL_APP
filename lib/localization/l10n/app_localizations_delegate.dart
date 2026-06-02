import 'package:flutter/material.dart';

import '../app_localizations.dart';

/// Minimal delegate to wire the app's custom [AppLocalizations] wrapper.
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode.toLowerCase() == 'en' ||
      locale.languageCode.toLowerCase() == 'sw';

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final lang = locale.languageCode.toLowerCase();
    if (lang == 'sw') return AppLocalizationsSw(locale.languageCode);
    return AppLocalizationsEn(locale.languageCode);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
