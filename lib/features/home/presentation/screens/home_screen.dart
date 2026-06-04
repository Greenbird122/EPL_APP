import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/launch_helpers.dart';
import 'package:repair_ai/features/auth/presentation/controllers/report_history_providers.dart';
import 'package:repair_ai/features/care_journey/presentation/controllers/care_journey_provider.dart';
import 'package:repair_ai/features/care_journey/presentation/widgets/care_support_block.dart';
import 'package:repair_ai/features/care_journey/presentation/widgets/care_timeline.dart';
import 'package:repair_ai/features/care_journey/presentation/widgets/today_care_card.dart';
import 'package:repair_ai/features/referral/presentation/controllers/referral_state_provider.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/shared/widgets/bottom_nav.dart';
import 'package:repair_ai/shared/widgets/demo_disclaimer_banner.dart';
import 'package:repair_ai/shared/widgets/hero_image_stack.dart';
import 'package:repair_ai/shared/widgets/image_accent_card.dart';
import 'package:repair_ai/shared/widgets/language_toggle.dart';
import 'package:repair_ai/shared/widgets/repair_app_bar.dart';
import 'package:repair_ai/shared/widgets/theme_mode_toggle.dart';
import 'package:repair_ai/shared/widgets/ussd_access_card.dart';
import 'package:repair_ai/shared/widgets/whatsapp_support_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reports = ref.watch(reportHistoryProvider);
    final lastReport = reports.isNotEmpty ? reports.last : null;
    final referral = ref.watch(referralStateProvider);
    final followUpStatus = ref.watch(careJourneyProvider);

    return Scaffold(
      appBar: RepairAppBar(
        title: l10n.appTitle,
        actions: const [
          ThemeModeToggle(),
          SizedBox(width: 6),
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: LanguageToggle(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 88),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeHeroBanner(
              imageAsset: 'assets/illustrations/mother_2.jpg',
              topChild: Chip(
                avatar: const Icon(
                  Icons.cloud_off,
                  size: 16,
                  color: Colors.white,
                ),
                label: Text(
                  l10n.worksOffline,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                backgroundColor: Colors.white24,
              ),
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
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: DemoDisclaimerBanner(compact: true),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TodayCareCard(
                latestReport: lastReport,
                referral: referral,
                followUpStatus: followUpStatus,
                onPrimaryAction: () => lastReport == null
                    ? context.push('/triage/symptom-report')
                    : context.push('/referral'),
                onSecondaryAction: () => lastReport == null
                    ? launchUssdCode()
                    : context.push('/history'),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CareTimeline(
                latestReport: lastReport,
                referral: referral,
                followUpStatus: followUpStatus,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _HomeActionCard(
                      title: l10n.myReports,
                      subtitle: l10n.myReportsSubtitle,
                      icon: Icons.history,
                      color: Colors.teal,
                      onTap: () => context.push('/history'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HomeActionCard(
                      title: l10n.myReferrals,
                      subtitle: l10n.myReferralsSubtitle,
                      icon: Icons.local_hospital_rounded,
                      color: AppTheme.primary,
                      onTap: () => context.push('/referral'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: WhatsAppSupportCard(),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: UssdAccessCard(),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: CareSupportBlock(compact: true),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
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
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
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

class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ImageAccentCard(
      imageAsset: icon == Icons.history
          ? 'assets/illustrations/mother_2.jpg'
          : 'assets/illustrations/hospital.jpg',
      accentColor: color,
      imageWidth: 58,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 36, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
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
      imageAsset: icon == Icons.psychology
          ? 'assets/illustrations/mental_health.jpg'
          : 'assets/illustrations/hospital.jpg',
      accentColor: AppTheme.primary,
      imageWidth: 72,
      onTap: onTap,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, size: 36, color: AppTheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
