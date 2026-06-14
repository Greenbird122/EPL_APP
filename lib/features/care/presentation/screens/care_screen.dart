import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/network/backend_services.dart';
import 'package:repair_ai/core/utils/responsive.dart';
import 'package:repair_ai/features/auth/presentation/controllers/report_history_providers.dart';
import 'package:repair_ai/features/anc/presentation/controllers/anc_profile_controller.dart';
import 'package:repair_ai/features/care/presentation/controllers/care_feed_provider.dart';
import 'package:repair_ai/shared/widgets/bottom_nav.dart';
import 'package:repair_ai/shared/widgets/repair_app_bar.dart';
import 'package:repair_ai/shared/widgets/responsive_page.dart';

class CareScreen extends ConsumerWidget {
  const CareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(careFeedProvider);
    return Scaffold(
      appBar: const RepairAppBar(title: 'Your Care'),
      body: feed.when(
        loading: () => const CareLoading(),
        error: (_, __) => CareBody(
          state: _emptyState(ref),
          onRefresh: () {
            ref.invalidate(careFeedProvider);
          },
        ),
        data: (state) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(careFeedProvider);
          },
          child: CareBody(state: state),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  CareFeedState _emptyState(WidgetRef ref) => CareFeedState(
        connectionState: BackendConnectionState.offline,
        backendReports: [],
        localReports: ref.watch(reportHistoryProvider),
        triageResults: [],
        referrals: [],
        followUps: [],
        alerts: [],
        prescriptions: [],
        profileCompletion: const ProfileCompletionState(
            isComplete: false, missingFields: ['profile']),
        notices: const ['Pull down to retry.'],
      );
}

class CareBody extends StatelessWidget {
  const CareBody({super.key, required this.state, this.onRefresh});
  final CareFeedState state;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final compact = RepairBreakpoints.isCompactPhone(context);
    final triage = state.triageResults;
    final highCount = triage.where((t) => t['risk_level'] == 'high').length;

    return ListView(
      padding: RepairInsets.scroll(context),
      children: [
        ResponsivePageShell(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 8),
              _ConnectionBanner(state: state),
              const SizedBox(height: 12),
              const _SectionTitle(text: 'Your Health Summary'),
              const SizedBox(height: 8),
              _StatsRow(state: state, compact: compact, highCount: highCount),
              const SizedBox(height: 20),
              const _SectionTitle(text: 'Your Check-ups'),
              const SizedBox(height: 8),
              if (state.backendReports.isNotEmpty)
                ...state.backendReports
                    .take(3)
                    .map((r) => _ReportCard(report: r))
              else if (state.localReports.isNotEmpty)
                ...state.localReports.reversed
                    .take(3)
                    .map((r) => _LocalCard(report: r))
              else
                const _EmptySlot(message: 'No check-ups yet'),
              Center(
                  child: TextButton(
                      onPressed: () => context.push('/history'),
                      child: const Text('View all'))),
              const SizedBox(height: 16),
              const _SectionTitle(text: 'Facility Visits'),
              const SizedBox(height: 8),
              if (state.referrals.isEmpty)
                const _EmptySlot(message: 'No facility visits')
              else
                ...state.referrals
                    .take(3)
                    .map((r) => _ReferralCard(referral: r)),
              Center(
                  child: TextButton(
                      onPressed: () => context.push('/referral'),
                      child: const Text('Find care'))),
              const SizedBox(height: 16),
              const _SectionTitle(text: 'Your Reminders'),
              const SizedBox(height: 8),
              if (state.followUps.isEmpty)
                const _EmptySlot(message: 'No reminders')
              else
                ...state.followUps
                    .take(2)
                    .map((f) => _FollowUpCard(followUp: f)),
              const SizedBox(height: 16),
              if (state.alerts.isNotEmpty) ...[
                const _SectionTitle(text: 'Warnings'),
                const SizedBox(height: 8),
                ...state.alerts.take(2).map((a) => _AlertCard(alert: a)),
                const SizedBox(height: 16),
              ],
              const AncSection(),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }
}

class CareLoading extends StatelessWidget {
  const CareLoading({super.key});
  @override
  Widget build(BuildContext context) {
    final compact = RepairBreakpoints.isCompactPhone(context);
    return ListView(padding: RepairInsets.scroll(context), children: [
      ResponsivePageShell(
          child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 20),
        child: Column(children: [
          const SizedBox(height: 8),
          const _Skel(height: 44),
          const SizedBox(height: 12),
          Row(
              children: List.generate(
                  5,
                  (_) => Expanded(
                      child: Container(
                          height: 90,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(16)))))),
          const SizedBox(height: 24),
          const _Skel(height: 20, width: 140),
          const SizedBox(height: 8),
          const _Skel(height: 70),
          const SizedBox(height: 8),
          const _Skel(height: 70),
          const SizedBox(height: 24),
          const _Skel(height: 20, width: 120),
          const SizedBox(height: 8),
          const _Skel(height: 70),
        ]),
      )),
    ]);
  }
}

class _Skel extends StatelessWidget {
  const _Skel({this.height = 56, this.width});
  final double height;
  final double? width;
  @override
  Widget build(BuildContext context) => Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14)));
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.state});
  final CareFeedState state;
  @override
  Widget build(BuildContext context) {
    final online = state.connectionState == BackendConnectionState.online;
    return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: online
                ? AppTheme.success.withValues(alpha: 0.08)
                : AppTheme.warning.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: online
                    ? AppTheme.success.withValues(alpha: 0.2)
                    : AppTheme.warning.withValues(alpha: 0.2))),
        child: Row(children: [
          Icon(online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              size: 18, color: online ? AppTheme.success : AppTheme.warning),
          const SizedBox(width: 8),
          Expanded(
              child: Text(
                  online
                      ? 'Your care data is up to date'
                      : 'Showing saved data',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: online ? AppTheme.success : AppTheme.warning))),
        ]));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          fontSize: RepairSizing.textScale(context, 17),
          fontWeight: FontWeight.w800));
}

class _StatsRow extends StatelessWidget {
  const _StatsRow(
      {required this.state, required this.compact, required this.highCount});
  final CareFeedState state;
  final bool compact;
  final int highCount;
  @override
  Widget build(BuildContext context) {
    final stats = [
      (
        Icons.assignment_turned_in,
        'Check-ups',
        state.backendReports.length + state.localReports.length,
        AppTheme.primary
      ),
      (
        Icons.warning_amber_rounded,
        'Needs attention',
        highCount,
        highCount > 0 ? AppTheme.error : AppTheme.primary.withValues(alpha: 0.5)
      ),
      (
        Icons.local_hospital,
        'Facility visits',
        state.referrals.length,
        AppTheme.accent
      ),
      (
        Icons.event_available,
        'Reminders',
        state.followUps.where((f) => f['sent'] != true).length,
        AppTheme.success
      ),
      (
        Icons.notifications_active,
        'Warnings',
        state.alerts.where((a) => a['resolved'] != true).length,
        AppTheme.warning
      ),
    ];
    return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: stats
              .map((s) => Container(
                    width: compact ? 100 : 120,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 10),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [
                              s.$4.withValues(alpha: 0.1),
                              s.$4.withValues(alpha: 0.04)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: s.$4.withValues(alpha: 0.15))),
                    child: Column(children: [
                      Icon(s.$1, color: s.$4, size: 22),
                      const SizedBox(height: 6),
                      Text('${s.$3}',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: s.$4)),
                      const SizedBox(height: 2),
                      Text(s.$2,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: s.$4.withValues(alpha: 0.8))),
                    ]),
                  ))
              .toList(),
        ));
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});
  final Map<String, dynamic> report;
  @override
  Widget build(BuildContext context) {
    final risk = '${report['risk_level'] ?? 'low'}'.toLowerCase();
    final c = risk == 'high'
        ? AppTheme.error
        : risk == 'moderate'
            ? AppTheme.warning
            : AppTheme.success;
    final visitId = report['id'] as int?;
    return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: visitId != null
              ? () => context.push('/care/chat/$visitId?title=Check-up')
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(
                    width: 8,
                    height: 40,
                    decoration: BoxDecoration(
                        color: c, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('${report['visit_date'] ?? 'Unknown'}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('${report['recommendation'] ?? ''}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontSize: 12)),
                    ])),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: c.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(risk.toUpperCase(),
                        style: TextStyle(
                            color: c,
                            fontSize: 11,
                            fontWeight: FontWeight.w800))),
              ])),
        ));
  }
}

class _LocalCard extends StatelessWidget {
  const _LocalCard({required this.report});
  final SymptomReport report;
  @override
  Widget build(BuildContext context) {
    final c = report.riskLevel == 'high'
        ? AppTheme.error
        : report.riskLevel == 'moderate'
            ? AppTheme.warning
            : AppTheme.success;
    return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                  width: 8,
                  height: 40,
                  decoration: BoxDecoration(
                      color: c, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        '${report.date.day}/${report.date.month}/${report.date.year}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${report.symptoms.length} symptoms',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12)),
                  ])),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(report.riskLevel.toUpperCase(),
                      style: TextStyle(
                          color: c,
                          fontSize: 11,
                          fontWeight: FontWeight.w800))),
            ])));
  }
}

class _ReferralCard extends StatelessWidget {
  const _ReferralCard({required this.referral});
  final Map<String, dynamic> referral;
  @override
  Widget build(BuildContext context) {
    final status = '${referral['status'] ?? 'pending'}';
    final sc = status == 'completed'
        ? AppTheme.success
        : status == 'cancelled'
            ? AppTheme.error
            : AppTheme.warning;
    return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.local_hospital,
                      color: AppTheme.primary, size: 20)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(
                        '${referral['facility_name'] ?? referral['facility'] ?? 'Facility'}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('Ref #${referral['id'] ?? '-'}',
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12)),
                  ])),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: sc.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(status.toUpperCase(),
                      style: TextStyle(
                          color: sc,
                          fontSize: 11,
                          fontWeight: FontWeight.w800))),
            ])));
  }
}

class _FollowUpCard extends StatelessWidget {
  const _FollowUpCard({required this.followUp});
  final Map<String, dynamic> followUp;
  @override
  Widget build(BuildContext context) {
    final sent = followUp['sent'] == true;
    return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                      color: (sent ? AppTheme.success : AppTheme.warning)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(
                      sent ? Icons.check_circle_outline : Icons.schedule,
                      color: sent ? AppTheme.success : AppTheme.warning,
                      size: 20)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(sent ? 'Done' : 'Upcoming',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                        'Due: ${followUp['due_date'] ?? 'TBD'} via ${followUp['channel'] ?? 'SMS'}',
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12)),
                  ])),
            ])));
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});
  final Map<String, dynamic> alert;
  @override
  Widget build(BuildContext context) => Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppTheme.error.withValues(alpha: 0.04),
      child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppTheme.error, size: 22),
            const SizedBox(width: 12),
            Expanded(
                child: Text(
                    '${alert['description'] ?? alert['flag'] ?? 'Active alert'}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600))),
          ])));
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.08))),
      child: Column(children: [
        Icon(Icons.inbox_outlined,
            size: 32, color: AppTheme.primary.withValues(alpha: 0.3)),
        const SizedBox(height: 6),
        Text(message,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12))
      ]));
}

class AncSection extends ConsumerWidget {
  const AncSection({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(ancProfileProvider);
    return profileAsync.when(
      loading: () => const _Skel(height: 70),
      error: (_, __) => const _EmptySlot(message: 'Could not load ANC profile'),
      data: (profile) {
        final flags = profile?.contextFlags ?? const [];
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _SectionTitle(text: 'ANC Profile'),
          const SizedBox(height: 8),
          if (profile == null || profile.isEmpty)
            const _EmptySlot(message: 'No ANC profile yet')
          else if (flags.isNotEmpty)
            ...flags.take(2).map((f) => _AlertCard(alert: {
                  'description': f.detail.isNotEmpty ? f.detail : f.label
                }))
          else
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(children: [
                      Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.verified_outlined,
                              color: AppTheme.success, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(
                              profile.nextAncAction.isNotEmpty
                                  ? profile.nextAncAction
                                  : 'ANC profile recorded',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600))),
                    ]))),
        ]);
      },
    );
  }
}
