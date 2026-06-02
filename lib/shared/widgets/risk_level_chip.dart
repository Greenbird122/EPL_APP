import 'package:flutter/material.dart';
import 'package:repair_ai/features/triage/domain/triage_result.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/localization/triage_l10n.dart';

class RiskLevelChip extends StatelessWidget {
  const RiskLevelChip({super.key, required this.level});

  final RiskLevel level;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = l10n.riskLabel(level);

    return Semantics(
      label: 'Risk level $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: level.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: level.color, width: 1.5),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: level.color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
