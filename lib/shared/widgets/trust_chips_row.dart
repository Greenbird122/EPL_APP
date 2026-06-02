import 'package:flutter/material.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class TrustChipsRow extends StatelessWidget {
  const TrustChipsRow({super.key, this.wrapWebsiteLink = true});

  final bool wrapWebsiteLink;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(context, l10n.featureAiTriage, isDark),
        _chip(context, l10n.worksOffline, isDark),
        _chip(context, l10n.explainableAI, isDark),
        if (wrapWebsiteLink)
          ActionChip(
            label: Text(l10n.fullPlatform),
            avatar: const Icon(Icons.open_in_new, size: 16),
            onPressed: () => launchUrl(
              Uri.parse('https://repairai.co.ke/'),
              mode: LaunchMode.externalApplication,
            ),
            backgroundColor: AppTheme.primary.withValues(alpha: isDark ? 0.25 : 0.12),
            labelStyle: TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  Widget _chip(BuildContext context, String label, bool isDark) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: isDark
          ? AppTheme.primary.withValues(alpha: 0.2)
          : AppTheme.primary.withValues(alpha: 0.08),
      side: BorderSide(
        color: AppTheme.primary.withValues(alpha: 0.3),
      ),
      labelStyle: TextStyle(
        color: isDark ? Colors.white70 : AppTheme.primary,
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
    );
  }
}

class ImpactStatsRow extends StatelessWidget {
  const ImpactStatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.platformImpactTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _stat(context, '68%', l10n.statReferralTime)),
            const SizedBox(width: 8),
            Expanded(child: _stat(context, '43%', l10n.statAncAttendance)),
            const SizedBox(width: 8),
            Expanded(child: _stat(context, '91%', l10n.statHighRiskDetected)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.platformImpactSource,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
        ),
      ],
    );
  }

  Widget _stat(BuildContext context, String value, String label) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                height: 1.2,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
