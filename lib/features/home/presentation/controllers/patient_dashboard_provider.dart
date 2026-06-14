import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_ai/core/network/api_client.dart';
import 'package:repair_ai/core/network/backend_services.dart';

/// Lightweight dashboard stats for the patient.
class PatientDashboardStats {
  const PatientDashboardStats({
    required this.visitCount,
    required this.highRiskCount,
    required this.referralCount,
    required this.pendingFollowUpCount,
    required this.latestRiskLevel,
    this.hasLoaded = false,
    this.loadingMessage,
  });

  final int visitCount;
  final int highRiskCount;
  final int referralCount;
  final int pendingFollowUpCount;
  final String? latestRiskLevel;
  final bool hasLoaded;
  final String? loadingMessage;

  PatientDashboardStats.empty()
      : visitCount = 0,
        highRiskCount = 0,
        referralCount = 0,
        pendingFollowUpCount = 0,
        latestRiskLevel = null,
        hasLoaded = false,
        loadingMessage = null;

  PatientDashboardStats.loading({this.loadingMessage})
      : visitCount = 0,
        highRiskCount = 0,
        referralCount = 0,
        pendingFollowUpCount = 0,
        latestRiskLevel = null,
        hasLoaded = false;

  PatientDashboardStats.error()
      : visitCount = 0,
        highRiskCount = 0,
        referralCount = 0,
        pendingFollowUpCount = 0,
        latestRiskLevel = null,
        hasLoaded = false,
        loadingMessage = null;
}

/// Fetches patient dashboard stats from backend APIs.
final patientDashboardProvider =
    FutureProvider.autoDispose<PatientDashboardStats>((ref) async {
  final tokenStore = ref.watch(secureTokenStoreProvider);
  final token = await tokenStore.readAccessToken();
  if (token == null) {
    return PatientDashboardStats.empty();
  }

  final triageApi = ref.watch(triageApiProvider);
  final referralApi = ref.watch(referralApiProvider);
  final followUpApi = ref.watch(followUpApiProvider);
  final visitApi = ref.watch(visitApiProvider);

  int visitCount = 0;
  int highRiskCount = 0;
  int referralCount = 0;
  int pendingFollowUpCount = 0;
  String? latestRiskLevel;

  // Fetch all stats in parallel, catch errors individually
  await Future.wait([
    _safeInt(() async {
      final visits = await visitApi.visits();
      visitCount = visits.length;
    }),
    _safeInt(() async {
      final triageResults = await triageApi.results();
      highRiskCount =
          triageResults.where((t) => t['risk_level'] == 'high').length;
      if (triageResults.isNotEmpty) {
        latestRiskLevel =
            (triageResults.last['risk_level'] as String?)?.toLowerCase();
      }
    }),
    _safeInt(() async {
      final referrals = await referralApi.referrals();
      referralCount = referrals.length;
    }),
    _safeInt(() async {
      final followUps = await followUpApi.schedules();
      pendingFollowUpCount = followUps.where((f) => f['sent'] != true).length;
    }),
  ]);

  return PatientDashboardStats(
    visitCount: visitCount,
    highRiskCount: highRiskCount,
    referralCount: referralCount,
    pendingFollowUpCount: pendingFollowUpCount,
    latestRiskLevel: latestRiskLevel,
    hasLoaded: true,
  );
});

Future<void> _safeInt(Future<void> Function() fn) async {
  try {
    await fn();
  } on ApiException {
    // Individual stat failure shouldn't crash the whole dashboard
  } catch (_) {
    // Silently skip failed stats
  }
}
