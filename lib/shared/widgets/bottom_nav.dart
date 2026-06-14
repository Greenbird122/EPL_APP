import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/localization/app_localizations.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.surfaceTinted,
        border: Border(
          top: BorderSide(
            color: AppTheme.primary.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.primary.withValues(alpha: 0.35),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        currentIndex: currentIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/symptom-check');
              break;
            case 2:
              context.go('/care');
              break;
            case 3:
              context.go('/referral');
              break;
            case 4:
              context.go('/profile');
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home), label: l10n.home),
          BottomNavigationBarItem(
            icon: const Icon(Icons.medical_services),
            label: l10n.triage,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_border),
            label: l10n.careTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.map_outlined),
            label: l10n.findCareTitle,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: l10n.profile,
          ),
        ],
      ),
    );
  }
}
