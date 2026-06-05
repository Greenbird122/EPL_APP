import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/network/api_client.dart';
import 'package:repair_ai/core/utils/app_error_handler.dart';
import 'package:repair_ai/core/utils/responsive.dart';
import 'package:repair_ai/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:repair_ai/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:repair_ai/shared/widgets/repair_app_bar.dart';
import 'package:repair_ai/shared/widgets/responsive_page.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscure = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _statusMessage;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _statusMessage = 'Updating your password...';
    });

    try {
      await ref.read(authSessionProvider.notifier).changePassword(
            oldPassword: _oldPasswordController.text,
            newPassword: _newPasswordController.text,
            confirmPassword: _confirmPasswordController.text,
          );
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _statusMessage = 'Password changed successfully.';
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      final message = friendlyAuthError(error);
      setState(() {
        _isSubmitting = false;
        _statusMessage = null;
        _errorMessage = message;
      });
      showAppErrorSnackBar(context, message);
    } catch (error) {
      if (!mounted) return;
      final message = friendlyAuthError(error);
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
    return Scaffold(
      appBar: const RepairAppBar(title: 'Change password'),
      body: SingleChildScrollView(
        padding: RepairInsets.scroll(context),
        child: ResponsivePageShell(
          maxWidth: RepairSizing.formMaxWidth(context),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null) ...[
                  AuthErrorBanner(
                    message: _errorMessage!,
                    onDismiss: () => setState(() => _errorMessage = null),
                  ),
                  const SizedBox(height: 12),
                ] else if (_statusMessage != null) ...[
                  AuthStatusBanner(
                    message: _statusMessage!,
                    tone: AuthStatusTone.success,
                    showProgress: _isSubmitting,
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _oldPasswordController,
                  obscureText: _obscure,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) => (value ?? '').isEmpty
                      ? 'Current password is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'New password',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  validator: _validateNewPassword,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscure,
                  decoration: const InputDecoration(
                    labelText: 'Confirm new password',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                  validator: (value) {
                    if ((value ?? '').isEmpty) return 'Confirm new password';
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Update password'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validateNewPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'New password is required';
    if (text.length < 8) return 'Password must be at least 8 characters';
    if (RegExp(r'^\d+$').hasMatch(text)) {
      return 'Password cannot be entirely numeric';
    }
    return null;
  }
}
