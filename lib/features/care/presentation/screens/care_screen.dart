import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/network/backend_services.dart';
import 'package:repair_ai/core/utils/responsive.dart';
import 'package:repair_ai/features/auth/presentation/controllers/report_history_providers.dart';
import 'package:repair_ai/features/anc/presentation/controllers/anc_profile_controller.dart';
import 'package:repair_ai/features/care/presentation/controllers/care_feed_provider.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/shared/widgets/bottom_nav.dart';
import 'package:repair_ai/shared/widgets/repair_app_bar.dart';
import 'package:repair_ai/shared/widgets/responsive_page.dart';

class CareScreen extends ConsumerWidget {
  const CareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final feed = ref.watch(careFeedProvider);

    return Scaffold(
      appBar: RepairAppBar(title: l10n.careTab),
      body: feed.when(
        loading: () => const _CareLoadingBody(),
        error: (_, __) => _CareBody(
          state: _emptyState(ref),
          onRefresh: () => ref.refresh(careFeedProvider.future),
        ),
        data: (state) => RefreshIndicator(
          onRefresh: () => ref.refresh(careFeedProvider.future),
          child: _CareBody(state: state),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  CareFeedState _emptyState(WidgetRef ref) {
    return CareFeedState(
      connectionState: BackendConnectionState.offline,
      backendReports: const [],
      localReports: ref.watch(reportHistoryProvider),
      triageResults: const [],
      referrals: const [],
      followUps: const [],
      alerts: const [],
      prescriptions: const [],
      profileCompletion: const ProfileCompletionState(
        isComplete: false,
        missingFields: ['age', 'sub-county', 'LMP'],
      ),
    );
  }
}

class _CareBody extends StatelessWidget {
  const _CareBody({required this.state, this.onRefresh});

  final CareFeedState state;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isOffline = state.connectionState == BackendConnectionState.offline;

    return ListView(
      padding: RepairInsets.scroll(context),
      children: [
        ResponsivePageShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isOffline)
                _BackendStatusCard(
                  title: l10n.backendOfflineTitle,
                  message: l10n.backendOfflineMessage,
                  icon: Icons.cloud_off_outlined,
                )
              else
                _BackendStatusCard(
                  title: l10n.backendConnectedTitle,
                  message: l10n.backendConnectedMessage,
                  icon: Icons.cloud_done_outlined,
                ),
              const SizedBox(height: 12),
              if (state.notices.isNotEmpty) ...[
                _CareNoticeCard(messages: state.notices),
                const SizedBox(height: 12),
              ],
              if (!state.profileCompletion.isComplete)
                _ProfileCompletionCard(
                  state: state.profileCompletion,
                  onTap: () => context.push('/profile/complete-care'),
                ),
              if (!state.profileCompletion.isComplete)
                const SizedBox(height: 12),
              const _AncCareSection(),
              const SizedBox(height: 12),
              _CareSection(
                title: l10n.careReports,
                icon: Icons.fact_check_outlined,
                actionLabel: l10n.viewReportsTimeline,
                onAction: () => context.push('/history'),
                children: [
                  if (state.backendReports.isNotEmpty)
                    ...state.backendReports.take(2).map(_BackendReportTile.new)
                  else if (state.localReports.isNotEmpty)
                    ...state.localReports.reversed
                        .take(2)
                        .map(
                          (report) => _SimpleCareTile(
                            icon: Icons.medical_services_outlined,
                            title: report.riskLevel.toUpperCase(),
                            subtitle:
                                '${report.symptoms.length} symptoms • ${report.gestationalAge.toStringAsFixed(1)} weeks',
                            color: AppTheme.primary,
                          ),
                        )
                  else
                    _EmptyCareTile(message: l10n.noReportsYet),
                ],
              ),
              const SizedBox(height: 12),
              _CareSection(
                title: l10n.myReferrals,
                icon: Icons.local_hospital_outlined,
                actionLabel: l10n.findCareTitle,
                onAction: () => context.push('/referral'),
                children: [
                  if (state.referrals.isEmpty)
                    _EmptyCareTile(message: l10n.myReferralsSubtitle)
                  else
                    ...state.referrals
                        .take(2)
                        .map(
                          (item) => _SimpleCareTile(
                            icon: Icons.alt_route_outlined,
                            title: '${item['status'] ?? l10n.pending}',
                            subtitle:
                                '${item['facility_name'] ?? item['facility'] ?? l10n.recommendedFacility}',
                            color: AppTheme.primary,
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 12),
              _CareSection(
                title: l10n.careFollowUps,
                icon: Icons.event_available_outlined,
                children: [
                  if (state.followUps.isEmpty)
                    _EmptyCareTile(message: l10n.noFollowUpsYet)
                  else
                    ...state.followUps
                        .take(2)
                        .map(
                          (item) => _SimpleCareTile(
                            icon: Icons.schedule_outlined,
                            title: '${item['due_date'] ?? l10n.pending}',
                            subtitle: '${item['message_template'] ?? ''}',
                            color: AppTheme.warning,
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 12),
              _CareSection(
                title: l10n.carePrescriptions,
                icon: Icons.receipt_long_outlined,
                actionLabel: l10n.medicationTrackerTitle,
                onAction: () => context.push('/medication-tracking'),
                children: [
                  if (state.prescriptions.isEmpty)
                    _EmptyCareTile(message: l10n.noPrescriptionsYet)
                  else
                    ...state.prescriptions
                        .take(2)
                        .map(
                          (item) => _SimpleCareTile(
                            icon: Icons.medication_outlined,
                            title:
                                '${item['medication'] ?? l10n.carePrescriptions}',
                            subtitle: '${item['dosing_guidance'] ?? ''}',
                            color: AppTheme.success,
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 12),
              _CareSection(
                title: l10n.careAlerts,
                icon: Icons.notifications_active_outlined,
                children: [
                  if (state.alerts.isEmpty)
                    _EmptyCareTile(message: l10n.noAlertsYet)
                  else
                    ...state.alerts
                        .take(2)
                        .map(
                          (item) => _SimpleCareTile(
                            icon: Icons.warning_amber_outlined,
                            title: '${item['flag'] ?? l10n.careAlerts}',
                            subtitle: '${item['description'] ?? ''}',
                            color: AppTheme.error,
                          ),
                        ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AncCareSection extends ConsumerWidget {
  const _AncCareSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(ancProfileProvider('current-patient'));

    return profileAsync.when(
      loading: () => const _LoadingCareCard(label: 'Loading ANC profile...'),
      error: (_, __) => _CareSection(
        title: l10n.ancSpecialCases,
        icon: Icons.assignment_turned_in_outlined,
        actionLabel: 'Open',
        onAction: () => context.push('/care/anc-profile'),
        children: [_EmptyCareTile(message: l10n.ancProfileEmpty)],
      ),
      data: (profile) {
        final flags = profile?.contextFlags ?? const [];
        return _CareSection(
          title: l10n.ancSpecialCases,
          icon: Icons.assignment_turned_in_outlined,
          actionLabel: 'Open',
          onAction: () => context.push('/care/anc-profile'),
          children: [
            if (profile == null || profile.isEmpty)
              _EmptyCareTile(message: l10n.ancProfileEmpty)
            else if (flags.isNotEmpty)
              ...flags
                  .take(3)
                  .map(
                    (flag) => _SimpleCareTile(
                      icon: flag.severity.name == 'urgent'
                          ? Icons.warning_amber_outlined
                          : Icons.info_outline,
                      title: flag.label,
                      subtitle: flag.detail,
                      color: flag.severity.name == 'urgent'
                          ? AppTheme.error
                          : AppTheme.warning,
                    ),
                  )
            else
              _SimpleCareTile(
                icon: Icons.verified_outlined,
                title: l10n.ancProfileRecordedByCareTeam,
                subtitle: profile.nextAncAction.isEmpty
                    ? l10n.ancSpecialCasesSubtitle
                    : profile.nextAncAction,
                color: AppTheme.success,
              ),
          ],
        );
      },
    );
  }
}

class _CareLoadingBody extends StatelessWidget {
  const _CareLoadingBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: RepairInsets.scroll(context),
      children: const [
        ResponsivePageShell(
          child: Column(
            children: [
              _LoadingCareCard(label: 'Loading care dashboard...'),
              SizedBox(height: 12),
              _LoadingCareCard(label: 'Loading reports...'),
              SizedBox(height: 12),
              _LoadingCareCard(label: 'Loading referrals...'),
              SizedBox(height: 12),
              _LoadingCareCard(label: 'Loading follow-ups...'),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadingCareCard extends StatelessWidget {
  const _LoadingCareCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackendStatusCard extends StatelessWidget {
  const _BackendStatusCard({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.primary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Text(
                    message,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CareNoticeCard extends StatelessWidget {
  const _CareNoticeCard({required this.messages});

  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.tertiaryContainer.withValues(alpha: 0.72),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: scheme.onTertiaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                messages.join('\n'),
                style: TextStyle(
                  color: scheme.onTertiaryContainer,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCompletionCard extends StatelessWidget {
  const _ProfileCompletionCard({required this.state, required this.onTap});

  final ProfileCompletionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.assignment_ind_outlined,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.completeCareProfile,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.completeCareProfileSubtitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: state.missingFields
                  .take(4)
                  .map(
                    (field) => Chip(
                      label: Text(field),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.edit_note_outlined),
                label: const Text('Complete profile'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CareSection extends StatelessWidget {
  const _CareSection({
    required this.title,
    required this.icon,
    required this.children,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        final action = actionLabel != null && onAction != null
            ? TextButton(
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  maxLines: compact ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : null;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: AppTheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (!compact && action != null) action,
                  ],
                ),
                if (compact && action != null) ...[
                  const SizedBox(height: 6),
                  Align(alignment: Alignment.centerLeft, child: action),
                ],
                const SizedBox(height: 8),
                ...children,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BackendReportTile extends StatelessWidget {
  const _BackendReportTile(this.item);

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final triage = item['triage_summary'];
    final risk = triage is Map ? triage['risk_level'] : null;
    return _SimpleCareTile(
      icon: Icons.medical_services_outlined,
      title: '${risk ?? 'Visit recorded'}',
      subtitle: '${item['symptoms_raw'] ?? ''}',
      color: AppTheme.primary,
    );
  }
}

class _SimpleCareTile extends StatelessWidget {
  const _SimpleCareTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}

class _EmptyCareTile extends StatelessWidget {
  const _EmptyCareTile({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
