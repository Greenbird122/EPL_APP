import 'package:flutter/material.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/launch_helpers.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/shared/widgets/repair_card.dart';

class HomeSupportStrip extends StatelessWidget {
  const HomeSupportStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return RepairCard(
      elevation: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.support_agent, color: AppTheme.success),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.helpSupport,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(l10n.helpSupportSubtitle,
                        style: TextStyle(
                            color: scheme.onSurfaceVariant, height: 1.3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 1: Website + USSD
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: launchRepairAiWebsite,
                  icon: const Icon(Icons.language,
                      color: AppTheme.primary, size: 18),
                  label: Text(l10n.website,
                      style: const TextStyle(
                          color: AppTheme.primary, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppTheme.primary.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: launchUssdCode,
                  icon: const Icon(Icons.dialpad,
                      color: AppTheme.primary, size: 18),
                  label: const Text(kRepairAiUssdCode,
                      style: TextStyle(color: AppTheme.primary, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppTheme.primary.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          // Row 2: Phone Number + Mobile App
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: launchRepairAiVoiceAssistant,
                  icon: const Icon(Icons.phone,
                      color: AppTheme.success, size: 18),
                  label: Text(l10n.phone,
                      style: const TextStyle(
                          color: AppTheme.success, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppTheme.success.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 42,
                child: OutlinedButton.icon(
                  onPressed: launchRepairAiWebsite,
                  icon: const Icon(Icons.phone_android,
                      color: AppTheme.primary, size: 18),
                  label: Text(l10n.mobileApp,
                      style: const TextStyle(
                          color: AppTheme.primary, fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppTheme.primary.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
