import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/launch_helpers.dart';
import 'package:repair_ai/localization/app_localizations.dart';

class UssdAccessCard extends StatelessWidget {
  const UssdAccessCard({
    super.key,
    this.compact = false,
  });

  final bool compact;

  Future<void> _dial(BuildContext context) async {
    final launched = await launchUssdCode();
    if (launched || !context.mounted) return;
    await Clipboard.setData(const ClipboardData(text: kRepairAiUssdCode));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).ussdCopied),
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: kRepairAiUssdCode));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).ussdCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: compact ? 2 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 14),
        child: Row(
          children: [
            Container(
              width: compact ? 44 : 52,
              height: compact ? 44 : 52,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.dialpad, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.useUssdTitle,
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    kRepairAiUssdCode,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  if (!compact)
                    Text(
                      l10n.useUssdSubtitle,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _copy(context),
              icon: const Icon(Icons.copy),
              tooltip: l10n.copyUssdCode,
            ),
            IconButton(
              onPressed: () => _dial(context),
              icon: const Icon(Icons.phone),
              tooltip: l10n.dialUssd,
            ),
          ],
        ),
      ),
    );
  }
}
