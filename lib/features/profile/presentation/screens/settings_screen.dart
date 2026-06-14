import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/network/api_client.dart';
import 'package:repair_ai/core/network/backend_heartbeat_provider.dart';
import 'package:repair_ai/core/network/backend_services.dart';
import 'package:repair_ai/core/utils/responsive.dart';
import 'package:repair_ai/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:repair_ai/shared/widgets/repair_app_bar.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _changingPassword = false;
  String? _username;
  String? _role;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ref.read(authApiProvider).profile();
      final patient = await ref.read(patientApiProvider).myProfile();
      if (!mounted) return;
      setState(() {
        _firstNameController.text = '${profile['first_name'] ?? ''}';
        _lastNameController.text = '${profile['last_name'] ?? ''}';
        _phoneController.text = '${patient['phone'] ?? profile['phone'] ?? ''}';
        _emailController.text = '${profile['email'] ?? ''}';
        _username = '${profile['username'] ?? ''}';
        _role = '${profile['role'] ?? 'patient'}';
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // Update auth profile (first_name, last_name, email)
      await ref.read(authApiProvider).updateProfile({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
      });

      // Update patient profile (phone)
      final patient = await ref.read(patientApiProvider).myProfile();
      final patientId = patient['id'] as int?;
      if (patientId != null) {
        await ref.read(patientApiProvider).updatePatient(patientId, {
          'phone': _phoneController.text.trim(),
          'name':
              '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved')),
        );
        context.pop();
      }
    } on ApiException catch (e) {
      setState(() {
        _isSaving = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Could not save profile.';
      });
    }
  }

  Future<void> _changePassword() async {
    final current = _currentPasswordController.text;
    final newPw = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (current.isEmpty || newPw.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'All password fields are required.');
      return;
    }
    if (newPw != confirm) {
      setState(() => _errorMessage = 'New passwords do not match.');
      return;
    }
    if (newPw.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters.');
      return;
    }

    setState(() {
      _changingPassword = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authApiProvider).changePassword(
            oldPassword: current,
            newPassword: newPw,
            confirmPassword: confirm,
          );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed')),
        );
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Could not change password.');
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = RepairBreakpoints.isCompactPhone(context);
    final isOnline =
        ref.watch(backendHeartbeatProvider) == BackendHeartbeatState.online;

    return Scaffold(
      appBar: const RepairAppBar(title: 'Settings'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(compact ? 14 : 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!isOnline) ...[
                      _OfflineBanner(compact: compact),
                      const SizedBox(height: 12),
                    ],
                    Text('Manage your account and preferences',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        )),
                    const SizedBox(height: 20),

                    // Profile Information
                    const _SectionHeader(title: 'Profile Information'),
                    const SizedBox(height: 10),
                    _Field(
                        label: 'First Name',
                        controller: _firstNameController,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 12),
                    _Field(
                        label: 'Last Name',
                        controller: _lastNameController,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 12),
                    _Field(
                        label: 'Phone',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 12),
                    _ReadOnlyField(
                        label: 'Username',
                        value: _username ?? '-',
                        hint: 'Username cannot be changed'),
                    const SizedBox(height: 12),
                    _Field(
                        label: 'Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _ReadOnlyField(label: 'Role', value: _role ?? 'patient'),

                    const SizedBox(height: 24),

                    // Change Password
                    const _SectionHeader(title: 'Change Password'),
                    const SizedBox(height: 10),
                    _Field(
                        label: 'Current Password',
                        controller: _currentPasswordController,
                        obscure: true),
                    const SizedBox(height: 12),
                    _Field(
                        label: 'New Password',
                        controller: _newPasswordController,
                        obscure: true),
                    const SizedBox(height: 12),
                    _Field(
                        label: 'Confirm New Password',
                        controller: _confirmPasswordController,
                        obscure: true),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: _changingPassword ? null : _changePassword,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _changingPassword
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Change Password'),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Error
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_errorMessage!,
                            style: const TextStyle(
                                color: AppTheme.error, fontSize: 13)),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Save
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Save profile',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Text(title,
      style: const TextStyle(
          fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.primary));
}

class _Field extends StatelessWidget {
  const _Field(
      {required this.label,
      required this.controller,
      this.validator,
      this.keyboardType,
      this.obscure = false});
  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscure;
  @override
  Widget build(BuildContext context) => TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value, this.hint});
  final String label;
  final String value;
  final String? hint;
  @override
  Widget build(BuildContext context) => TextFormField(
        initialValue: value,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          filled: true,
          fillColor: AppTheme.primary.withValues(alpha: 0.04),
        ),
      );
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.compact});
  final bool compact;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off_outlined, size: 18, color: AppTheme.warning),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "You're offline. Changes will sync when connected.",
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.warning),
            ),
          ),
        ],
      ),
    );
  }
}
