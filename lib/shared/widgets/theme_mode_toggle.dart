import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_ai/core/config/theme_mode_provider.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/localization/app_localizations.dart';

class ThemeModeToggle extends ConsumerWidget {
  const ThemeModeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appAppearanceProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Chip(
            icon: Icons.light_mode,
            selected: appearance == AppAppearance.light,
            onTap: () => ref
                .read(themeModeProvider.notifier)
                .setAppearance(AppAppearance.light),
          ),
          _Chip(
            icon: Icons.dark_mode,
            selected: appearance == AppAppearance.dark,
            onTap: () => ref
                .read(themeModeProvider.notifier)
                .setAppearance(AppAppearance.dark),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Icon(
            icon,
            size: 18,
            color: selected ? AppTheme.primary : Colors.white,
          ),
        ),
      ),
    );
  }
}

class AppearanceSelector extends ConsumerWidget {
  const AppearanceSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appAppearanceProvider);
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 400;

    if (compact) {
      return Row(
        children: [
          Expanded(
            child: _AppearanceTile(
              selected: appearance == AppAppearance.light,
              icon: Icons.light_mode,
              label: l10n.lightMode,
              onTap: () => ref
                  .read(themeModeProvider.notifier)
                  .setAppearance(AppAppearance.light),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _AppearanceTile(
              selected: appearance == AppAppearance.dark,
              icon: Icons.dark_mode,
              label: l10n.darkMode,
              onTap: () => ref
                  .read(themeModeProvider.notifier)
                  .setAppearance(AppAppearance.dark),
            ),
          ),
        ],
      );
    }

    return SegmentedButton<AppAppearance>(
      segments: [
        ButtonSegment(
          value: AppAppearance.light,
          icon: const Icon(Icons.light_mode, size: 18),
          label: Text(l10n.lightMode),
        ),
        ButtonSegment(
          value: AppAppearance.dark,
          icon: const Icon(Icons.dark_mode, size: 18),
          label: Text(l10n.darkMode),
        ),
      ],
      selected: {appearance},
      onSelectionChanged: (set) {
        ref.read(themeModeProvider.notifier).setAppearance(set.first);
      },
    );
  }
}

class _AppearanceTile extends StatelessWidget {
  const _AppearanceTile({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppTheme.primary.withValues(alpha: 0.12)
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: AppTheme.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight:
                        selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
