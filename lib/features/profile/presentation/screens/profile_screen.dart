import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/responsive.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/shared/widgets/bottom_nav.dart';
import 'package:repair_ai/shared/widgets/repair_app_bar.dart';
import 'package:repair_ai/shared/widgets/responsive_page.dart';
import 'package:repair_ai/core/utils/launch_helpers.dart';
import 'package:repair_ai/shared/widgets/theme_mode_toggle.dart';
import 'package:repair_ai/shared/widgets/ussd_access_card.dart';

import '../../../auth/presentation/controllers/auth_session_provider.dart';
import '../../../auth/presentation/controllers/login_profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: RepairAppBar(title: l10n.myProfile),
      body: SingleChildScrollView(
        padding: RepairInsets.scroll(context),
        child: ResponsivePageShell(
          maxWidth: RepairSizing.formMaxWidth(context),
          child: Column(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: AppTheme.primary,
                child: const Icon(Icons.person, size: 70, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                ref.watch(profileNameProvider) ?? 'Jane Wanjiku',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                ref.watch(profileEmailProvider) ?? 'jane@example.com',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.brightness_6, color: AppTheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            l10n.appearance,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const AppearanceSelector(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _menuItem(
                context,
                icon: Icons.history,
                title: l10n.myReports,
                subtitle: l10n.myReportsSubtitle,
                onTap: () => context.push('/history'),
              ),
              _menuItem(
                context,
                icon: Icons.language,
                title: l10n.language,
                subtitle: '${l10n.languageEnglish} • ${l10n.languageSwahili}',
                onTap: () => context.push('/profile/language'),
              ),
              _menuItem(
                context,
                icon: Icons.lock_reset,
                title: l10n.changePassword,
                subtitle: l10n.changePasswordSubtitle,
                onTap: () => context.push('/profile/change-password'),
              ),
              _menuItem(
                context,
                icon: Icons.help_outline,
                title: l10n.helpSupport,
                subtitle: '${l10n.helpSupportSubtitle} • USSD *384#',
                onTap: () => launchWhatsAppHelp(context),
              ),
              const SizedBox(height: 4),
              const UssdAccessCard(compact: true),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(authSessionProvider.notifier)
                        .signOutBackend();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.loggedOutSuccess)),
                      );
                      context.go('/auth');
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: Text(
                    l10n.logout,
                    style: const TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary, size: 28),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
