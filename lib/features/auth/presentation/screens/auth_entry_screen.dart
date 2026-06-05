import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/onboarding_provider.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:repair_ai/features/auth/presentation/controllers/login_profile_providers.dart';
import 'package:repair_ai/features/auth/presentation/widgets/auth_shell.dart';
import 'package:repair_ai/localization/app_localizations.dart';

class AuthEntryScreen extends ConsumerStatefulWidget {
  const AuthEntryScreen({super.key});

  @override
  ConsumerState<AuthEntryScreen> createState() => _AuthEntryScreenState();
}

class _AuthEntryScreenState extends ConsumerState<AuthEntryScreen> {
  bool _isStartingDemo = false;

  Future<void> _continueDemo() async {
    if (_isStartingDemo) return;
    setState(() => _isStartingDemo = true);
    ref.read(profileFormDataProvider.notifier).state = const ProfileFormData(
      name: 'Jane Wanjiku',
      email: 'demo@repairai.co.ke',
    );
    await ref.read(onboardingCompleteProvider.notifier).markComplete();
    await AuthSessionNotifier.acceptTerms();
    await ref
        .read(authSessionProvider.notifier)
        .signIn(status: AuthSessionStatus.demo);
    if (mounted) context.go('/login/transition');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AuthShell(
      title: l10n.appTitle,
      subtitle: l10n.chooseAccessSubtitle,
      imageAsset: 'assets/illustrations/mama.jpeg',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AuthChoiceButton(
            icon: Icons.lock_outline,
            title: l10n.signInTitle,
            color: AppTheme.primary,
            onTap: () => context.push('/auth/sign-in'),
          ),
          const SizedBox(height: 10),
          _AuthChoiceButton(
            icon: Icons.person_add_alt_1,
            title: l10n.createAccountTitle,
            color: AppTheme.accent,
            onTap: () => context.push('/auth/create-account'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _isStartingDemo ? null : _continueDemo,
            icon: _isStartingDemo
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_circle_outline),
            label: Text(l10n.continueAsGuest),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => context.push('/auth/chp'),
            icon: const Icon(Icons.badge_outlined),
            label: Text(l10n.providerAccess),
          ),
        ],
      ),
    );
  }
}

class _AuthChoiceButton extends StatelessWidget {
  const _AuthChoiceButton({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color,
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
