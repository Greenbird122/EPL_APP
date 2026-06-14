import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_ai/core/network/backend_services.dart';

class DashboardStats {
  const DashboardStats({
    this.totalVisits = 0,
    this.highRisk = 0,
    this.moderateRisk = 0,
    this.lowRisk = 0,
    this.latestRiskLevel,
    this.totalReferrals = 0,
    this.pendingFollowups = 0,
    this.activeAlerts = 0,
    this.communityName,
    this.membershipStatus,
    this.chpName,
    this.chpPhone,
    this.profilePercent = 0,
    this.visitTrend = const [],
    this.recentReferrals = const [],
    this.upcomingFollowups = const [],
    this.patientIdentifier,
  });

  final int totalVisits;
  final int highRisk;
  final int moderateRisk;
  final int lowRisk;
  final String? latestRiskLevel;
  final int totalReferrals;
  final int pendingFollowups;
  final int activeAlerts;
  final String? communityName;
  final String? membershipStatus;
  final String? chpName;
  final String? chpPhone;
  final int profilePercent;
  final List<Map<String, dynamic>> visitTrend;
  final List<Map<String, dynamic>> recentReferrals;
  /// Upcoming follow-up appointments (from `upcoming_followups` in API).
  final List<Map<String, dynamic>> upcomingFollowups;
  /// Patient digital ID status from `patient_identifier` in API.
  /// Contains `has_pid` (bool) and `is_active` (bool).
  final Map<String, dynamic>? patientIdentifier;

  factory DashboardStats.fromMap(Map<String, dynamic> data) {
    return DashboardStats(
      totalVisits: (data['total_visits'] as num?)?.toInt() ?? 0,
      highRisk: (data['high_risk'] as num?)?.toInt() ?? 0,
      moderateRisk: (data['moderate_risk'] as num?)?.toInt() ?? 0,
      lowRisk: (data['low_risk'] as num?)?.toInt() ?? 0,
      latestRiskLevel: data['latest_risk_level'] as String?,
      totalReferrals: (data['total_referrals'] as num?)?.toInt() ?? 0,
      pendingFollowups: (data['pending_followups'] as num?)?.toInt() ?? 0,
      activeAlerts: (data['active_alerts'] as num?)?.toInt() ?? 0,
      communityName: data['community_name'] as String?,
      membershipStatus: data['membership_status'] as String?,
      chpName: data['chp_name'] as String?,
      chpPhone: data['chp_phone'] as String?,
      profilePercent: (data['profile_percent'] as num?)?.toInt() ??
          (data['profile_completed'] as num?)?.toInt() ?? 0,
      visitTrend: (data['visit_trend'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      recentReferrals: (data['recent_referrals'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      upcomingFollowups: (data['upcoming_followups'] as List?)
              ?.whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList() ??
          [],
      patientIdentifier: data['patient_identifier'] is Map
          ? Map<String, dynamic>.from(data['patient_identifier'] as Map)
          : null,
    );
  }
}

/// Fetches live dashboard statistics from the backend.
/// Returns an empty [DashboardStats] on error so the UI degrades gracefully.
final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  try {
    final data = await ref.read(patientApiProvider).getDashboardStats();
    return DashboardStats.fromMap(data);
  } catch (_) {
    return const DashboardStats();
  }
});
