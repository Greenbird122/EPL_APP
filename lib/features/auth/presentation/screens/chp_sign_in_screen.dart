import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/onboarding_provider.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/app_error_handler.dart';
import 'package:repair_ai/core/utils/async_guard.dart';
import 'package:repair_ai/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:repair_ai/features/auth/presentation/controllers/login_profile_providers.dart';
import 'package:repair_ai/features/auth/presentation/widgets/auth_shell.dart';
import 'package:repair_ai/localization/app_localizations.dart';

class ChpSignInScreen extends ConsumerStatefulWidget {
  const ChpSignInScreen({super.key});

  @override
  ConsumerState<ChpSignInScreen> createState() => _ChpSignInScreenState();
}

class _ChpSignInScreenState extends ConsumerState<ChpSignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _staffController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _staffController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);

    final ok = await runWithTimeout(
      () async {
        await Future<void>.delayed(const Duration(milliseconds: 650));
        ref.read(profileFormDataProvider.notifier).state = ProfileFormData(
          name: 'CHP Care Team',
          email: _staffController.text.trim(),
        );
        await ref.read(onboardingCompleteProvider.notifier).markComplete();
        await AuthSessionNotifier.acceptTerms();
        await ref
            .read(authSessionProvider.notifier)
            .signIn(status: AuthSessionStatus.provider);
        return true;
      },
      timeout: const Duration(seconds: 12),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (ok != true) {
      showAppErrorSnackBar(context, l10n.timeoutError);
      return;
    }
    context.go('/dashboard/provider');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return AuthShell(
      title: l10n.providerSignInTitle,
      subtitle: l10n.providerSignInSubtitle,
      showBack: true,
      imageAsset: 'assets/illustrations/hospital.jpg',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.18),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined,
                      color: AppTheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.chpAccessHint,
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _staffController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n.staffIdOrEmail,
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? l10n.staffIdRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: l10n.password,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(
                    () => _obscurePassword = !_obscurePassword,
                  ),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
              obscureText: _obscurePassword,
              validator: (value) {
                final text = value ?? '';
                if (text.isEmpty) return l10n.passwordRequired;
                if (text.length < 6) return l10n.passwordMinLength;
                return null;
              },
              onFieldSubmitted: (_) => _signIn(),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _signIn,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.dashboard_customize_outlined),
              label: Text(l10n.continueToChpDashboard),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/auth/sign-in'),
              child: Text(l10n.signInTitle),
            ),
          ],
        ),
      ),
    );
  }
}
