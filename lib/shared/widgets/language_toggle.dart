import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/features/auth/presentation/controllers/language_providers.dart';

class LanguageToggle extends ConsumerWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(languageProvider);

    return PopupMenuButton<AppLanguage>(
      tooltip: 'Language',
      onSelected: (language) =>
          ref.read(languageProvider.notifier).setLanguage(language),
      itemBuilder: (context) => AppLanguage.values
          .map(
            (language) => PopupMenuItem(
              value: language,
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      language.shortLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(child: Text(language.displayName)),
                  if (language == current)
                    const Icon(Icons.check, color: AppTheme.primary),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              current.shortLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.expand_more, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
