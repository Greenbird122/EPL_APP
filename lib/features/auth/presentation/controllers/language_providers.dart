import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  en,
  sw,
}

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.en) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('app_language');
    state = switch (code) {
      'sw' => AppLanguage.sw,
      _ => AppLanguage.en,
    };
  }

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', language.storageCode);
  }
}

extension AppLanguageMeta on AppLanguage {
  String get storageCode {
    return switch (this) {
      AppLanguage.en => 'en',
      AppLanguage.sw => 'sw',
    };
  }

  String get localeCode {
    return switch (this) {
      AppLanguage.en => 'en',
      AppLanguage.sw => 'sw',
    };
  }

  String get shortLabel {
    return switch (this) {
      AppLanguage.en => 'EN',
      AppLanguage.sw => 'SW',
    };
  }

  String get displayName {
    return switch (this) {
      AppLanguage.en => 'English',
      AppLanguage.sw => 'Kiswahili',
    };
  }
}

final languageProvider =
    StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  return LanguageNotifier();
});
