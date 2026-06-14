import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_ai/core/network/api_client.dart';
import 'package:repair_ai/core/network/backend_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_profile_providers.dart';

enum AuthSessionStatus { signedOut, patient, chp, loading, error }

class AuthSession {
  const AuthSession({
    required this.status,
    this.errorMessage,
    this.patientId,
  });

  const AuthSession.signedOut() : this(status: AuthSessionStatus.signedOut);
  const AuthSession.loading() : this(status: AuthSessionStatus.loading);
  // Named 'patient' to align with backend role name 'patient'
  const AuthSession.patient({int? patientId})
      : this(status: AuthSessionStatus.patient, patientId: patientId);
  // Named 'chp' to align with backend role name 'chp' (Community Health Promoter)
  const AuthSession.chp({int? patientId})
      : this(status: AuthSessionStatus.chp, patientId: patientId);
  const AuthSession.error(String message)
      : this(status: AuthSessionStatus.error, errorMessage: message);

  final AuthSessionStatus status;
  final String? errorMessage;
  final int? patientId;

  bool get isLoggedIn =>
      status == AuthSessionStatus.patient ||
      status == AuthSessionStatus.chp;

  bool get isProvider => status == AuthSessionStatus.chp;

  String get storageValue => status.name;

  static AuthSession fromStorage(String? value) {
    switch (value) {
      // Legacy 'mother' key kept for backward-compat with existing stored prefs
      case 'mother':
      case 'patient':
        return const AuthSession.patient();
      // Legacy 'provider' key kept for backward-compat with existing stored prefs
      case 'provider':
      case 'chp':
        return const AuthSession.chp();
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
            (legacyLoggedIn ? 'mother' : 'signedOut'),
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
          await _loadLinkedPatientProfileIfNeeded(state);
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
        // No backend token — restore demo session if one was stored
        state = stored.isLoggedIn ? stored : const AuthSession.signedOut();
      }
    } finally {
      if (mounted) {
        _ref.read(authReadyProvider.notifier).state = true;
      }
    }
  }

  Future<void> signIn({
    AuthSessionStatus status = AuthSessionStatus.patient,
    int? patientId,
  }) async {
    final next = switch (status) {
      AuthSessionStatus.chp => AuthSession.chp(patientId: patientId),
      AuthSessionStatus.patient => AuthSession.patient(patientId: patientId),
      _ => AuthSession.patient(patientId: patientId),
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
      await _loadLinkedPatientProfileIfNeeded(next);
      await AuthSessionNotifier.acceptTerms();
      return next;
    } catch (error) {
      rethrow;
    }
  }

  Future<AuthSession> registerPatientWithBackend({
    required String password,
    required String passwordConfirm,
    required String fullName,
    required String phone,
    required String country,
    required String county,
    required String subCounty,
    bool rememberMe = true,
  }) async {
    state = const AuthSession.loading();
    final names = _splitName(fullName);
    try {
      await _ref.read(authApiProvider).registerPatient({
        'first_name': names.$1,
        'last_name': names.$2,
        'phone': phone.trim(),
        'password': password,
        'password_confirm': passwordConfirm,
        'country': country,
        'county': county,
        'sub_county': subCounty,
      });
      try {
        return await signInWithBackend(
          username: phone,
          password: password,
          rememberMe: rememberMe,
        );
      } catch (_) {
        return signInWithBackend(
          username: phone,
          password: password,
          rememberMe: rememberMe,
        );
      }
    } catch (error) {
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
      await _loadLinkedPatientProfileIfNeeded(next);
    } catch (error) {
      if (error is ApiException && error.statusCode == 401) {
        await signOutBackend();
        return;
      }
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

  Future<void> _persistSession(AuthSession next, {bool remember = true}) async {
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
    _ref.read(currentPatientContextProvider.notifier).state = null;
    await _ref.read(secureTokenStoreProvider).clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
    await prefs.setString('auth_session_status', 'signedOut');
  }

  AuthSession _sessionForBackendRole(String? role) {
    return switch (role) {
      // Backend role 'patient' → mobile AuthSessionStatus.patient
      'patient' => const AuthSession.patient(),
      // Backend role 'chp' → mobile AuthSessionStatus.chp
      'chp' => const AuthSession.chp(),
      'admin' || 'moh' || 'nurse' || 'clinician' => throw const ApiException(
          'This account is managed on the web dashboard. Please use the website for this role.',
          statusCode: 403,
        ),
      _ => throw const ApiException(
          'This account type is not available in the mobile app yet.',
          statusCode: 403,
        ),
    };
  }

  void _setProfileFromBackend(Map<String, dynamic> data) {
    final fullName = (data['full_name'] ?? '').toString();
    final email = (data['email'] ?? '').toString();
    final phone = data['phone'] as String?;
    final role = data['role'] as String?;
    final userId = data['user_id'] as int? ?? data['id'] as int?;
    final patientId = data['patient_id'] as int? ?? userId;
    final perms = (data['permissions'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final roles = (data['rbac_roles'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        const <Map<String, dynamic>>[];

    final name = fullName.isEmpty
        ? (email.isEmpty ? 'REPAIR-AI user' : email)
        : fullName;
    final displayEmail = email.isEmpty ? 'Signed in' : email;

    _ref.read(profileFormDataProvider.notifier).state = ProfileFormData(
      name: name,
      email: displayEmail,
      phone: phone,
      role: role,
      userId: userId,
      permissions: perms,
      rbacRoles: roles,
    );

    // Set patient context for patient users and update state with patient ID
    if (state.status == AuthSessionStatus.patient && patientId != null) {
      _ref.read(currentPatientContextProvider.notifier).state =
          CurrentPatientContext(
        id: patientId,
        name: name,
      );
      // Update state to include patient ID
      state = AuthSession.patient(patientId: patientId);
    } else if (state.status == AuthSessionStatus.chp &&
        patientId != null) {
      state = AuthSession.chp(patientId: patientId);
    }
  }

  Future<void> _loadLinkedPatientProfileIfNeeded(AuthSession session) async {
    if (session.status != AuthSessionStatus.patient) {
      _ref.read(currentPatientContextProvider.notifier).state = null;
      return;
    }
    final profile = await _ref.read(patientApiProvider).myProfile();
    final patientId = profile['id'] as int?;
    if (patientId == null) {
      throw const ApiException(
        'Your care profile is not ready yet. Please contact support.',
        statusCode: 404,
      );
    }
    final name = (profile['name'] ?? '').toString().trim();
    _ref.read(currentPatientContextProvider.notifier).state =
        CurrentPatientContext(
      id: patientId,
      name: name.isEmpty ? 'Patient' : name,
    );
  }

  (String, String) _splitName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return ('', '');
    if (parts.length == 1) return (parts.first, '');
    return (parts.first, parts.skip(1).join(' '));
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
