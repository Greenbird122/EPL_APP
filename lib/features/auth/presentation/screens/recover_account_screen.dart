import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/app_error_handler.dart';
import 'package:repair_ai/features/auth/presentation/widgets/auth_shell.dart';
import 'package:repair_ai/localization/app_localizations.dart';

class RecoverAccountScreen extends StatefulWidget {
  const RecoverAccountScreen({super.key});

  @override
  State<RecoverAccountScreen> createState() => _RecoverAccountScreenState();
}

class _RecoverAccountScreenState extends State<RecoverAccountScreen> {
  final _controller = TextEditingController(text: '+254');
  bool _isSending = false;
  String? _statusMessage;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendRecovery() async {
    if (_controller.text.trim().length < 6) {
      const message = 'Enter your phone or email.';
      setState(() => _errorMessage = message);
      showAppErrorSnackBar(context, message);
      return;
    }
    const message =
        'Password reset is not available on this backend yet. Please use the web dashboard or contact support.';
    setState(() {
      _isSending = false;
      _statusMessage = null;
      _errorMessage = message;
    });
    showAppErrorSnackBar(context, message);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AuthShell(
      title: l10n.recoverAccountTitle,
      subtitle: l10n.recoverAccountSubtitle,
      showBack: true,
      errorMessage: _errorMessage,
      statusMessage: _statusMessage,
      isLoading: _isSending,
      onDismissError: () => setState(() => _errorMessage = null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: '${l10n.phoneNumberLabel} / ${l10n.emailLabel}',
              prefixIcon: const Icon(Icons.lock_reset),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isSending ? null : _sendRecovery,
            icon: _isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send),
            label: Text(l10n.sendRecoveryInstructions),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
          TextButton(
            onPressed: () => context.go('/auth/sign-in'),
            child: Text(l10n.backToSignIn),
          ),
        ],
      ),
    );
  }
}
