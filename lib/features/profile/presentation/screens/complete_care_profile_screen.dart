import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/kenya_counties.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/network/api_client.dart';
import 'package:repair_ai/core/network/backend_heartbeat_provider.dart';
import 'package:repair_ai/core/network/backend_services.dart';
import 'package:repair_ai/core/utils/responsive.dart';
import 'package:repair_ai/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:repair_ai/features/care/presentation/controllers/care_feed_provider.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/shared/widgets/repair_app_bar.dart';
import 'package:repair_ai/shared/widgets/responsive_page.dart';

class CompleteCareProfileScreen extends ConsumerStatefulWidget {
  const CompleteCareProfileScreen({super.key});

  @override
  ConsumerState<CompleteCareProfileScreen> createState() =>
      _CompleteCareProfileScreenState();
}

class _CompleteCareProfileScreenState
    extends ConsumerState<CompleteCareProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ageController = TextEditingController();
  final _subCountyController = TextEditingController();
  final _villageController = TextEditingController();
  final _gravidaController = TextEditingController();
  int? _patientId;
  String? _county;
  DateTime? _lmp;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _subCountyController.dispose();
    _villageController.dispose();
    _gravidaController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ref.read(patientApiProvider).myProfile();
      if (!mounted) return;
      setState(() {
        _patientId = profile['id'] as int?;
        _ageController.text = '${profile['age'] ?? ''}';
        _subCountyController.text = '${profile['sub_county'] ?? ''}';
        _villageController.text = '${profile['village'] ?? ''}';
        _gravidaController.text = '${profile['gravida'] ?? ''}';
        _county = _validCounty('${profile['county'] ?? ''}');
        _lmp = _parseDate(profile['lmp']);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = friendlyAuthError(
          error,
          fallback: 'Could not load your care profile.',
        );
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final patientId = _patientId;
    if (patientId == null) {
      setState(() {
        _errorMessage = 'Patient profile was not found. Please sign in again.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _statusMessage = null;
    });

    final body = <String, dynamic>{
      'age': int.parse(_ageController.text.trim()),
      'county': _county,
      'sub_county': _subCountyController.text.trim(),
      'village': _villageController.text.trim(),
      'gravida': int.parse(_gravidaController.text.trim()),
      'lmp': _formatDate(_lmp),
    };

    try {
      await ref.read(patientApiProvider).updatePatient(patientId, body);
      ref.invalidate(careFeedProvider);
      if (!mounted) return;
      setState(() {
        _statusMessage = 'Care profile saved.';
        _isSaving = false;
      });
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (mounted) context.pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = friendlyAuthError(
          error,
          fallback: 'Could not save your care profile.',
        );
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = friendlyAuthError(
          error,
          fallback: 'Could not save your care profile.',
        );
      });
    }
  }

  Future<void> _pickLmp() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lmp ?? now.subtract(const Duration(days: 84)),
      firstDate: now.subtract(const Duration(days: 330)),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _lmp = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isOnline =
        ref.watch(backendHeartbeatProvider) == BackendHeartbeatState.online;

    return Scaffold(
      appBar: RepairAppBar(title: l10n.completeCareProfile),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: RepairInsets.scroll(context),
        child: ResponsivePageShell(
          maxWidth: RepairSizing.formMaxWidth(context),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isOnline) ...[
                        const _OfflineBanner(),
                        const SizedBox(height: 12),
                      ],
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
                        ),
                        const SizedBox(height: 12),
                      ],
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Add the essentials for referrals and follow-ups.',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _NumberField(
                                controller: _ageController,
                                label: 'Age',
                                min: 10,
                                max: 60,
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: _county,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'County',
                                  prefixIcon: Icon(
                                    Icons.location_city_outlined,
                                  ),
                                ),
                                items: kenyaCounties
                                    .map(
                                      (county) => DropdownMenuItem(
                                        value: county.name,
                                        child: Text(county.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _county = value),
                                validator: (value) =>
                                    value == null ? 'Choose county.' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _subCountyController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Sub-county',
                                  prefixIcon: Icon(Icons.map_outlined),
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                        ? 'Enter sub-county.'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _villageController,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Village / community',
                                  prefixIcon: Icon(Icons.home_work_outlined),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _NumberField(
                                controller: _gravidaController,
                                label: 'Pregnancy history',
                                helper:
                                    'Number of pregnancies, including this one.',
                                min: 0,
                                max: 20,
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _pickLmp,
                                icon: const Icon(Icons.event_outlined),
                                label: Text(
                                  _lmp == null
                                      ? 'Choose last period date'
                                      : 'Last period: ${_formatDate(_lmp)}',
                                ),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton.icon(
                                onPressed: _isSaving ? null : _saveProfile,
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save_outlined),
                                label: const Text('Save care profile'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  String? _validCounty(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return kenyaCounties.any((county) => county.name == trimmed)
        ? trimmed
        : null;
  }

  DateTime? _parseDate(Object? value) {
    if (value == null || value.toString().trim().isEmpty) return null;
    return DateTime.tryParse(value.toString());
  }

  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.min,
    required this.max,
    this.helper,
  });

  final TextEditingController controller;
  final String label;
  final int min;
  final int max;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        prefixIcon: const Icon(Icons.numbers_outlined),
      ),
      validator: (value) {
        final parsed = int.tryParse(value?.trim() ?? '');
        if (parsed == null) return 'Enter a number.';
        if (parsed < min || parsed > max) {
          return 'Use a value from $min to $max.';
        }
        return null;
      },
    );
  }
}
