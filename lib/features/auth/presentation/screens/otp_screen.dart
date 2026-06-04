import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/onboarding_provider.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/app_error_handler.dart';
import 'package:repair_ai/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:repair_ai/features/auth/presentation/controllers/login_profile_providers.dart';
import 'package:repair_ai/features/auth/presentation/widgets/auth_shell.dart';
import 'package:repair_ai/localization/app_localizations.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, this.isDemoMode = false});

  final bool isDemoMode;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _phoneController = TextEditingController(text: '+254');
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      showAppErrorSnackBar(context, 'Enter a valid phone number.');
      return;
    }
    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _codeSent = true;
      _codeController.text = '123456';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP sent. Use 123456 for this build.')),
    );
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.trim() != '123456') {
      showAppErrorSnackBar(context, 'Use OTP 123456.');
      return;
    }
    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    ref.read(profileFormDataProvider.notifier).state = ProfileFormData(
      name: widget.isDemoMode ? 'Jane Wanjiku' : 'Mother User',
      email: widget.isDemoMode ? 'demo@repairai.co.ke' : 'phone-user',
    );
    await ref.read(onboardingCompleteProvider.notifier).markComplete();
    await AuthSessionNotifier.acceptTerms();
    await ref.read(authSessionProvider.notifier).signIn(
          status: widget.isDemoMode
              ? AuthSessionStatus.demo
              : AuthSessionStatus.mother,
        );
    if (mounted) context.go('/login/transition');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = widget.isDemoMode ? l10n.continueAsGuest : l10n.phoneOtpLabel;

    return AuthShell(
      title: title,
      subtitle: widget.isDemoMode
          ? l10n.fastSignInSubtitle
          : l10n.recoverAccountSubtitle,
      showBack: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: l10n.phoneNumberLabel,
              prefixIcon: const Icon(Icons.phone_android),
            ),
          ),
          if (_codeSent) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: l10n.otpCodeLabel,
                prefixIcon: const Icon(Icons.password),
                counterText: '',
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed:
                _isSubmitting ? null : (_codeSent ? _verifyCode : _sendCode),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(_codeSent ? Icons.verified : Icons.sms),
            label: Text(
              _codeSent ? l10n.verifyAndContinue : l10n.sendOtp,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
          if (_codeSent)
            TextButton(
              onPressed: _isSubmitting ? null : _sendCode,
              child: Text(l10n.resendOtp),
            ),
          TextButton(
            onPressed: () => context.go('/auth/sign-in'),
            child: Text(l10n.loginButton),
          ),
        ],
      ),
    );
  }
}
