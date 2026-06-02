import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/launch_helpers.dart';
import 'package:repair_ai/features/triage/application/triage_controller.dart';
import 'package:repair_ai/features/triage/domain/triage_result.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/shared/widgets/bottom_nav.dart';
import 'package:repair_ai/shared/widgets/demo_disclaimer_banner.dart';
import 'package:repair_ai/shared/widgets/repair_app_bar.dart';
import 'package:repair_ai/shared/widgets/repair_buttons.dart';

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  void _showSuccess(BuildContext context, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: AppTheme.success, size: 48),
        title: Text(l10n.referralSuccessTitle),
        content: Text(l10n.referralSuccessMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push('/history');
            },
            child: Text(l10n.viewHistory),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final result = ref.watch(triageResultProvider);
    final isUrgent = result?.riskLevel == RiskLevel.high;
    final urgencyLabel = isUrgent ? l10n.goNowUrgency : l10n.within24Hours;

    return Scaffold(
      appBar: RepairAppBar(
        title: l10n.smartReferrals,
        showDemoChip: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DemoDisclaimerBanner(compact: true),
            const SizedBox(height: 12),
            if (isUrgent)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.error),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.priority_high, color: AppTheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        urgencyLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            InkWell(
              onTap: launchFacilityMaps,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                  image: const DecorationImage(
                    image: AssetImage('assets/illustrations/hospital.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Color(0x66000000),
                      BlendMode.darken,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: Colors.white70),
                    const SizedBox(height: 8),
                    Text(
                      l10n.mapPlaceholder,
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.openInMaps,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isUrgent) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: launchEmergencyCall,
                  icon: const Icon(Icons.phone, color: AppTheme.error),
                  label: Text(
                    l10n.callEmergency,
                    style: const TextStyle(color: AppTheme.error),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(
              l10n.recommendedFacility,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.local_hospital,
                      size: 70,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.referralHospitalName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      l10n.facilityDistance,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoChip(
                          icon: Icons.access_time,
                          label: l10n.facilityChip247,
                        ),
                        _InfoChip(
                          icon: Icons.medical_services,
                          label: l10n.facilityChipUltrasound,
                        ),
                        _InfoChip(
                          icon: Icons.bloodtype,
                          label: l10n.facilityChipBloodBank,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.otherNearbyOptions,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...List.generate(2, (index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(
                    Icons.local_hospital_outlined,
                    color: AppTheme.primary,
                  ),
                  title: Text('${l10n.facilitySecondary} ${index + 2}'),
                  subtitle: Text(l10n.facilityDistanceSample),
                  trailing: OutlinedButton(
                    onPressed: launchFacilityMaps,
                    child: Text(l10n.openInMaps),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
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
                    label: l10n.sendReferral,
                    icon: Icons.send,
                    onPressed: () => _showSuccess(context, l10n),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primary),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
