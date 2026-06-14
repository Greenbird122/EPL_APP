import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  en,
  sw,
  fr,
  es,
  pt,
  ar,
  so,
  tn,
  xh,
  yo,
  zu,
  ha,
  ig,
  rw,
  lg,
  rn,
  st
}

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.en) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('app_language');
    state = AppLanguage.values.firstWhere(
      (l) => l.localeCode == code,
      orElse: () => AppLanguage.en,
    );
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', language.localeCode);
  }
}

extension AppLanguageMeta on AppLanguage {
  String get localeCode {
    return switch (this) {
      AppLanguage.en => 'en',
      AppLanguage.sw => 'sw',
      AppLanguage.fr => 'fr',
      AppLanguage.es => 'es',
      AppLanguage.pt => 'pt',
      AppLanguage.ar => 'ar',
      AppLanguage.so => 'so',
      AppLanguage.tn => 'tn',
      AppLanguage.xh => 'xh',
      AppLanguage.yo => 'yo',
      AppLanguage.zu => 'zu',
      AppLanguage.ha => 'ha',
      AppLanguage.ig => 'ig',
      AppLanguage.rw => 'rw',
      AppLanguage.lg => 'lg',
      AppLanguage.rn => 'rn',
      AppLanguage.st => 'st',
    };
  }

  String get displayName {
    return switch (this) {
      AppLanguage.en => 'English',
      AppLanguage.sw => 'Kiswahili',
      AppLanguage.fr => 'Francais',
      AppLanguage.es => 'Espanol',
      AppLanguage.pt => 'Portugues',
      AppLanguage.ar => 'العربية (Arabic)',
      AppLanguage.so => 'Soomaali (Somali)',
      AppLanguage.tn => 'Setswana (Tswana)',
      AppLanguage.xh => 'isiXhosa (Xhosa)',
      AppLanguage.yo => 'Yoruba',
      AppLanguage.zu => 'isiZulu (Zulu)',
      AppLanguage.ha => 'Hausa',
      AppLanguage.ig => 'Igbo',
      AppLanguage.rw => 'Kinyarwanda',
      AppLanguage.lg => 'Luganda',
      AppLanguage.rn => 'Kirundi (Rundi)',
      AppLanguage.st => 'Sesotho',
    };
  }

  String get shortLabel {
    return switch (this) {
      AppLanguage.en => 'EN',
      AppLanguage.sw => 'SW',
      AppLanguage.fr => 'FR',
      AppLanguage.es => 'ES',
      AppLanguage.pt => 'PT',
      AppLanguage.ar => 'AR',
      AppLanguage.so => 'SO',
      AppLanguage.tn => 'TN',
      AppLanguage.xh => 'XH',
      AppLanguage.yo => 'YO',
      AppLanguage.zu => 'ZU',
      AppLanguage.ha => 'HA',
      AppLanguage.ig => 'IG',
      AppLanguage.rw => 'RW',
      AppLanguage.lg => 'LG',
      AppLanguage.rn => 'RN',
      AppLanguage.st => 'ST',
    };
  }
}

final languageProvider =
    StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  return LanguageNotifier();
});
