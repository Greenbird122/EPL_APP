import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/network/update_check_provider.dart';
import 'package:repair_ai/core/utils/app_error_handler.dart';
import 'core/routes/app_router.dart';
import 'localization/app_localizations.dart';
import 'localization/l10n/app_localizations_delegate.dart';
import 'core/config/theme_mode_provider.dart';
import 'features/auth/presentation/controllers/language_providers.dart';
import 'shared/widgets/backend_connection_listener.dart';
import 'shared/widgets/video_splash_screen.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    installAppErrorHandlers();

    // Check if video splash should show BEFORE launching the app.
    shouldShowVideoSplash().then((show) {
      if (show) {
        runApp(const ProviderScope(child: _VideoSplashWrapper()));
      } else {
        runApp(const ProviderScope(child: RepairAIApp()));
      }
    });
  }, (error, stack) {
    if (kDebugMode) {
      debugPrint('Zone error: $error\n$stack');
    }
  });
}

/// Wraps the video splash so it plays first, then launches the real app.
class _VideoSplashWrapper extends StatelessWidget {
  const _VideoSplashWrapper();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: VideoSplashScreen(
        onGetStarted: () {
          // Replace the entire widget tree with the real app.
          runApp(const ProviderScope(child: RepairAIApp()));
        },
      ),
    );
  }
}

class RepairAIApp extends ConsumerWidget {
  const RepairAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLanguage = ref.watch(languageProvider);
    final locale = Locale(appLanguage.localeCode);
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
      builder: (context, child) {
        // Schedule update check after first frame.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(updateCheckProvider.notifier).checkForUpdate();
        });

        return Stack(
          children: [
            if (child != null) child,
            const BackendConnectionListener(),
            const BackendConnectionBar(),
            const _UpdateListener(),
          ],
        );
      },
    );
  }
}

/// Listens for update availability and shows a dialog.
/// Must be a ConsumerWidget because ref.listen requires the build context.
class _UpdateListener extends ConsumerWidget {
  const _UpdateListener();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<UpdateState>(updateCheckProvider, (prev, next) {
      if (next.status == UpdateStatus.updateAvailable) {
        _showDialog(context, ref, next);
      }
    });
    return const SizedBox.shrink();
  }

  void _showDialog(BuildContext context, WidgetRef ref, UpdateState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Available'),
        content: Text(
          'Version ${state.latestVersion ?? ''} is available. '
          'Please update to get the latest features and fixes.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(updateCheckProvider.notifier).dismissLater();
              Navigator.of(ctx).pop();
            },
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(updateCheckProvider.notifier).dismissUpdate();
              Navigator.of(ctx).pop();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
