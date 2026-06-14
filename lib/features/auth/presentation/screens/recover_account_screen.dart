import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/launch_helpers.dart';
import 'package:repair_ai/features/auth/presentation/widgets/auth_form_widgets.dart';
import 'package:repair_ai/features/auth/presentation/widgets/auth_shell.dart';
import 'package:repair_ai/localization/app_localizations.dart';

class RecoverAccountScreen extends StatefulWidget {
  const RecoverAccountScreen({super.key});

  @override
  State<RecoverAccountScreen> createState() => _RecoverAccountScreenState();
}

class _RecoverAccountScreenState extends State<RecoverAccountScreen> {
  bool _isSending = false;

  Future<void> _openWebReset() async {
    setState(() => _isSending = true);
    try {
      await launchRepairAiWebsite();
    } catch (_) {
      // Browser not available
    }
    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return AuthShell(
      title: l10n.recoverAccountTitle,
      subtitle: l10n.recoverAccountSubtitle,
      showBack: true,
      isLoading: _isSending,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: AppTheme.warning, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Password reset is handled through the web platform. '
                    'Open the link below in your browser, or contact your '
                    'CHP or support for help.',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AuthPrimaryButton(
            onPressed: _openWebReset,
            isLoading: _isSending,
            icon: Icons.open_in_browser,
            label: 'Open Web Platform',
          ),
          const SizedBox(height: 12),
          AuthLinkWrap(
            children: [
              TextButton.icon(
                onPressed: () => context.go('/auth/sign-in'),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text(l10n.backToSignIn),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
