import 'package:flutter/material.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/localization/app_localizations.dart';

class RepairAppBar extends StatelessWidget implements PreferredSizeWidget {
  const RepairAppBar({
    super.key,
    required this.title,
    this.showDemoChip = false,
    this.actions,
    this.leading,
  });

  final String title;
  final bool showDemoChip;
  final List<Widget>? actions;
  final Widget? leading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final actionWidgets = <Widget>[
      if (showDemoChip)
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Center(
            child: Chip(
              label: Text(
                l10n.demoChipLabel,
                style: const TextStyle(fontSize: 11, color: Colors.white),
              ),
              backgroundColor: Colors.white24,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ...?actions,
    ];

    return AppBar(
      leading: leading,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: AppTheme.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      actions: actionWidgets.isEmpty ? null : actionWidgets,
    );
  }
}
