import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/network/api_client.dart';
import 'package:repair_ai/core/utils/app_error_handler.dart';
import 'package:repair_ai/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:repair_ai/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:repair_ai/features/auth/presentation/widgets/auth_form_widgets.dart';
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
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;
  bool _rememberMe = true;
  String? _errorMessage;
  String? _statusMessage;
  AuthStatusTone _statusTone = AuthStatusTone.info;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithPassword() async {
    final l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _statusMessage = l10n.authSigningInStatus;
      _statusTone = AuthStatusTone.info;
    });

    try {
      final session =
          await ref.read(authSessionProvider.notifier).signInWithBackend(
                username: _phoneController.text.trim(),
                password: _passwordController.text,
                rememberMe: _rememberMe,
              );
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _statusMessage = l10n.authSignedInStatus;
        _statusTone = AuthStatusTone.success;
      });
      await Future<void>.delayed(const Duration(milliseconds: 500));
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AuthShell(
      title: l10n.signInTitle,
      subtitle: l10n.signInSubtitle,
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
              icon: Icons.lock_outline,
              title: l10n.signInTitle,
            ),
            AuthTextField(
              controller: _phoneController,
              label: '${l10n.signInPhoneLabel} / ${l10n.usernameCareIdLabel}',
              helperText: l10n.signInPhoneHelper,
              icon: Icons.phone_android,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) {
                  return l10n.signInPhoneRequired;
                }
                final normalized = value.replaceAll(RegExp(r'[\s-]'), '');
                final validPhone =
                    RegExp(r'^(?:0|254|\+254)7\d{8}$').hasMatch(normalized);
                final validCareId =
                    value.length >= 3 && !value.contains(RegExp(r'\s'));
                if (!validPhone && !validCareId) {
                  return l10n.signInPhoneInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            AuthTextField(
              controller: _passwordController,
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
              obscureText: _obscurePassword,
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
              },
              validator: (v) {
                final value = v ?? '';
                if (value.isEmpty) return l10n.passwordRequired;
                return null;
              },
              onFieldSubmitted: (_) => _signInWithPassword(),
            ),
            const SizedBox(height: 12),
            AuthRememberRow(
              value: _rememberMe,
              onChanged: (value) {
                if (!_isSubmitting) setState(() => _rememberMe = value);
              },
              title: l10n.rememberMe,
              subtitle: l10n.rememberMePatientSubtitle,
            ),
            const SizedBox(height: 14),
            AuthPrimaryButton(
              onPressed: _signInWithPassword,
              isLoading: _isSubmitting,
              icon: Icons.login,
              label: l10n.continueToCare,
            ),
            const SizedBox(height: 10),
            AuthLinkWrap(
              children: [
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}
