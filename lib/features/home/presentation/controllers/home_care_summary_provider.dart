import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_ai/core/network/backend_services.dart';
import 'package:repair_ai/features/auth/presentation/controllers/login_profile_providers.dart';

enum CareCompassState {
  noCheck,
  checked,
  referralNeeded,
  followUpPending,
  stable,
  profileNeeded,
  offline,
}

enum CareSignalStatus { empty, ready, warning, urgent, complete, offline }

class HomeCareSummary {
  const HomeCareSummary({
    this.patientId,
    this.name,
    this.county,
    this.pregnancyWeeks,
    this.latestRisk,
    this.latestVisitId,
    this.latestTriageId,
    this.referralStatus,
    this.followUpCount = 0,
    this.alertCount = 0,
    this.backendAvailable = true,
    this.error,
  });

  final int? patientId;
  final String? name;
  final String? county;
  final double? pregnancyWeeks;
  final String? latestRisk;
  final int? latestVisitId;
  final int? latestTriageId;
  final String? referralStatus;
  final int followUpCount;
  final int alertCount;
  final bool backendAvailable;
  final String? error;

  bool get hasProfile => patientId != null;
  bool get hasRisk => latestRisk != null && latestRisk!.trim().isNotEmpty;
  bool get hasReferral =>
      referralStatus != null && referralStatus!.trim().isNotEmpty;
  bool get hasFollowUp => followUpCount > 0 || alertCount > 0;

  CareCompassState get state {
    if (!backendAvailable) return CareCompassState.offline;
    if (!hasProfile) return CareCompassState.profileNeeded;
    if (alertCount > 0 || followUpCount > 0) {
      return CareCompassState.followUpPending;
    }
    if (hasReferral) return CareCompassState.referralNeeded;
    if (hasRisk) return CareCompassState.checked;
    return CareCompassState.noCheck;
  }
}

final homeCareSummaryProvider =
    FutureProvider.autoDispose<HomeCareSummary>((ref) async {
  final patientApi = ref.watch(patientApiProvider);
  final visitApi = ref.watch(visitApiProvider);
  final triageApi = ref.watch(triageApiProvider);
  final referralApi = ref.watch(referralApiProvider);
  final followUpApi = ref.watch(followUpApiProvider);
  final currentPatient = ref.watch(currentPatientContextProvider);

  try {
    final profile = await patientApi.myProfile();
    final patientId = _intValue(profile['id']) ?? currentPatient?.id;
    if (patientId == null) {
      return HomeCareSummary(
        name: currentPatient?.name,
        backendAvailable: true,
      );
    }

    final visits = await visitApi.visits(patientId: patientId);
    final triageResults = await triageApi.results(patientId: patientId);
    final referrals = await referralApi.referrals(patientId: patientId);
    final followUps = await followUpApi.schedules(patientId: patientId);
    final alerts = await followUpApi.alerts(patientId: patientId);

    final latestVisit = _latestByDate(visits, ['visit_date', 'created_at']);
    final latestTriage =
        _latestByDate(triageResults, ['processed_at', 'created_at']);
    final latestReferral =
        _latestByDate(referrals, ['created_at', 'updated_at']);

    return HomeCareSummary(
      patientId: patientId,
      name: _stringOrNull(profile['name']) ??
          _stringOrNull(profile['full_name']) ??
          currentPatient?.name,
      county: _stringOrNull(profile['county']),
      pregnancyWeeks: _doubleValue(
        latestVisit?['gestation_weeks'] ?? profile['gestation_weeks'],
      ),
      latestRisk: _stringOrNull(
        latestTriage?['risk_level'] ??
            latestVisit?['triage_result']?['risk_level'],
      ),
      latestVisitId: _intValue(latestVisit?['id']),
      latestTriageId: _intValue(latestTriage?['id']),
      referralStatus: _stringOrNull(latestReferral?['status']),
      followUpCount: followUps.length,
      alertCount: alerts.length,
      backendAvailable: true,
    );
  } catch (error) {
    return HomeCareSummary(
      name: currentPatient?.name,
      patientId: currentPatient?.id,
      backendAvailable: false,
      error: error.toString(),
    );
  }
});

Map<String, dynamic>? _latestByDate(
  List<Map<String, dynamic>> items,
  List<String> dateKeys,
) {
  if (items.isEmpty) return null;
  final sorted = [...items];
  sorted.sort((a, b) {
    final aDate = _firstDate(a, dateKeys);
    final bDate = _firstDate(b, dateKeys);
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return bDate.compareTo(aDate);
  });
  return sorted.first;
}

DateTime? _firstDate(Map<String, dynamic> item, List<String> keys) {
  for (final key in keys) {
    final raw = item[key]?.toString();
    if (raw == null || raw.isEmpty) continue;
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed;
  }
  return null;
}

String? _stringOrNull(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') return null;
  return text;
}

int? _intValue(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _doubleValue(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
