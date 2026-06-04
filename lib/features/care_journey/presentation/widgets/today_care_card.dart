import 'package:flutter/material.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/features/auth/presentation/controllers/report_history_providers.dart';
import 'package:repair_ai/features/care_journey/presentation/controllers/care_journey_provider.dart';
import 'package:repair_ai/features/referral/presentation/controllers/referral_state_provider.dart';
import 'package:repair_ai/features/triage/domain/triage_result.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/localization/triage_l10n.dart';
import 'package:repair_ai/shared/widgets/image_accent_card.dart';

class TodayCareCard extends StatelessWidget {
  const TodayCareCard({
    super.key,
    required this.latestReport,
    required this.referral,
    required this.followUpStatus,
    required this.onPrimaryAction,
    required this.onSecondaryAction,
  });

  final SymptomReport? latestReport;
  final ReferralState referral;
  final FollowUpStatus followUpStatus;
  final VoidCallback onPrimaryAction;
  final VoidCallback onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final hasReport = latestReport != null;
    final risk =
        hasReport ? l10n.riskFromStored(latestReport!.riskLevel) : null;
    final riskLabel =
        risk != null ? l10n.riskLabel(risk) : latestReport?.riskLevel;
    final title =
        hasReport ? l10n.todayCareSavedTitle : l10n.todayCareEmptyTitle;
    final message = _nextStepText(l10n, hasReport: hasReport);
    final primaryLabel = _primaryLabel(l10n, hasReport: hasReport);
    final iconColor = risk?.color ?? AppTheme.primary;

    return ImageAccentCard(
      imageAsset: hasReport
          ? 'assets/illustrations/mama.jpeg'
          : 'assets/illustrations/mother_2.jpg',
      accentColor: iconColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.favorite, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.todayCareTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CareMetric(
                icon: Icons.pregnant_woman,
                label: latestReport == null
                    ? l10n.pregnancyWeek
                    : '${latestReport!.gestationalAge.toStringAsFixed(0)} ${l10n.weeksPregnantLabel}',
              ),
              _CareMetric(
                icon: Icons.health_and_safety,
                label: riskLabel == null
                    ? l10n.noCheckYet
                    : '$riskLabel ${l10n.riskLevel.toLowerCase()}',
                color: iconColor,
              ),
              _CareMetric(
                icon: Icons.route,
                label: _referralLabel(l10n, referral.status),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: const TextStyle(fontSize: 15, height: 1.35),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onPrimaryAction,
                  icon: Icon(hasReport ? Icons.local_hospital : Icons.edit),
                  label: Text(primaryLabel),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: onSecondaryAction,
                child: Text(hasReport ? l10n.viewHistory : l10n.useUssd),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _primaryLabel(AppLocalizations l10n, {required bool hasReport}) {
    if (!hasReport) return l10n.reportSymptoms;
    if (followUpStatus == FollowUpStatus.needsHelp) return l10n.getHelp;
    if (referral.status == ReferralUiStatus.sent ||
        referral.status == ReferralUiStatus.accepted ||
        referral.status == ReferralUiStatus.recommended) {
      return l10n.followReferral;
    }
    return l10n.checkCare;
  }

  String _nextStepText(AppLocalizations l10n, {required bool hasReport}) {
    if (!hasReport) {
      return l10n.todayCareEmptyMessage;
    }
    if (followUpStatus == FollowUpStatus.reachedCare) {
      return l10n.todayCareReachedMessage;
    }
    if (followUpStatus == FollowUpStatus.needsHelp) {
      return l10n.todayCareNeedsHelpMessage;
    }
    if (referral.status == ReferralUiStatus.completed) {
      return l10n.todayCareCompletedMessage;
    }
    return l10n.todayCareDefaultMessage;
  }

  String _referralLabel(AppLocalizations l10n, ReferralUiStatus status) {
    return switch (status) {
      ReferralUiStatus.draft => l10n.referralDraft,
      ReferralUiStatus.recommended => l10n.careFound,
      ReferralUiStatus.sent => l10n.referralSentStatus,
      ReferralUiStatus.accepted => l10n.accepted,
      ReferralUiStatus.completed => l10n.completed,
      ReferralUiStatus.cancelled => l10n.cancelled,
    };
  }
}

class _CareMetric extends StatelessWidget {
  const _CareMetric({
    required this.icon,
    required this.label,
    this.color = AppTheme.primary,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
