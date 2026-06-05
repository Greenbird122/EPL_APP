import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/network/api_client.dart';
import 'package:repair_ai/core/utils/app_error_handler.dart';
import 'package:repair_ai/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:repair_ai/features/auth/presentation/widgets/auth_error_banner.dart';
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
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _usePhone = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _rememberMe = true;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithPassword() async {
    final l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final session =
          await ref.read(authSessionProvider.notifier).signInWithBackend(
                username: _usernameController.text.trim(),
                password: _passwordController.text,
                rememberMe: _rememberMe,
              );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      context
          .go(session.isProvider ? '/dashboard/provider' : '/login/transition');
    } on ApiException catch (error) {
      if (!mounted) return;
      final message = friendlyAuthError(error);
      setState(() {
        _isSubmitting = false;
        _errorMessage = message;
      });
      showAppErrorSnackBar(context, message);
    } catch (error) {
      if (!mounted) return;
      final message = friendlyAuthError(error, fallback: l10n.timeoutError);
      setState(() {
        _isSubmitting = false;
        _errorMessage = message;
      });
      showAppErrorSnackBar(context, message);
    }
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
      errorMessage: _errorMessage,
      statusMessage: _isSubmitting ? 'Signing you in securely...' : null,
      isLoading: _isSubmitting,
      onDismissError: () => setState(() => _errorMessage = null),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_usePhone) ...[
              AuthStatusBanner(
                message:
                    'Phone OTP is not connected to the backend yet. Use username and password for now.',
                tone: AuthStatusTone.warning,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.phoneNumberLabel,
                  prefixIcon: const Icon(Icons.phone_android),
                ),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: _rememberMe,
                onChanged: _isSubmitting
                    ? null
                    : (value) => setState(() => _rememberMe = value ?? true),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Remember me'),
                subtitle: const Text('Keep me signed in on this device.'),
              ),
              const SizedBox(height: 8),
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
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  helperText: 'Use your username, not your email address.',
                  prefixIcon: const Icon(Icons.alternate_email),
                ),
                keyboardType: TextInputType.text,
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) {
                    return 'Username is required';
                  }
                  if (value.contains(' ')) {
                    return 'Username cannot contain spaces';
                  }
                  if (value.contains('@')) {
                    return 'Use your username, not email. Email login is not supported by this backend yet.';
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
                  return null;
                },
                onFieldSubmitted: (_) => _signInWithPassword(),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _signInWithPassword,
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
            TextButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : () => setState(() {
                        _usePhone = !_usePhone;
                        _errorMessage = null;
                      }),
              icon: Icon(_usePhone ? Icons.lock_outline : Icons.phone_android),
              label: Text(
                _usePhone ? 'Use username and password' : 'Use phone OTP later',
              ),
            ),
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
