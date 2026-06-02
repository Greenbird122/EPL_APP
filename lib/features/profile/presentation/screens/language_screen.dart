import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/shared/widgets/repair_app_bar.dart';

import '../../../../../../features/auth/presentation/controllers/language_providers.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(languageProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: RepairAppBar(
        title: l10n.language,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _LanguageTile(
              title: l10n.languageEnglish,
              subtitle: l10n.languageEnglish,
              selected: current == AppLanguage.en,
              onTap: () async {
                await ref
                    .read(languageProvider.notifier)
                    .setLanguage(AppLanguage.en);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.languageChangedEn)),
                  );
                }
              },
            ),
            _LanguageTile(
              title: l10n.languageSwahili,
              subtitle: l10n.languageSwahili,
              selected: current == AppLanguage.sw,
              onTap: () async {
                await ref
                    .read(languageProvider.notifier)
                    .setLanguage(AppLanguage.sw);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.languageChangedSw)),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: selected
          ? const Icon(Icons.check_circle, color: Colors.green)
          : null,
      onTap: onTap,
    );
  }
}
