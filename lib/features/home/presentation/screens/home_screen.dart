import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/launch_helpers.dart';
import 'package:repair_ai/core/utils/responsive.dart';
import 'package:repair_ai/features/auth/presentation/controllers/login_profile_providers.dart';
import 'package:repair_ai/features/auth/presentation/controllers/report_history_providers.dart';
import 'package:repair_ai/features/home/presentation/controllers/home_care_summary_provider.dart';
import 'package:repair_ai/features/home/presentation/widgets/care_compass_card.dart';
import 'package:repair_ai/features/home/presentation/widgets/care_signal_row.dart';
import 'package:repair_ai/features/home/presentation/widgets/home_connection_status_chip.dart';
import 'package:repair_ai/features/home/presentation/widgets/home_support_strip.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/localization/triage_l10n.dart';
import 'package:repair_ai/shared/widgets/bottom_nav.dart';
import 'package:repair_ai/shared/widgets/hero_image_stack.dart';
import 'package:repair_ai/shared/widgets/image_accent_card.dart';
import 'package:repair_ai/shared/widgets/language_toggle.dart';
import 'package:repair_ai/shared/widgets/repair_app_bar.dart';
import 'package:repair_ai/shared/widgets/responsive_page.dart';
import 'package:repair_ai/shared/widgets/theme_mode_toggle.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reports = ref.watch(reportHistoryProvider);
    final lastReport = reports.isNotEmpty ? reports.last : null;
    final summaryAsync = ref.watch(homeCareSummaryProvider);
    final summary = summaryAsync.valueOrNull;
    final profileName = ref.watch(profileNameProvider);
    final patientName = _firstName(
      summary?.name ?? profileName ?? l10n.careIdentityUnknown,
    );
    final storedRisk =
        lastReport == null ? null : l10n.riskFromStored(lastReport.riskLevel);
    final localRisk =
        storedRisk == null ? lastReport?.riskLevel : l10n.riskLabel(storedRisk);

    return Scaffold(
      appBar: RepairAppBar(
        title: l10n.appTitle,
        actions: const [
          ThemeModeToggle(),
          SizedBox(width: 6),
          Padding(padding: EdgeInsets.only(right: 8), child: LanguageToggle()),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: RepairInsets.scrollBottom(context)),
        child: ResponsivePageShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeHeroBanner(
                imageAsset: 'assets/illustrations/mother_2.jpg',
                topChild: const HomeConnectionStatusChip(),
                bottomChild: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.yourPregnancyMatters,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${l10n.reportSymptomsEarly} ${l10n.homeSupportChannelsSuffix}',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _PersonalizedHeader(
                  greeting: l10n.homeGreeting(patientName),
                  summary: summary,
                  loading: summaryAsync.isLoading,
                  hasLocalReport: lastReport != null,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CareCompassCard(
                  summary: summary,
                  hasLocalReport: lastReport != null,
                  localRiskLabel: localRisk,
                  onPrimaryAction: () => _handleCompassPrimary(
                      context, summary, lastReport != null),
                  onSecondaryAction: () =>
                      _handleCompassSecondary(context, summary),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: CareSignalRow(
                  summary: summary,
                  hasLocalReport: lastReport != null,
                  onTriage: () => context.push('/triage/symptom-report'),
                  onReferral: () => context.push('/referral'),
                  onCare: () => context.push('/care'),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _ReportSymptomsCard(
                  title: l10n.reportSymptoms,
                  subtitle: l10n.reportSymptomsSubtitle,
                  onTap: () => context.push('/triage/symptom-report'),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: HomeSupportStrip(),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _CompactNavCard(
                      title: l10n.careTab,
                      subtitle:
                          '${l10n.careReports} • ${l10n.careFollowUps} • ${l10n.carePrescriptions}',
                      icon: Icons.favorite_border,
                      onTap: () => context.push('/care'),
                    ),
                    const SizedBox(height: 12),
                    _CompactNavCard(
                      title: l10n.mentalHealthSupport,
                      subtitle: l10n.mentalHealthSubtitle,
                      icon: Icons.psychology,
                      onTap: () => context.push('/mental-health'),
                    ),
                    const SizedBox(height: 12),
                    _CompactNavCard(
                      title: l10n.nearestFacility,
                      subtitle: l10n.nearestFacilitySubtitle,
                      icon: Icons.local_hospital,
                      onTap: () => context.push('/referral'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  String _firstName(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'Mama';
    return clean.split(RegExp(r'\s+')).first;
  }

  void _handleCompassPrimary(
    BuildContext context,
    HomeCareSummary? summary,
    bool hasLocalReport,
  ) {
    final state = summary?.backendAvailable == true
        ? summary!.state
        : (hasLocalReport
            ? CareCompassState.checked
            : CareCompassState.offline);
    switch (state) {
      case CareCompassState.profileNeeded:
        context.push('/profile/complete-care');
        return;
      case CareCompassState.referralNeeded:
        context.push('/referral');
        return;
      case CareCompassState.checked:
      case CareCompassState.followUpPending:
      case CareCompassState.stable:
        context.push('/care');
        return;
      case CareCompassState.noCheck:
      case CareCompassState.offline:
        context.push('/triage/symptom-report');
        return;
    }
  }

  void _handleCompassSecondary(BuildContext context, HomeCareSummary? summary) {
    if (summary != null && !summary.backendAvailable) {
      launchUssdCode();
      return;
    }
    context.push('/care');
  }
}

class _PersonalizedHeader extends StatelessWidget {
  const _PersonalizedHeader({
    required this.greeting,
    required this.summary,
    required this.loading,
    required this.hasLocalReport,
  });

  final String greeting;
  final HomeCareSummary? summary;
  final bool loading;
  final bool hasLocalReport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _IdentityChip(
              icon: Icons.location_on_outlined,
              label: summary?.county ??
                  (loading ? l10n.careIdentityUnknown : l10n.locationNotSet),
              color: AppTheme.primary,
            ),
            _IdentityChip(
              icon: Icons.pregnant_woman,
              label: summary?.pregnancyWeeks == null
                  ? l10n.pregnancyWeek
                  : '${summary!.pregnancyWeeks!.toStringAsFixed(0)} ${l10n.weeksPregnantLabel}',
              color: AppTheme.accent,
            ),
            _IdentityChip(
              icon: hasLocalReport || summary?.hasRisk == true
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              label: hasLocalReport || summary?.hasRisk == true
                  ? l10n.todayCareSavedTitle
                  : l10n.noCheckYet,
              color: hasLocalReport || summary?.hasRisk == true
                  ? AppTheme.success
                  : AppTheme.primary,
            ),
          ],
        ),
      ],
    );
  }
}

class _IdentityChip extends StatelessWidget {
  const _IdentityChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportSymptomsCard extends StatelessWidget {
  const _ReportSymptomsCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ImageAccentCard(
      imageAsset: 'assets/illustrations/pregnant_mother.jpg',
      accentColor: AppTheme.primary,
      onTap: onTap,
      imageWidth: 104,
      imageFit: ImageAccentFit.visibleTop,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppTheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
}

class _CompactNavCard extends StatelessWidget {
  const _CompactNavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ImageAccentCard(
      imageAsset: switch (icon) {
        Icons.psychology => 'assets/illustrations/mental_health.jpg',
        Icons.favorite_border => 'assets/illustrations/mama.jpeg',
        _ => 'assets/illustrations/hospital.jpg',
      },
      accentColor: AppTheme.primary,
      imageWidth: 72,
      imageFit: ImageAccentFit.visibleTop,
      onTap: onTap,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, size: 36, color: AppTheme.primary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
