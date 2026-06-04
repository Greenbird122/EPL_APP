import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/app_error_handler.dart';
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
  final _emailController = TextEditingController();
  final _countyController = TextEditingController(text: 'Bungoma');
  bool _acceptedConsent = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _countyController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!_acceptedConsent) {
      showAppErrorSnackBar(
        context,
        'Please accept consent and privacy terms to create an account.',
      );
      return;
    }
    context.push('/auth/otp');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AuthShell(
      title: l10n.createAccountTitle,
      subtitle: l10n.createAccountSubtitle,
      showBack: true,
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
                labelText: '${l10n.emailLabel} (optional)',
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _countyController,
              decoration: InputDecoration(
                labelText: l10n.careAreaLabel,
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Care area is required' : null,
            ),
            const SizedBox(height: 8),
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
              onPressed: _continue,
              icon: const Icon(Icons.sms),
              label: Text(l10n.continueToPhoneVerification),
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
}
