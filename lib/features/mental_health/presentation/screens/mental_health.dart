import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/app_error_handler.dart';
import 'package:repair_ai/core/utils/launch_helpers.dart';
import 'package:repair_ai/core/utils/responsive.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/shared/widgets/repair_app_bar.dart';

class MentalHealthScreen extends ConsumerStatefulWidget {
  const MentalHealthScreen({super.key});

  @override
  ConsumerState<MentalHealthScreen> createState() => _MentalHealthScreenState();
}

class _MentalHealthScreenState extends ConsumerState<MentalHealthScreen> {
  String? selectedFeelingKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final compact = RepairBreakpoints.isCompactPhone(context);

    final feelings = [
      {
        'emoji': '😊',
        'key': 'good',
        'label': l10n.feelingGood,
        'color': Colors.green,
      },
      {
        'emoji': '😐',
        'key': 'okay',
        'label': l10n.feelingOkay,
        'color': Colors.orange,
      },
      {
        'emoji': '😔',
        'key': 'sad',
        'label': l10n.feelingSad,
        'color': Colors.blue,
      },
      {
        'emoji': '😢',
        'key': 'very_sad',
        'label': l10n.feelingVerySad,
        'color': AppTheme.primary,
      },
      {
        'emoji': '😟',
        'key': 'anxious',
        'label': l10n.feelingAnxious,
        'color': AppTheme.error,
      },
    ];

    return Scaffold(
      appBar: RepairAppBar(title: l10n.mentalHealthSupport),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: compact ? 120 : 150,
                width: double.infinity,
                child: Image.asset(
                  'assets/illustrations/mental_health.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => ColoredBox(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.psychology,
                      color: AppTheme.primary,
                      size: 42,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.howAreYouFeeling,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.feelingsMatter,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            Card(
              color: AppTheme.error.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.support_agent, color: AppTheme.error),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'If you feel unsafe, overwhelmed, or at risk of harming yourself, contact emergency support or a trusted provider now.',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: feelings.length,
              itemBuilder: (context, index) {
                final feeling = feelings[index];
                final key = feeling['key'] as String;
                final isSelected = selectedFeelingKey == key;

                return GestureDetector(
                  onTap: () => setState(() => selectedFeelingKey = key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: isSelected
                          ? (feeling['color'] as Color).withValues(alpha: 0.12)
                          : AppTheme.surfaceTinted,
                      border: Border.all(
                        color: isSelected
                            ? feeling['color'] as Color
                            : AppTheme.primary.withValues(alpha: 0.1),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: (feeling['color'] as Color)
                                    .withValues(alpha: 0.18),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            feeling['emoji'] as String,
                            style: TextStyle(
                              fontSize: isSelected ? 46 : 38,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            feeling['label'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? feeling['color'] as Color
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                              fontSize: RepairSizing.textScale(context, 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            if (selectedFeelingKey != null)
              Card(
                color: AppTheme.primary.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.thankYouForSharing,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.feelingGuidance,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      if (selectedFeelingKey == 'very_sad' ||
                          selectedFeelingKey == 'anxious') ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Recommended: talk to a counselor or community health provider today.',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => launchWhatsAppHelp(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(l10n.talkToCounselor),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                showAppErrorSnackBar(
                                  context,
                                  l10n.supportGroupComingSoon,
                                );
                              },
                              child: Text(l10n.joinSupportGroup),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
