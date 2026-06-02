import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/onboarding_provider.dart';
import 'package:repair_ai/core/widgets/loading_error_state.dart';
import 'package:repair_ai/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:repair_ai/features/auth/presentation/screens/login_transition_screen.dart';
import 'package:repair_ai/features/onboarding/presentation/screens/how_it_works_screen.dart';
import 'package:repair_ai/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/triage/presentation/screens/symptom_report_screen.dart';
import '../../features/triage/presentation/screens/ai_analyzing_screen.dart';
import '../../features/triage/presentation/screens/risk_result_screen.dart';
import '../../features/referral/presentation/screens/referral_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/my_reports_screen.dart';
import '../../features/profile/presentation/screens/language_screen.dart';
import '../../features/mental_health/presentation/screens/mental_health.dart';
import '../../features/dashboard/presentation/screens/provider_dashboard.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../shared/widgets/quote_loading_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

bool _isPublicRoute(String path) {
  return path == '/splash' ||
      path == '/onboarding' ||
      path == '/how-it-works' ||
      path == '/login' ||
      path == '/login/transition';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(authSessionProvider);
  final onboardingDone = ref.watch(onboardingCompleteProvider);
  final authReady = ref.watch(authReadyProvider);
  final splashDone = ref.watch(splashMinimumDoneProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final path = state.matchedLocation;

      if ((!authReady || !splashDone) && path != '/splash') {
        return '/splash';
      }

      if (authReady && splashDone && path == '/splash') {
        if (isLoggedIn) return '/';
        if (onboardingDone) return '/login';
        return '/onboarding';
      }

      if (!isLoggedIn && !_isPublicRoute(path)) {
        return '/login';
      }

      if (isLoggedIn && path == '/login') {
        return '/';
      }

      if (isLoggedIn && path == '/onboarding') {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const _AppSplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/how-it-works',
        builder: (context, state) => const HowItWorksScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/login/transition',
        builder: (context, state) => const LoginTransitionScreen(),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/triage/symptom-report',
        builder: (context, state) => const SymptomReportScreen(),
      ),
      GoRoute(
        path: '/triage/analyzing',
        builder: (context, state) => const AiAnalyzingScreen(),
      ),
      GoRoute(
        path: '/triage/risk-result',
        builder: (context, state) => const RiskResultScreen(),
      ),
      GoRoute(
        path: '/referral',
        builder: (context, state) => const ReferralScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/language',
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const MyReportsScreen(),
      ),
      GoRoute(
        path: '/mental-health',
        builder: (context, state) => const MentalHealthScreen(),
      ),
      GoRoute(
        path: '/dashboard/provider',
        builder: (context, state) => const ProviderDashboard(),
      ),
    ],
    errorBuilder: (context, state) {
      final l10n = AppLocalizations.of(context);
      return Scaffold(
        appBar: AppBar(title: Text(l10n.routeError)),
        body: ErrorState(
          message: '${l10n.routeNotFound}\n${state.uri}',
          retryText: l10n.retry,
          onRetry: () => context.go('/'),
        ),
      );
    },
  );
});

class _AppSplashScreen extends ConsumerStatefulWidget {
  const _AppSplashScreen();

  @override
  ConsumerState<_AppSplashScreen> createState() => _AppSplashScreenState();
}

class _AppSplashScreenState extends ConsumerState<_AppSplashScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final authReady = ref.watch(authReadyProvider);

    return QuoteLoadingScreen(
      subtitle: l10n.appTitle,
      onFinished: () {
        if (authReady) {
          ref.read(splashMinimumDoneProvider.notifier).state = true;
        }
      },
      runTask: () async {
        while (!ref.read(authReadyProvider)) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      },
    );
  }
}
