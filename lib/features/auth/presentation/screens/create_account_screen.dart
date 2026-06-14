import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/kenya_counties.dart';
import 'package:repair_ai/core/network/api_client.dart';
import 'package:repair_ai/core/utils/app_error_handler.dart';
import 'package:repair_ai/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:repair_ai/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:repair_ai/features/auth/presentation/widgets/auth_form_widgets.dart';
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
  final _phoneController = TextEditingController(text: '+254');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _subCountyController = TextEditingController();
  String? _selectedCounty;
  bool _acceptedConsent = false;
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _statusMessage;
  AuthStatusTone _statusTone = AuthStatusTone.info;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _subCountyController.dispose();
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
      _statusMessage = l10n.authCreatingAccountStatus;
      _statusTone = AuthStatusTone.info;
    });
    try {
      final session = await ref
          .read(authSessionProvider.notifier)
          .registerPatientWithBackend(
            password: _passwordController.text,
            passwordConfirm: _confirmPasswordController.text,
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            country: 'Kenya',
            county: _selectedCounty ?? '',
            subCounty: _subCountyController.text.trim(),
            rememberMe: true,
          );
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _statusMessage = l10n.authAccountCreatedStatus;
        _statusTone = AuthStatusTone.success;
      });
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      context.go(
        session.isProvider ? '/dashboard/provider' : '/login/transition',
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      final message = friendlyAuthStatusMessage(context, error);
      setState(() {
        _isSubmitting = false;
        _statusMessage = null;
        _errorMessage = message;
      });
      showAppErrorSnackBar(context, message);
    } catch (error) {
      if (!mounted) return;
      final message = friendlyAuthStatusMessage(
        context,
        error,
        fallback: l10n.authCareServicesUnavailable,
      );
      setState(() {
        _isSubmitting = false;
        _statusMessage = null;
        _errorMessage = message;
      });
      showAppErrorSnackBar(context, message);
    }
  }

  void _clearError() {
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AuthShell(
      title: l10n.createAccountTitle,
      subtitle: l10n.createAccountSubtitle,
      showBack: true,
      errorMessage: _errorMessage,
      statusMessage: _statusMessage,
      isLoading: _isSubmitting,
      statusTone: _statusTone,
      onDismissError: () => setState(() => _errorMessage = null),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthSectionHeader(
              icon: Icons.person_outline,
              title: l10n.accountDetailsSection,
            ),
            AuthTextField(
              controller: _nameController,
              onChanged: (_) => _clearError(),
              label: l10n.name,
              icon: Icons.person_outline,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  (value ?? '').trim().length < 2 ? l10n.nameTooShort : null,
            ),
            const SizedBox(height: 12),
            AuthSectionHeader(
              icon: Icons.phone_android,
              title: l10n.contactDetailsSection,
            ),
            AuthTextField(
              controller: _phoneController,
              onChanged: (_) => _clearError(),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              label: l10n.phoneNumberLabel,
              icon: Icons.phone_android,
              helperText:
                  'Your phone number will be your Care ID for signing in.',
              validator: (value) =>
                  (value ?? '').trim().length < 10 ? 'Phone is required' : null,
            ),
            const SizedBox(height: 18),
            const AuthSectionHeader(
              icon: Icons.location_on_outlined,
              title: 'Your Location',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedCounty,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'County',
                prefixIcon: const Icon(Icons.map_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: kenyaCounties
                  .map((c) => DropdownMenuItem(
                        value: c.name,
                        child: Text(c.name),
                      ))
                  .toList(),
              onChanged: (value) {
                _clearError();
                setState(() => _selectedCounty = value);
              },
              validator: (value) =>
                  (value ?? '').isEmpty ? 'Please select your county' : null,
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _subCountyController,
              onChanged: (_) => _clearError(),
              textInputAction: TextInputAction.next,
              label: 'Sub-County / Ward',
              icon: Icons.location_city,
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'Sub-county is required'
                  : null,
            ),
            const SizedBox(height: 18),
            AuthSectionHeader(
              icon: Icons.lock_outline,
              title: l10n.securitySection,
            ),
            PasswordGuidance(text: l10n.passwordGuidanceShort),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _passwordController,
              onChanged: (_) => _clearError(),
              obscureText: _obscurePassword,
              label: l10n.password,
              icon: Icons.lock_outline,
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
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
            AuthTextField(
              controller: _confirmPasswordController,
              onChanged: (_) => _clearError(),
              obscureText: _obscurePassword,
              label: 'Confirm password',
              icon: Icons.lock_reset_outlined,
              validator: (value) {
                if ((value ?? '').isEmpty) return 'Confirm your password';
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            AuthConsentRow(
              value: _acceptedConsent,
              onChanged: (value) => setState(() => _acceptedConsent = value),
              text: l10n.consentText,
            ),
            const SizedBox(height: 14),
            AuthPrimaryButton(
              onPressed: _continue,
              isLoading: _isSubmitting,
              icon: Icons.person_add_alt_1,
              label: l10n.createAccountTitle,
            ),
            const SizedBox(height: 8),
            AuthLinkWrap(
              children: [
                TextButton(
                  onPressed: () => context.go('/auth/sign-in'),
                  child: Text(l10n.alreadyHaveAccountSignIn),
                ),
              ],
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
