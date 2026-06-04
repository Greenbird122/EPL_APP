import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/launch_helpers.dart';
import 'package:repair_ai/features/care_journey/presentation/widgets/care_support_block.dart';
import 'package:repair_ai/features/care_journey/presentation/widgets/follow_up_prompt.dart';
import 'package:repair_ai/features/referral/presentation/controllers/referral_state_provider.dart';
import 'package:repair_ai/features/triage/application/triage_controller.dart';
import 'package:repair_ai/features/triage/domain/triage_result.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/shared/widgets/bottom_nav.dart';
import 'package:repair_ai/shared/widgets/demo_disclaimer_banner.dart';
import 'package:repair_ai/shared/widgets/repair_app_bar.dart';
import 'package:repair_ai/shared/widgets/repair_buttons.dart';
import 'package:repair_ai/shared/widgets/ussd_access_card.dart';

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final result = ref.watch(triageResultProvider);
    final referral = ref.watch(referralStateProvider);
    final selected = facilityOptions[referral.selectedFacility];
    final isUrgent = result?.riskLevel == RiskLevel.high;

    return Scaffold(
      appBar: RepairAppBar(
        title: l10n.findCareTitle,
        showDemoChip: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DemoDisclaimerBanner(compact: true),
            const SizedBox(height: 12),
            if (isUrgent)
              _UrgentReferralBanner(
                text: l10n.goNowUrgency,
                onCall: launchEmergencyCall,
              ),
            _ReferralStatusCard(
              status: referral.status,
              facilityName: selected.name,
              l10n: l10n,
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: launchFacilityMaps,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                  image: const DecorationImage(
                    image: AssetImage('assets/illustrations/hospital.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Color(0x77000000),
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.map, size: 42, color: Colors.white),
                      const SizedBox(height: 8),
                      Text(
                        l10n.openFacilityDirections,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.recommendedFacility,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            ...facilityOptions.asMap().entries.map(
                  (entry) => _FacilityCard(
                    facility: entry.value,
                    selected: entry.key == referral.selectedFacility,
                    onTap: () => ref
                        .read(referralStateProvider.notifier)
                        .selectFacility(entry.key),
                  ),
                ),
            const SizedBox(height: 18),
            _ActionGrid(
              onCallFacility: launchEmergencyCall,
              onMaps: launchFacilityMaps,
              onWhatsApp: () => launchWhatsAppHelp(context),
              onTransport: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.transportRequestQueued),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const UssdAccessCard(compact: true),
            const SizedBox(height: 12),
            const FollowUpPrompt(compact: true),
            const SizedBox(height: 12),
            const CareSupportBlock(compact: true),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: RepairOutlinedButton(
                    label: l10n.triageBack,
                    onPressed: () => context.pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RepairPrimaryButton(
                    label: _primaryLabel(l10n, referral.status),
                    icon: Icons.send,
                    onPressed: () => _advanceReferral(context, ref),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: () => context.push('/history'),
              icon: const Icon(Icons.timeline),
              label: Text(l10n.viewReportsTimeline),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }

  String _primaryLabel(AppLocalizations l10n, ReferralUiStatus status) {
    switch (status) {
      case ReferralUiStatus.sent:
        return l10n.markAccepted;
      case ReferralUiStatus.accepted:
        return l10n.markCompleted;
      case ReferralUiStatus.completed:
        return l10n.completed;
      case ReferralUiStatus.cancelled:
        return l10n.restartReferral;
      case ReferralUiStatus.draft:
      case ReferralUiStatus.recommended:
        return l10n.sendReferral;
    }
  }

  void _advanceReferral(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(referralStateProvider.notifier);
    final status = ref.read(referralStateProvider).status;
    switch (status) {
      case ReferralUiStatus.sent:
        notifier.accept();
        break;
      case ReferralUiStatus.accepted:
        notifier.complete();
        break;
      case ReferralUiStatus.completed:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.referralAlreadyCompleted)),
        );
        return;
      case ReferralUiStatus.cancelled:
      case ReferralUiStatus.draft:
      case ReferralUiStatus.recommended:
        notifier.send();
        break;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.referralStatusUpdated)),
    );
  }
}

class _UrgentReferralBanner extends StatelessWidget {
  const _UrgentReferralBanner({required this.text, required this.onCall});

  final String text;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.12),
        border: Border.all(color: AppTheme.error),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.priority_high, color: AppTheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.error,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: onCall,
            icon: const Icon(Icons.phone, color: AppTheme.error),
            tooltip: AppLocalizations.of(context).callEmergency,
          ),
        ],
      ),
    );
  }
}

class _ReferralStatusCard extends StatelessWidget {
  const _ReferralStatusCard({
    required this.status,
    required this.facilityName,
    required this.l10n,
  });

  final ReferralUiStatus status;
  final String facilityName;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ReferralUiStatus.sent => AppTheme.warning,
      ReferralUiStatus.accepted => AppTheme.primary,
      ReferralUiStatus.completed => AppTheme.success,
      ReferralUiStatus.cancelled => AppTheme.error,
      _ => AppTheme.primary,
    };
    final label = switch (status) {
      ReferralUiStatus.draft => l10n.referralDraft,
      ReferralUiStatus.recommended => l10n.facilityRecommended,
      ReferralUiStatus.sent => l10n.referralSentStatus,
      ReferralUiStatus.accepted => l10n.facilityAccepted,
      ReferralUiStatus.completed => l10n.careCompleted,
      ReferralUiStatus.cancelled => l10n.referralCancelled,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.16),
              child: Icon(Icons.route, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    facilityName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _FacilityCard extends StatelessWidget {
  const _FacilityCard({
    required this.facility,
    required this.selected,
    required this.onTap,
  });

  final FacilityOption facility;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppTheme.primary : Colors.transparent,
          width: selected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          facility.isRecommended
              ? Icons.local_hospital
              : Icons.local_hospital_outlined,
          color: selected ? AppTheme.primary : null,
        ),
        title: Text(
          facility.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${facility.distance} • ${facility.eta} • ${facility.capabilities.join(' • ')}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: selected
            ? const Icon(Icons.check_circle, color: AppTheme.primary)
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({
    required this.onCallFacility,
    required this.onMaps,
    required this.onWhatsApp,
    required this.onTransport,
  });

  final VoidCallback onCallFacility;
  final VoidCallback onMaps;
  final VoidCallback onWhatsApp;
  final VoidCallback onTransport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.25,
      children: [
        _ActionTile(Icons.phone, l10n.callEmergency, onCallFacility),
        _ActionTile(Icons.directions, l10n.openInMaps, onMaps),
        _ActionTile(Icons.chat, 'WhatsApp', onWhatsApp),
        _ActionTile(Icons.local_taxi, l10n.transport, onTransport),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
