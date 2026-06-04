import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/launch_helpers.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/shared/widgets/repair_app_bar.dart';
import 'package:repair_ai/shared/widgets/trust_chips_row.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class HowItWorksScreen extends ConsumerStatefulWidget {
  const HowItWorksScreen({super.key});

  @override
  ConsumerState<HowItWorksScreen> createState() => _HowItWorksScreenState();
}

class _HowItWorksScreenState extends ConsumerState<HowItWorksScreen> {
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_StepData> _steps(AppLocalizations l10n) => [
        _StepData(
            '01', l10n.step01Title, l10n.step01Description, Icons.person_add),
        _StepData('02', l10n.step02Title, l10n.step02Description,
            Icons.medical_services),
        _StepData(
            '03', l10n.step03Title, l10n.step03Description, Icons.auto_awesome),
        _StepData('04', l10n.step04Title, l10n.step04Description,
            Icons.local_hospital),
      ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = _steps(l10n);

    return Scaffold(
      appBar: RepairAppBar(title: l10n.howItWorksTitle, showDemoChip: true),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.smartCareTagline,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.howItWorksSubtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                const TrustChipsRow(),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: steps.length,
              itemBuilder: (context, index) {
                final step = steps[index];
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor:
                                AppTheme.primary.withValues(alpha: 0.15),
                            child: Text(
                              step.number,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Icon(step.icon, size: 48, color: AppTheme.primary),
                          const SizedBox(height: 16),
                          Text(
                            step.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            step.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SmoothPageIndicator(
            controller: _controller,
            count: steps.length,
            effect: const WormEffect(
              dotHeight: 8,
              dotWidth: 8,
              activeDotColor: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(l10n.getStartedButton),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
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
