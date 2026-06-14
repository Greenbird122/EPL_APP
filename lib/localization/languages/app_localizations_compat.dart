import 'app_localizations.dart';

/// Helper mixin to provide missing localization getters.
///
/// This repo contains many generated locale files. When the base
/// [AppLocalizations] API changes, all locale classes must implement the new
/// getters. During patching we keep the app compiling by offering defaults.
mixin AppLocalizationsCompat on AppLocalizations {
  @override
  String get localSafetyFallback =>
      // Generic English fallback string.
      'Local safety guidance is available.';

  @override
  String get useLocalSafetyScreening =>
      // Generic English fallback string.
      'Use local safety screening';
}

