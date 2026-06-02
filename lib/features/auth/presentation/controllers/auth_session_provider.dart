import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_profile_providers.dart';

class AuthSessionNotifier extends StateNotifier<bool> {
  AuthSessionNotifier(this._ref) : super(false) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = prefs.getBool('is_logged_in') ?? false;
    } finally {
      _ref.read(authReadyProvider.notifier).state = true;
    }
  }

  Future<void> signIn() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
  }

  Future<void> signOut() async {
    state = false;
    _ref.read(profileFormDataProvider.notifier).state = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
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
    StateNotifierProvider<AuthSessionNotifier, bool>((ref) {
  return AuthSessionNotifier(ref);
});

/// True after SharedPreferences session load completes.
final authReadyProvider = StateProvider<bool>((ref) => false);

/// True after cold-start splash minimum duration (5s).
final splashMinimumDoneProvider = StateProvider<bool>((ref) => false);
