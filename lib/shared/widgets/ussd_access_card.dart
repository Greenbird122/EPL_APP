import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/launch_helpers.dart';
import 'package:repair_ai/core/utils/responsive.dart';
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
    final narrow = MediaQuery.sizeOf(context).width < 360;
    final iconSize = RepairSizing.supportVisualSize(context, compact: compact);

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
              width: iconSize,
              height: iconSize,
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
            if (narrow)
              PopupMenuButton<String>(
                tooltip: l10n.quickActions,
                onSelected: (value) {
                  if (value == 'copy') _copy(context);
                  if (value == 'dial') _dial(context);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'copy', child: Text(l10n.copyUssdCode)),
                  PopupMenuItem(value: 'dial', child: Text(l10n.dialUssd)),
                ],
              )
            else ...[
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
          ],
        ),
      ),
    );
  }
}
