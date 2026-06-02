import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/app_error_handler.dart';
import 'core/routes/app_router.dart';
import 'localization/app_localizations.dart';
import 'localization/l10n/app_localizations_delegate.dart';
import 'core/config/theme_mode_provider.dart';
import 'features/auth/presentation/controllers/language_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  installAppErrorHandlers();
  runApp(const ProviderScope(child: RepairAIApp()));
}

class RepairAIApp extends ConsumerWidget {
  const RepairAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLanguage = ref.watch(languageProvider);

    final locale =
        appLanguage == AppLanguage.sw ? const Locale('sw') : const Locale('en');

    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      locale: locale,
      title: 'REPAIR-AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
