import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/onboarding_provider.dart';
import 'package:repair_ai/core/widgets/loading_error_state.dart';
import 'package:repair_ai/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:repair_ai/features/auth/presentation/controllers/login_profile_providers.dart';
import 'package:repair_ai/features/anc/domain/anc_profile.dart';
import 'package:repair_ai/features/anc/presentation/screens/anc_profile_screen.dart';
import 'package:repair_ai/features/auth/presentation/screens/auth_entry_screen.dart';
import 'package:repair_ai/features/auth/presentation/screens/change_password_screen.dart';
import 'package:repair_ai/features/auth/presentation/screens/chp_sign_in_screen.dart';
import 'package:repair_ai/features/auth/presentation/screens/create_account_screen.dart';
import 'package:repair_ai/features/auth/presentation/screens/recover_account_screen.dart';
import 'package:repair_ai/features/auth/presentation/screens/otp_screen.dart';
import 'package:repair_ai/features/care/presentation/screens/care_screen.dart';
import 'package:repair_ai/features/medication_tracking/presentation/screens/medication_tracking_screen.dart';
import 'package:repair_ai/features/profile/presentation/screens/complete_care_profile_screen.dart';
import 'package:repair_ai/features/auth/presentation/screens/login_transition_screen.dart';
import 'package:repair_ai/features/onboarding/presentation/screens/how_it_works_screen.dart';
import 'package:repair_ai/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/triage/presentation/screens/symptom_report_screen.dart';
import '../../features/triage/presentation/screens/ai_analyzing_screen.dart';
import '../../features/triage/presentation/screens/risk_result_screen.dart';
import '../../features/triage/presentation/screens/symptom_check_screen.dart';
import '../../features/referral/presentation/screens/referral_screen.dart';
import '../../features/care/presentation/screens/case_chat_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/my_reports_screen.dart';
import '../../features/profile/presentation/screens/language_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/profile/presentation/screens/notifications_screen.dart';
import '../../features/profile/presentation/screens/payments_screen.dart';
import '../../features/mental_health/presentation/screens/mental_health.dart';
import '../../features/dashboard/presentation/screens/provider_dashboard.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../shared/widgets/quote_loading_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

bool isPublicRoute(String path) {
  return path == '/splash' ||
      path == '/onboarding' ||
      path == '/how-it-works' ||
      path == '/login' ||
      path == '/auth' ||
      path == '/auth/sign-in' ||
      path == '/auth/chp' ||
      path == '/auth/create-account' ||
      path == '/auth/recover' ||
      path == '/auth/otp' ||
      path == '/login/transition';
}

bool isProviderRoute(String path) {
  return path == '/dashboard/provider' ||
      path == '/dashboard/provider/anc-profile';
}

bool isPatientRoute(String path) {
  return path == '/' ||
      path == '/symptom-check' ||
      path == '/triage/symptom-report' ||
      path == '/triage/analyzing' ||
      path == '/triage/risk-result' ||
      path == '/care' ||
      path == '/care/anc-profile' ||
      path == '/referral' ||
      path == '/profile' ||
      path == '/profile/complete-care' ||
      path == '/profile/language' ||
      path == '/profile/settings' ||
      path == '/profile/notifications' ||
      path == '/profile/change-password' ||
      path == '/profile/payments' ||
      path == '/history' ||
      path == '/mental-health';
}

bool isSharedProtectedRoute(String path) {
  return path == '/medication-tracking' || path == '/care/chat/:visitId';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authSession = ref.watch(authSessionProvider);
  final currentPatient = ref.watch(currentPatientContextProvider);
  final isLoggedIn = authSession.isLoggedIn;
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
        if (isLoggedIn) {
          return authSession.isProvider ? '/dashboard/provider' : '/';
        }
        if (onboardingDone) return '/auth';
        return '/onboarding';
      }

      if (!isLoggedIn && !isPublicRoute(path)) {
        return '/auth';
      }

      // Shared protected routes require login but allow both roles.
      if (!isLoggedIn && isSharedProtectedRoute(path)) {
        return '/auth';
      }

      if (isLoggedIn && isProviderRoute(path) && !authSession.isProvider) {
        return '/';
      }

      if (isLoggedIn && (path == '/login' || path.startsWith('/auth'))) {
        return authSession.isProvider ? '/dashboard/provider' : '/';
      }

      if (authSession.isProvider && isPatientRoute(path)) {
        return '/dashboard/provider';
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
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthEntryScreen(),
      ),
      GoRoute(
        path: '/auth/sign-in',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/chp',
        builder: (context, state) => const ChpSignInScreen(),
      ),
      GoRoute(
        path: '/auth/create-account',
        builder: (context, state) => const CreateAccountScreen(),
      ),
      GoRoute(
        path: '/auth/recover',
        builder: (context, state) => const RecoverAccountScreen(),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (context, state) => const OtpScreen(),
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
        path: '/symptom-check',
        builder: (context, state) => const SymptomCheckScreen(),
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
      GoRoute(path: '/care', builder: (context, state) => const CareScreen()),
      GoRoute(
        path: '/care/anc-profile',
        builder: (context, state) => AncProfileScreen(
          mode: AncProfileMode.patientReadOnly,
          patientId: currentPatient?.storageKey ?? 'current-patient',
        ),
      ),
      GoRoute(
        path: '/care/chat/:visitId',
        builder: (context, state) {
          final visitId =
              int.tryParse(state.pathParameters['visitId'] ?? '') ?? 0;
          if (visitId == 0) {
            return Scaffold(
              appBar: AppBar(title: const Text('Chat')),
              body: const Center(child: Text('Invalid visit ID.')),
            );
          }
          final title = state.uri.queryParameters['title'] ?? 'Chat';
          return CaseChatScreen(visitId: visitId, visitTitle: title);
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/profile/complete-care',
        builder: (context, state) => const CompleteCareProfileScreen(),
      ),
      GoRoute(
        path: '/profile/language',
        builder: (context, state) => const LanguageScreen(),
      ),
      GoRoute(
        path: '/profile/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/profile/payments',
        builder: (context, state) => const PaymentsScreen(),
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
        path: '/medication-tracking',
        builder: (context, state) {
          final query = state.uri.queryParameters;
          final providerRequested = query['mode'] == 'provider';
          final canUseProviderMode =
              authSession.isProvider && providerRequested;

          return MedicationTrackingScreen(
            mode: canUseProviderMode
                ? MedicationTrackingMode.providerManage
                : MedicationTrackingMode.patientReadOnly,
            patientId: query['patientId'] ??
                currentPatient?.storageKey ??
                'current-patient',
            patientName: query['patientName'],
          );
        },
      ),
      GoRoute(
        path: '/dashboard/provider',
        builder: (context, state) => const ProviderDashboard(),
      ),
      GoRoute(
        path: '/dashboard/provider/anc-profile',
        builder: (context, state) {
          final query = state.uri.queryParameters;
          return AncProfileScreen(
            mode: AncProfileMode.providerManage,
            patientId: query['patientId'] ?? 'current-patient',
            patientName: query['patientName'],
          );
        },
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
