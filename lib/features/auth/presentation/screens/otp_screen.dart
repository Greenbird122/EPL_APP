import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/app_error_handler.dart';
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
  final bool _codeSent = false;
  final bool _isSubmitting = false;
  String? _errorMessage;
  String? _statusMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      const message = 'Enter a valid phone number.';
      setState(() => _errorMessage = message);
      showAppErrorSnackBar(context, message);
      return;
    }
    setState(() {
      _errorMessage =
          'Phone code sign-in is not available in the app yet. Use username and password for now.';
      _statusMessage = null;
    });
  }

  Future<void> _verifyCode() async {
    const message =
        'Phone code sign-in is not available in the app yet. Use username and password for now.';
    setState(() => _errorMessage = message);
    showAppErrorSnackBar(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = l10n.phoneOtpLabel;

    return AuthShell(
      title: title,
      subtitle: l10n.recoverAccountSubtitle,
      showBack: true,
      errorMessage: _errorMessage,
      statusMessage: _statusMessage,
      isLoading: _isSubmitting,
      onDismissError: () => setState(() => _errorMessage = null),
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
            label: Text(_codeSent ? l10n.verifyAndContinue : l10n.sendOtp),
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
