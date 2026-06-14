import 'package:flutter/material.dart';

import '../app_localizations.dart';

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  static const _supported = {
    'en',
    'sw',
    'fr',
    'es',
    'pt',
    'ar',
    'so',
    'tn',
    'xh',
    'yo',
    'zu',
    'ha',
    'ig',
    'rw',
    'lg',
    'rn',
    'st',
  };

  @override
  bool isSupported(Locale locale) =>
      _supported.contains(locale.languageCode.toLowerCase());

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final lang = locale.languageCode.toLowerCase();
    return switch (lang) {
      'sw' => AppLocalizationsSw(lang),
      'fr' => AppLocalizationsFR(lang),
      'es' => AppLocalizationsES(lang),
      'pt' => AppLocalizationsPT(lang),
      'ar' => AppLocalizationsAR(lang),
      'so' => AppLocalizationsSO(lang),
      'tn' => AppLocalizationsTN(lang),
      'xh' => AppLocalizationsXH(lang),
      'yo' => AppLocalizationsYO(lang),
      'zu' => AppLocalizationsZU(lang),
      'ha' => AppLocalizationsHA(lang),
      'ig' => AppLocalizationsIG(lang),
      'rw' => AppLocalizationsRW(lang),
      'lg' => AppLocalizationsLG(lang),
      'rn' => AppLocalizationsRN(lang),
      'st' => AppLocalizationsST(lang),
      _ => AppLocalizationsEn(lang),
    };
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
