import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_ai/core/network/api_client.dart';
import 'package:repair_ai/core/network/backend_services.dart';
import 'package:repair_ai/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:repair_ai/features/auth/presentation/controllers/report_history_providers.dart';

class ProfileCompletionState {
  const ProfileCompletionState({
    required this.isComplete,
    required this.missingFields,
  });

  final bool isComplete;
  final List<String> missingFields;
}

class CareFeedState {
  const CareFeedState({
    required this.connectionState,
    required this.backendReports,
    required this.localReports,
    required this.triageResults,
    required this.referrals,
    required this.followUps,
    required this.alerts,
    required this.prescriptions,
    required this.profileCompletion,
    this.notices = const [],
  });

  final BackendConnectionState connectionState;
  final List<Map<String, dynamic>> backendReports;
  final List<SymptomReport> localReports;
  final List<Map<String, dynamic>> triageResults;
  final List<Map<String, dynamic>> referrals;
  final List<Map<String, dynamic>> followUps;
  final List<Map<String, dynamic>> alerts;
  final List<Map<String, dynamic>> prescriptions;
  final ProfileCompletionState profileCompletion;
  final List<String> notices;

  bool get hasBackendData =>
      backendReports.isNotEmpty ||
      triageResults.isNotEmpty ||
      referrals.isNotEmpty ||
      followUps.isNotEmpty ||
      alerts.isNotEmpty ||
      prescriptions.isNotEmpty;
}

final careFeedProvider = FutureProvider.autoDispose<CareFeedState>((ref) async {
  final localReports = ref.watch(reportHistoryProvider);
  final patientApi = ref.watch(patientApiProvider);
  final visitApi = ref.watch(visitApiProvider);
  final triageApi = ref.watch(triageApiProvider);
  final referralApi = ref.watch(referralApiProvider);
  final followUpApi = ref.watch(followUpApiProvider);
  final clinicalApi = ref.watch(clinicalApiProvider);
  final tokenStore = ref.watch(secureTokenStoreProvider);

  String? token;
  try {
    token = await tokenStore.readAccessToken();
  } catch (_) {
    token = null;
  }

  if (token == null) {
    return CareFeedState(
      connectionState: BackendConnectionState.offline,
      backendReports: const [],
      localReports: localReports,
      triageResults: const [],
      referrals: const [],
      followUps: const [],
      alerts: const [],
      prescriptions: const [],
      profileCompletion: const ProfileCompletionState(
        isComplete: false,
        missingFields: ['sign in'],
      ),
      notices: const [
        'Sign in to connect this page to your backend care records.',
      ],
    );
  }

  // Accumulate results so a late 401 doesn't discard already-fetched data.
  List<Map<String, dynamic>> backendReports = const [];
  List<Map<String, dynamic>> triageResults = const [];
  List<Map<String, dynamic>> referrals = const [];
  List<Map<String, dynamic>> followUps = const [];
  List<Map<String, dynamic>> alerts = const [];
  List<Map<String, dynamic>> prescriptions = const [];
  List<String> notices = const [];
  Map<String, dynamic>? profile;

  try {
    profile = await patientApi.myProfile();
    final patientId = profile['id'] as int?;
    notices = <String>[];

    backendReports = await _safeFetchList(
      () => visitApi.visits(patientId: patientId),
      notices,
      label: 'Reports',
    );
    triageResults = await _safeFetchList(
      () => triageApi.results(patientId: patientId),
      notices,
      label: 'AI assessments',
    );
    referrals = await _safeFetchList(
      () => referralApi.referrals(patientId: patientId),
      notices,
      label: 'Referrals',
    );
    followUps = await _safeFetchList(
      () => followUpApi.schedules(patientId: patientId),
      notices,
      label: 'Follow-ups',
    );
    alerts = await _safeFetchList(
      () => followUpApi.alerts(patientId: patientId),
      notices,
      label: 'Alerts',
    );
    prescriptions = await _safeFetchList(
      () => clinicalApi.decisions(patientId: patientId),
      notices,
      label: 'Prescriptions',
      forbiddenMessage:
          'Prescriptions are connected, but this patient account is not allowed to read /api/clinical/ yet.',
    );

    return CareFeedState(
      connectionState: BackendConnectionState.online,
      backendReports: backendReports,
      localReports: localReports,
      triageResults: triageResults,
      referrals: referrals,
      followUps: followUps,
      alerts: alerts,
      prescriptions: prescriptions,
      profileCompletion: _profileCompletion(profile),
      notices: notices,
    );
  } on ApiException catch (error) {
    if (error.statusCode == 401) {
      await ref.read(authSessionProvider.notifier).signOutBackend();
      // Don't discard already-fetched data — return what we collected so far.
      return CareFeedState(
        connectionState: BackendConnectionState.offline,
        backendReports: backendReports,
        localReports: localReports,
        triageResults: triageResults,
        referrals: referrals,
        followUps: followUps,
        alerts: alerts,
        prescriptions: prescriptions,
        profileCompletion: const ProfileCompletionState(
          isComplete: false,
          missingFields: ['sign in'],
        ),
        notices: [
          ...notices,
          'Your session expired. Some data may be unavailable.',
        ],
      );
    }
    return CareFeedState(
      connectionState: BackendConnectionState.offline,
      backendReports: const [],
      localReports: localReports,
      triageResults: const [],
      referrals: const [],
      followUps: const [],
      alerts: const [],
      prescriptions: const [],
      profileCompletion: const ProfileCompletionState(
        isComplete: false,
        missingFields: ['sign in'],
      ),
      notices: [
        error.statusCode == 403
            ? 'Your account does not have permission to access this care data.'
            : error.message,
      ],
    );
  } catch (_) {
    // Non-API errors (network, etc.) — still preserve already-fetched data.
    return CareFeedState(
      connectionState: BackendConnectionState.offline,
      backendReports: backendReports,
      localReports: localReports,
      triageResults: triageResults,
      referrals: referrals,
      followUps: followUps,
      alerts: alerts,
      prescriptions: prescriptions,
      profileCompletion: const ProfileCompletionState(
        isComplete: false,
        missingFields: ['age', 'sub-county', 'LMP'],
      ),
      notices: [
        ...notices,
        'We could not connect to the backend. Saved care data is still shown where available.',
      ],
    );
  }
});

Future<List<Map<String, dynamic>>> _safeFetchList(
  Future<List<Map<String, dynamic>>> Function() request,
  List<String> notices, {
  required String label,
  String? forbiddenMessage,
}) async {
  try {
    return await request();
  } on ApiException catch (error) {
    if (error.statusCode == 401) rethrow;
    if (error.statusCode == 403) {
      notices.add(
        forbiddenMessage ??
            '$label could not be loaded because this account does not have permission.',
      );
      return const [];
    }
    if (error.statusCode == 404) {
      notices.add('$label endpoint was not found on the backend.');
      return const [];
    }
    notices.add('$label could not be loaded: ${error.message}');
    return const [];
  } catch (_) {
    notices.add('$label could not be loaded right now.');
    return const [];
  }
}

ProfileCompletionState _profileCompletion(Map<String, dynamic> profile) {
  final missing = <String>[];
  for (final entry in const {
    'age': 'age',
    'county': 'county',
    'sub_county': 'sub-county',
    'village': 'village',
    'gravida': 'pregnancy history',
    'lmp': 'last period date',
  }.entries) {
    final value = profile[entry.key];
    if (value == null || value.toString().trim().isEmpty) {
      missing.add(entry.value);
    }
  }

  return ProfileCompletionState(
    isComplete: missing.isEmpty,
    missingFields: missing,
  );
}
