import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_profile_providers.dart';

enum AuthSessionStatus {
  signedOut,
  demo,
  mother,
  provider,
  loading,
  error,
}

class AuthSession {
  const AuthSession({
    required this.status,
    this.errorMessage,
  });

  const AuthSession.signedOut() : this(status: AuthSessionStatus.signedOut);
  const AuthSession.loading() : this(status: AuthSessionStatus.loading);
  const AuthSession.demo() : this(status: AuthSessionStatus.demo);
  const AuthSession.mother() : this(status: AuthSessionStatus.mother);
  const AuthSession.provider() : this(status: AuthSessionStatus.provider);
  const AuthSession.error(String message)
      : this(status: AuthSessionStatus.error, errorMessage: message);

  final AuthSessionStatus status;
  final String? errorMessage;

  bool get isLoggedIn =>
      status == AuthSessionStatus.demo ||
      status == AuthSessionStatus.mother ||
      status == AuthSessionStatus.provider;

  bool get isProvider => status == AuthSessionStatus.provider;

  String get storageValue => status.name;

  static AuthSession fromStorage(String? value) {
    switch (value) {
      case 'demo':
        return const AuthSession.demo();
      case 'mother':
        return const AuthSession.mother();
      case 'provider':
        return const AuthSession.provider();
      default:
        return const AuthSession.signedOut();
    }
  }
}

class AuthSessionNotifier extends StateNotifier<AuthSession> {
  AuthSessionNotifier(this._ref) : super(const AuthSession.loading()) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacyLoggedIn = prefs.getBool('is_logged_in') ?? false;
      state = AuthSession.fromStorage(
        prefs.getString('auth_session_status') ??
            (legacyLoggedIn ? 'demo' : 'signedOut'),
      );
    } finally {
      _ref.read(authReadyProvider.notifier).state = true;
    }
  }

  Future<void> signIn({
    AuthSessionStatus status = AuthSessionStatus.mother,
  }) async {
    final next = switch (status) {
      AuthSessionStatus.demo => const AuthSession.demo(),
      AuthSessionStatus.provider => const AuthSession.provider(),
      AuthSessionStatus.mother => const AuthSession.mother(),
      _ => const AuthSession.mother(),
    };
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('auth_session_status', next.storageValue);
  }

  Future<void> signOut() async {
    state = const AuthSession.signedOut();
    _ref.read(profileFormDataProvider.notifier).state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.setString('auth_session_status', 'signedOut');
  }

  static Future<bool> hasAcceptedTerms() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('terms_accepted') ?? false;
  }

  static Future<void> acceptTerms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('terms_accepted', true);
  }
}

final authSessionProvider =
    StateNotifierProvider<AuthSessionNotifier, AuthSession>((ref) {
  return AuthSessionNotifier(ref);
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authSessionProvider).isLoggedIn;
});

final isProviderSessionProvider = Provider<bool>((ref) {
  return ref.watch(authSessionProvider).isProvider;
});

/// True after SharedPreferences session load completes.
final authReadyProvider = StateProvider<bool>((ref) => false);

/// True after cold-start splash minimum duration (5s).
final splashMinimumDoneProvider = StateProvider<bool>((ref) => false);
