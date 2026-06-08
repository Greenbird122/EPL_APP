import 'package:flutter/material.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/localization/app_localizations.dart';

class MotherlyQuoteCard extends StatelessWidget {
  const MotherlyQuoteCard({super.key, required this.quote, this.author});

  final String quote;
  final String? author;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite,
              color: AppTheme.primary.withValues(alpha: 0.85),
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              quote,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                height: 1.45,
                fontStyle: FontStyle.italic,
                color: scheme.onSurface,
              ),
            ),
            if (author != null) ...[
              const SizedBox(height: 10),
              Text(
                author!,
                style: TextStyle(
                  fontSize: 13,
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static List<String> quotesFor(AppLocalizations l10n) => [
    l10n.motherQuote1,
    l10n.motherQuote2,
    l10n.motherQuote3,
  ];
}
