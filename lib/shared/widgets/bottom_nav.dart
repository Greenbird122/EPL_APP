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
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primary,
      unselectedItemColor: Colors.grey,
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/triage/symptom-report');
            break;
          case 2:
            context.go('/referral');
            break;
          case 3:
            context.go('/profile');
            break;
        }
      },
      items: [
        BottomNavigationBarItem(icon: const Icon(Icons.home), label: l10n.home),
        BottomNavigationBarItem(
          icon: const Icon(Icons.medical_services),
          label: l10n.triage,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.map_outlined),
          label: l10n.myReferrals,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: l10n.profile,
        ),
      ],
    );
  }
}
