import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/launch_helpers.dart';
import 'package:repair_ai/core/utils/responsive.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/shared/widgets/repair_app_bar.dart';
import 'package:repair_ai/shared/widgets/responsive_page.dart';
import 'package:repair_ai/shared/widgets/trust_chips_row.dart';

class HowItWorksScreen extends ConsumerWidget {
  const HowItWorksScreen({super.key});

  List<_StepData> _steps(AppLocalizations l10n) => [
        _StepData(
          '01',
          l10n.step01Title,
          l10n.step01Description,
          Icons.person_add_alt_1_outlined,
        ),
        _StepData(
          '02',
          l10n.step02Title,
          l10n.step02Description,
          Icons.health_and_safety_outlined,
        ),
        _StepData(
          '03',
          l10n.step03Title,
          l10n.step03Description,
          Icons.auto_awesome_outlined,
        ),
        _StepData(
          '04',
          l10n.step04Title,
          l10n.step04Description,
          Icons.local_hospital_outlined,
        ),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final steps = _steps(l10n);
    final compact = RepairBreakpoints.isCompactPhone(context);

    return Scaffold(
      appBar: RepairAppBar(title: l10n.howItWorksTitle),
      body: SafeArea(
        child: ListView(
          padding: RepairInsets.scroll(context),
          children: [
            ResponsivePageShell(
              maxWidth: RepairSizing.formMaxWidth(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.smartCareTagline,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primary,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.howItWorksSubtitle,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.42,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const TrustChipsRow(),
                  SizedBox(height: compact ? 14 : 18),
                  ...steps.map(_HowStepCard.new),
                  SizedBox(height: compact ? 12 : 18),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(l10n.getStartedButton),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: launchRepairAiWebsite,
                    child: Text(l10n.learnMoreWebsite),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(l10n.skip),
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

class _HowStepCard extends StatelessWidget {
  const _HowStepCard(this.step);

  final _StepData step;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(step.icon, color: AppTheme.primary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${step.number}  ${step.title}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    step.description,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      height: 1.38,
                      fontWeight: FontWeight.w500,
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

class _StepData {
  const _StepData(this.number, this.title, this.description, this.icon);

  final String number;
  final String title;
  final String description;
  final IconData icon;
}
