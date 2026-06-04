import 'package:flutter/material.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/features/auth/presentation/controllers/report_history_providers.dart';
import 'package:repair_ai/features/care_journey/presentation/controllers/care_journey_provider.dart';
import 'package:repair_ai/features/referral/presentation/controllers/referral_state_provider.dart';
import 'package:repair_ai/features/triage/domain/triage_result.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/localization/triage_l10n.dart';
import 'package:repair_ai/shared/widgets/repair_card.dart';

class CareTimeline extends StatelessWidget {
  const CareTimeline({
    super.key,
    required this.latestReport,
    required this.referral,
    required this.followUpStatus,
  });

  final SymptomReport? latestReport;
  final ReferralState referral;
  final FollowUpStatus followUpStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = _steps(context);

    return RepairCard(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.careTimelineTitle,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          ),
          const SizedBox(height: 4),
          Text(
            steps.isEmpty
                ? l10n.careTimelineEmptyMessage
                : l10n.careTimelineSavedMessage,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          if (steps.isEmpty)
            _TimelineRow(
              icon: Icons.favorite_border,
              title: l10n.noCareStepsYet,
              subtitle: l10n.startWithSymptomCheck,
              isLast: true,
            )
          else
            ...steps.asMap().entries.map(
                  (entry) => _TimelineRow(
                    icon: entry.value.icon,
                    title: entry.value.title,
                    subtitle: entry.value.subtitle,
                    color: entry.value.color,
                    isLast: entry.key == steps.length - 1,
                  ),
                ),
        ],
      ),
    );
  }

  List<_TimelineStep> _steps(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <_TimelineStep>[];
    if (latestReport != null) {
      final risk = l10n.riskFromStored(latestReport!.riskLevel);
      final riskLabel =
          risk != null ? l10n.riskLabel(risk) : latestReport!.riskLevel;
      items.add(
        _TimelineStep(
          icon: Icons.assignment_turned_in,
          title: l10n.symptomCheckSaved,
          subtitle:
              '$riskLabel ${l10n.riskLevel.toLowerCase()} • ${latestReport!.gestationalAge.toStringAsFixed(0)} ${l10n.weeksPregnantLabel}',
          color: risk?.color ?? AppTheme.primary,
        ),
      );
    }
    if (latestReport != null) {
      items.add(
        _TimelineStep(
          icon: Icons.local_hospital,
          title: _referralTitle(l10n, referral.status),
          subtitle: l10n.facilityReadyFindCare,
          color: _referralColor(referral.status),
        ),
      );
    }
    if (followUpStatus != FollowUpStatus.unknown) {
      items.add(
        _TimelineStep(
          icon: Icons.favorite,
          title: _followUpTitle(l10n, followUpStatus),
          subtitle: _followUpSubtitle(l10n, followUpStatus),
          color: _followUpColor(followUpStatus),
        ),
      );
    }
    return items;
  }

  String _referralTitle(AppLocalizations l10n, ReferralUiStatus status) {
    return switch (status) {
      ReferralUiStatus.draft => l10n.referralDrafted,
      ReferralUiStatus.recommended => l10n.facilityRecommended,
      ReferralUiStatus.sent => l10n.referralSentStatus,
      ReferralUiStatus.accepted => l10n.facilityAccepted,
      ReferralUiStatus.completed => l10n.careCompleted,
      ReferralUiStatus.cancelled => l10n.referralCancelled,
    };
  }

  Color _referralColor(ReferralUiStatus status) {
    return switch (status) {
      ReferralUiStatus.sent => AppTheme.warning,
      ReferralUiStatus.accepted => AppTheme.primary,
      ReferralUiStatus.completed => AppTheme.success,
      ReferralUiStatus.cancelled => AppTheme.error,
      _ => AppTheme.primary,
    };
  }

  String _followUpTitle(AppLocalizations l10n, FollowUpStatus status) {
    return switch (status) {
      FollowUpStatus.reachedCare => l10n.reachedCare,
      FollowUpStatus.notYet => l10n.careNotReachedYet,
      FollowUpStatus.needsHelp => l10n.helpRequested,
      FollowUpStatus.unknown => '',
    };
  }

  String _followUpSubtitle(AppLocalizations l10n, FollowUpStatus status) {
    return switch (status) {
      FollowUpStatus.reachedCare => l10n.journeyMarkedFollowedUp,
      FollowUpStatus.notYet => l10n.keepReferralClose,
      FollowUpStatus.needsHelp => l10n.supportChannelsReady,
      FollowUpStatus.unknown => '',
    };
  }

  Color _followUpColor(FollowUpStatus status) {
    return switch (status) {
      FollowUpStatus.reachedCare => AppTheme.success,
      FollowUpStatus.notYet => AppTheme.warning,
      FollowUpStatus.needsHelp => AppTheme.error,
      FollowUpStatus.unknown => AppTheme.primary,
    };
  }
}

class _TimelineStep {
  const _TimelineStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color = AppTheme.primary,
    required this.isLast,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: color.withValues(alpha: 0.13),
              child: Icon(icon, size: 18, color: color),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 34,
                color: color.withValues(alpha: 0.2),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
