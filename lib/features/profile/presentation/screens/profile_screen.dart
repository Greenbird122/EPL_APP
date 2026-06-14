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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryLight],
                  ),
                ),
                child: const CircleAvatar(
                  radius: 58,
                  backgroundColor: AppTheme.surfaceTinted,
                  child: Icon(
                    Icons.person,
                    size: 66,
                    color: AppTheme.primary,
                  ),
                ),
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
              const SizedBox(height: 4),
              _PhoneDisplay(),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.brightness_6,
                              color: AppTheme.primary),
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
                icon: Icons.notifications_outlined,
                title: l10n.notifications,
                subtitle: l10n.notificationsSubtitle,
                onTap: () => context.push('/profile/notifications'),
              ),
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
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'Manage your account and preferences',
                onTap: () => context.push('/profile/settings'),
              ),
              _menuItem(
                context,
                icon: Icons.account_balance_wallet_outlined,
                title: 'Payments & Balance',
                subtitle: 'Top up via M-Pesa, view transaction history',
                onTap: () => context.push('/profile/payments'),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  width: double.infinity,
                  height: RepairSizing.buttonHeight(context),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Sign out?'),
                          content: const Text(
                              'Your saved data stays on this device.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Sign out'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      await ref
                          .read(authSessionProvider.notifier)
                          .signOutBackend();
                      if (context.mounted) context.go('/auth');
                    },
                    icon: const Icon(Icons.logout, color: AppTheme.error),
                    label: Text(l10n.logout,
                        style: const TextStyle(color: AppTheme.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.error),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
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
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.primary.withValues(alpha: 0.1),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primary.withValues(alpha: 0.15),
                AppTheme.primaryLight.withValues(alpha: 0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Icon(
          Icons.chevron_right,
          color: AppTheme.primary.withValues(alpha: 0.4),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _PhoneDisplay extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phone = ref.watch(profilePhoneProvider);
    if (phone == null || phone.isEmpty) return const SizedBox.shrink();
    return Text(
      phone,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
