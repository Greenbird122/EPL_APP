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

class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+254');
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _acceptedConsent = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptedConsent) {
      const message =
          'Please accept consent and privacy terms to create an account.';
      setState(() => _errorMessage = message);
      showAppErrorSnackBar(context, message);
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final session = await ref
          .read(authSessionProvider.notifier)
          .registerPatientWithBackend(
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            passwordConfirm: _confirmPasswordController.text,
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            rememberMe: true,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AuthShell(
      title: l10n.createAccountTitle,
      subtitle: l10n.createAccountSubtitle,
      showBack: true,
      errorMessage: _errorMessage,
      statusMessage: _isSubmitting ? 'Creating your account...' : null,
      isLoading: _isSubmitting,
      onDismissError: () => setState(() => _errorMessage = null),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.name,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              validator: (value) =>
                  (value ?? '').trim().length < 2 ? l10n.nameTooShort : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                helperText: 'You will use this to sign in.',
                prefixIcon: Icon(Icons.alternate_email),
              ),
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.length < 3) return 'Username is required';
                if (text.contains(' ')) return 'Username cannot contain spaces';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: l10n.phoneNumberLabel,
                prefixIcon: const Icon(Icons.phone_android),
              ),
              validator: (value) =>
                  (value ?? '').trim().length < 10 ? 'Phone is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n.emailLabel,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) return l10n.emailRequired;
                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
                  return l10n.emailInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: l10n.password,
                helperText:
                    'Use at least 8 characters. Avoid common or numeric-only passwords.',
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
              validator: (value) {
                final text = value ?? '';
                if (text.isEmpty) return l10n.passwordRequired;
                if (text.length < 8) {
                  return 'Password must be at least 8 characters';
                }
                if (RegExp(r'^\d+$').hasMatch(text)) {
                  return 'Password cannot be entirely numeric';
                }
                if (_isCommonPassword(text)) {
                  return 'Choose a less common password';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscurePassword,
              decoration: const InputDecoration(
                labelText: 'Confirm password',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
              validator: (value) {
                if ((value ?? '').isEmpty) return 'Confirm your password';
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _acceptedConsent,
              onChanged: (value) =>
                  setState(() => _acceptedConsent = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(l10n.consentText),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _continue,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.person_add_alt_1),
              label: Text(l10n.createAccountTitle),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/auth/sign-in'),
              child: Text(l10n.alreadyHaveAccountSignIn),
            ),
          ],
        ),
      ),
    );
  }

  bool _isCommonPassword(String value) {
    final normalized = value.toLowerCase().trim();
    return const {
      'password',
      'password123',
      '12345678',
      '123456789',
      'qwerty123',
      'repairai',
    }.contains(normalized);
  }
}
