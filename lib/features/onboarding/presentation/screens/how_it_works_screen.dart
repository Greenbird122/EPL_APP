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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _RepairAiMark(compact: compact),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          l10n.smartCareTagline,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: AppTheme.primary,
                                    height: 1.1,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
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
                  _HowItWorksTimeline(steps: steps),
                  SizedBox(height: compact ? 12 : 18),
                  ElevatedButton(
                    onPressed: () => context.go('/auth'),
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
                    onPressed: () => context.go('/auth'),
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

class _RepairAiMark extends StatelessWidget {
  const _RepairAiMark({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 58.0 : 68.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.2),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.asset(
          'assets/icons/repair_ai_logo_splash.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => ColoredBox(
            color: AppTheme.primary.withValues(alpha: 0.14),
            child: const Icon(Icons.auto_awesome, color: AppTheme.primary),
          ),
        ),
      ),
    );
  }
}

class _HowItWorksTimeline extends StatelessWidget {
  const _HowItWorksTimeline({required this.steps});

  final List<_StepData> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _HowStepCard(
            step: steps[i],
            isFirst: i == 0,
            isLast: i == steps.length - 1,
          ),
      ],
    );
  }
}

class _HowStepCard extends StatelessWidget {
  const _HowStepCard({
    required this.step,
    required this.isFirst,
    required this.isLast,
  });

  final _StepData step;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 52,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst
                        ? Colors.transparent
                        : AppTheme.primary.withValues(alpha: 0.18),
                  ),
                ),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.22),
                        blurRadius: 14,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Icon(step.icon, color: Colors.white, size: 22),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast
                        ? Colors.transparent
                        : AppTheme.primary.withValues(alpha: 0.18),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.number,
                          style: TextStyle(
                            color: AppTheme.primary.withValues(alpha: 0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            step.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
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
            ),
          ),
        ],
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
