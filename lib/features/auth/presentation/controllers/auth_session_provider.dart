import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_ai/core/network/api_client.dart';
import 'package:repair_ai/core/network/backend_services.dart';
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
      if (!mounted) return;
      final legacyLoggedIn = prefs.getBool('is_logged_in') ?? false;
      final stored = AuthSession.fromStorage(
        prefs.getString('auth_session_status') ??
            (legacyLoggedIn ? 'demo' : 'signedOut'),
      );
      final hasBackendToken = await _hasStoredBackendToken();
      if (!mounted) return;

      if (hasBackendToken) {
        try {
          final profile = await _ref.read(authApiProvider).profile();
          if (!mounted) return;
          state = _sessionForBackendRole(profile['role'] as String?);
          await _persistSession(state);
          if (!mounted) return;
          _setProfileFromBackend(profile);
          return;
        } on ApiException catch (error) {
          if (!mounted) return;
          if (error.statusCode == 401) {
            await signOut();
            return;
          }
          state = stored;
        } catch (_) {
          if (!mounted) return;
          state = stored;
        }
      } else {
        state = stored.status == AuthSessionStatus.demo
            ? stored
            : const AuthSession.signedOut();
      }
    } finally {
      if (mounted) {
        _ref.read(authReadyProvider.notifier).state = true;
      }
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
    await _persistSession(next);
  }

  Future<AuthSession> signInWithBackend({
    required String username,
    required String password,
    bool rememberMe = true,
  }) async {
    state = const AuthSession.loading();
    try {
      final data = await _ref.read(authApiProvider).login(
            username: username.trim(),
            password: password,
            rememberMe: rememberMe,
          );
      final next = _sessionForBackendRole(data['role'] as String?);
      state = next;
      await _persistSession(next, remember: rememberMe);
      _setProfileFromBackend(data);
      await AuthSessionNotifier.acceptTerms();
      return next;
    } catch (error) {
      final message = _messageForError(error);
      state = AuthSession.error(message);
      rethrow;
    }
  }

  Future<AuthSession> registerPatientWithBackend({
    required String username,
    required String email,
    required String password,
    required String passwordConfirm,
    required String fullName,
    required String phone,
    bool rememberMe = true,
  }) async {
    state = const AuthSession.loading();
    final names = _splitName(fullName);
    try {
      await _ref.read(authApiProvider).registerPatient({
        'username': username.trim(),
        'email': email.trim(),
        'first_name': names.$1,
        'last_name': names.$2,
        'phone': phone.trim(),
        'password': password,
        'password_confirm': passwordConfirm,
      });
      return signInWithBackend(
        username: username,
        password: password,
        rememberMe: rememberMe,
      );
    } catch (error) {
      final message = _messageForError(error);
      state = AuthSession.error(message);
      rethrow;
    }
  }

  Future<void> restoreBackendSession() async {
    state = const AuthSession.loading();
    try {
      final profile = await _ref.read(authApiProvider).profile();
      final next = _sessionForBackendRole(profile['role'] as String?);
      state = next;
      await _persistSession(next);
      _setProfileFromBackend(profile);
    } catch (error) {
      if (error is ApiException && error.statusCode == 401) {
        await signOutBackend();
        return;
      }
      final message = _messageForError(error);
      state = AuthSession.error(message);
      rethrow;
    }
  }

  Future<void> refreshBackendSession() async {
    final refreshToken =
        await _ref.read(secureTokenStoreProvider).readRefreshToken();
    if (refreshToken == null) {
      await signOut();
      throw const ApiException(
        'Your session expired. Please sign in again.',
        statusCode: 401,
      );
    }
    await _ref.read(authApiProvider).refresh(refreshToken: refreshToken);
    await restoreBackendSession();
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _ref.read(authApiProvider).changePassword(
          oldPassword: oldPassword,
          newPassword: newPassword,
          confirmPassword: confirmPassword,
        );
  }

  Future<void> signOutBackend() async {
    await _ref.read(authApiProvider).logout();
    await signOut();
  }

  Future<bool> _hasStoredBackendToken() async {
    try {
      return await _ref.read(secureTokenStoreProvider).readAccessToken() !=
          null;
    } catch (_) {
      return false;
    }
  }

  Future<void> _persistSession(
    AuthSession next, {
    bool remember = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (!remember) {
      await prefs.setBool('is_logged_in', false);
      await prefs.setString('auth_session_status', 'signedOut');
      return;
    }
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('auth_session_status', next.storageValue);
  }

  Future<void> signOut() async {
    state = const AuthSession.signedOut();
    _ref.read(profileFormDataProvider.notifier).state = null;
    await _ref.read(secureTokenStoreProvider).clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.setString('auth_session_status', 'signedOut');
  }

  AuthSession _sessionForBackendRole(String? role) {
    return switch (role) {
      'patient' => const AuthSession.mother(),
      'chp' => const AuthSession.provider(),
      'admin' || 'moh' || 'nurse' || 'clinician' => throw const ApiException(
          'This account is managed in the web dashboard. Please use the website for this role.',
          statusCode: 403,
        ),
      _ => throw ApiException(
          'Unsupported account role: ${role ?? 'unknown'}.',
          statusCode: 403,
        ),
    };
  }

  void _setProfileFromBackend(Map<String, dynamic> data) {
    final name = (data['full_name'] ?? data['username'] ?? '').toString();
    final email = (data['email'] ?? '').toString();
    if (name.isEmpty && email.isEmpty) return;
    _ref.read(profileFormDataProvider.notifier).state = ProfileFormData(
      name: name.isEmpty ? 'REPAIR-AI user' : name,
      email: email.isEmpty ? 'Signed in' : email,
    );
  }

  (String, String) _splitName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return ('', '');
    if (parts.length == 1) return (parts.first, '');
    return (parts.first, parts.skip(1).join(' '));
  }

  String _messageForError(Object error) {
    if (error is ApiException) return error.message;
    return 'Backend request failed. Check your connection and try again.';
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
