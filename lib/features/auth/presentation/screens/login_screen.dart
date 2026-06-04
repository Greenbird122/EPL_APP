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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController(text: '+254');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _usePhone = true;
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    final l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);

    final ok = await runWithTimeout(
      () async {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        ref.read(profileFormDataProvider.notifier).state = ProfileFormData(
          name: 'Mother User',
          email: _emailController.text.trim(),
        );
        await ref.read(onboardingCompleteProvider.notifier).markComplete();
        await AuthSessionNotifier.acceptTerms();
        await ref.read(authSessionProvider.notifier).signIn(
              status: AuthSessionStatus.mother,
            );
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
    context.go('/login/transition');
  }

  void _continuePhoneOtp() {
    if (_phoneController.text.trim().length < 10) {
      showAppErrorSnackBar(context, 'Enter a valid phone number.');
      return;
    }
    context.push('/auth/otp');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AuthShell(
      title: l10n.signInTitle,
      subtitle: l10n.signInSubtitle,
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: true,
                  icon: const Icon(Icons.phone_android),
                  label: Text(l10n.phoneOtpLabel),
                ),
                ButtonSegment(
                  value: false,
                  icon: const Icon(Icons.mail_outline),
                  label: Text(l10n.emailLabel),
                ),
              ],
              selected: {_usePhone},
              onSelectionChanged: (value) =>
                  setState(() => _usePhone = value.first),
            ),
            const SizedBox(height: 14),
            if (_usePhone) ...[
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.phoneNumberLabel,
                  prefixIcon: const Icon(Icons.phone_android),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _continuePhoneOtp,
                icon: const Icon(Icons.sms),
                label: Text(l10n.sendOtp),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: l10n.email,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return l10n.emailRequired;
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                    return l10n.emailInvalid;
                  }
                  return null;
                },
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
                validator: (v) {
                  final value = v ?? '';
                  if (value.isEmpty) return l10n.passwordRequired;
                  if (value.length < 6) return l10n.passwordMinLength;
                  return null;
                },
                onFieldSubmitted: (_) => _signInWithEmail(),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _signInWithEmail,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.login),
                label: Text(l10n.loginButton),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => context.push('/auth/recover'),
              child: Text(l10n.forgotPassword),
            ),
            TextButton(
              onPressed: () => context.push('/auth/create-account'),
              child: Text(l10n.newToRepairCreateAccount),
            ),
            TextButton.icon(
              onPressed: () => context.push('/auth/chp'),
              icon: const Icon(Icons.badge_outlined),
              label: Text(l10n.providerAccess),
            ),
            TextButton(
              onPressed: () => context.go('/auth'),
              child: Text(l10n.useGuestAccessInstead),
            ),
          ],
        ),
      ),
    );
  }
}
