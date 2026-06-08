import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/responsive.dart';
import 'package:repair_ai/features/anc/domain/anc_profile.dart';
import 'package:repair_ai/features/anc/presentation/controllers/anc_profile_controller.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/shared/widgets/repair_app_bar.dart';
import 'package:repair_ai/shared/widgets/repair_buttons.dart';
import 'package:repair_ai/shared/widgets/responsive_page.dart';

class AncProfileScreen extends ConsumerStatefulWidget {
  const AncProfileScreen({
    super.key,
    required this.mode,
    required this.patientId,
    this.patientName,
  });

  final AncProfileMode mode;
  final String patientId;
  final String? patientName;

  @override
  ConsumerState<AncProfileScreen> createState() => _AncProfileScreenState();
}

class _AncProfileScreenState extends ConsumerState<AncProfileScreen> {
  final _bloodGroup = TextEditingController();
  final _rhFactor = TextEditingController();
  final _antibodyScreen = TextEditingController();
  final _haemoglobin = TextEditingController();
  final _anaemiaStatus = TextEditingController();
  final _bpConcern = TextEditingController();
  final _proteinuriaConcern = TextEditingController();
  final _hivStatus = TextEditingController();
  final _syphilisStatus = TextEditingController();
  final _malariaIptp = TextEditingController();
  final _previousComplications = TextEditingController();
  final _notes = TextEditingController();
  final _nextAction = TextEditingController();
  String? _loadedPatientId;

  bool get _canManage => widget.mode == AncProfileMode.providerManage;

  @override
  void dispose() {
    _bloodGroup.dispose();
    _rhFactor.dispose();
    _antibodyScreen.dispose();
    _haemoglobin.dispose();
    _anaemiaStatus.dispose();
    _bpConcern.dispose();
    _proteinuriaConcern.dispose();
    _hivStatus.dispose();
    _syphilisStatus.dispose();
    _malariaIptp.dispose();
    _previousComplications.dispose();
    _notes.dispose();
    _nextAction.dispose();
    super.dispose();
  }

  void _loadIntoForm(AncProfile? profile) {
    if (profile == null || _loadedPatientId == profile.patientId) return;
    _loadedPatientId = profile.patientId;
    _bloodGroup.text = profile.bloodGroup;
    _rhFactor.text = profile.rhFactor;
    _antibodyScreen.text = profile.antibodyScreenStatus;
    _haemoglobin.text = profile.haemoglobin;
    _anaemiaStatus.text = profile.anaemiaStatus;
    _bpConcern.text = profile.bpConcern;
    _proteinuriaConcern.text = profile.proteinuriaConcern;
    _hivStatus.text = profile.hivScreeningStatus;
    _syphilisStatus.text = profile.syphilisScreeningStatus;
    _malariaIptp.text = profile.malariaIptpStatus;
    _previousComplications.text = profile.previousComplications;
    _notes.text = profile.notes;
    _nextAction.text = profile.nextAncAction;
  }

  Future<void> _save() async {
    final profile = AncProfile(
      patientId: widget.patientId,
      patientName: widget.patientName,
      bloodGroup: _bloodGroup.text.trim(),
      rhFactor: _rhFactor.text.trim(),
      antibodyScreenStatus: _antibodyScreen.text.trim(),
      haemoglobin: _haemoglobin.text.trim(),
      anaemiaStatus: _anaemiaStatus.text.trim(),
      bpConcern: _bpConcern.text.trim(),
      proteinuriaConcern: _proteinuriaConcern.text.trim(),
      hivScreeningStatus: _hivStatus.text.trim(),
      syphilisScreeningStatus: _syphilisStatus.text.trim(),
      malariaIptpStatus: _malariaIptp.text.trim(),
      previousComplications: _previousComplications.text.trim(),
      notes: _notes.text.trim(),
      nextAncAction: _nextAction.text.trim(),
      updatedBy: 'CHP/provider',
      updatedAt: DateTime.now(),
    );
    await ref.read(ancProfileSaveControllerProvider.notifier).save(profile);
    ref.invalidate(ancProfileProvider(widget.patientId));
    if (!mounted) return;
    final state = ref.read(ancProfileSaveControllerProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          state.hasError
              ? 'ANC profile could not be saved.'
              : 'ANC profile saved.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(ancProfileProvider(widget.patientId));
    final saveState = ref.watch(ancProfileSaveControllerProvider);
    final title = widget.patientName == null
        ? l10n.ancSpecialCases
        : '${widget.patientName} ANC profile';

    return Scaffold(
      appBar: RepairAppBar(title: title),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _AncError(message: '$error'),
        data: (profile) {
          _loadIntoForm(profile);
          final viewProfile =
              profile ?? AncProfile(patientId: widget.patientId);
          return SingleChildScrollView(
            padding: RepairInsets.scroll(context),
            child: ResponsivePageShell(
              maxWidth: RepairSizing.formMaxWidth(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AncIntroCard(
                    canManage: _canManage,
                    isEmpty: viewProfile.isEmpty,
                  ),
                  const SizedBox(height: 12),
                  if (_canManage)
                    _AncForm(
                      bloodGroup: _bloodGroup,
                      rhFactor: _rhFactor,
                      antibodyScreen: _antibodyScreen,
                      haemoglobin: _haemoglobin,
                      anaemiaStatus: _anaemiaStatus,
                      bpConcern: _bpConcern,
                      proteinuriaConcern: _proteinuriaConcern,
                      hivStatus: _hivStatus,
                      syphilisStatus: _syphilisStatus,
                      malariaIptp: _malariaIptp,
                      previousComplications: _previousComplications,
                      notes: _notes,
                      nextAction: _nextAction,
                    )
                  else
                    _AncReadOnlyProfile(profile: viewProfile),
                  if (_canManage) ...[
                    const SizedBox(height: 16),
                    RepairPrimaryButton(
                      label: 'Save ANC profile',
                      icon: Icons.save_outlined,
                      isLoading: saveState.isLoading,
                      onPressed: _save,
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(l10n.triageBack),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AncIntroCard extends StatelessWidget {
  const _AncIntroCard({required this.canManage, required this.isEmpty});

  final bool canManage;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      color: AppTheme.primary.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.assignment_turned_in_outlined,
              color: AppTheme.primary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                canManage
                    ? 'Record verified ANC special-case details for this mother. Patients can view this, but cannot edit it.'
                    : isEmpty
                    ? l10n.ancProfileEmpty
                    : l10n.ancProfileRecordedByCareTeam,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AncForm extends StatelessWidget {
  const _AncForm({
    required this.bloodGroup,
    required this.rhFactor,
    required this.antibodyScreen,
    required this.haemoglobin,
    required this.anaemiaStatus,
    required this.bpConcern,
    required this.proteinuriaConcern,
    required this.hivStatus,
    required this.syphilisStatus,
    required this.malariaIptp,
    required this.previousComplications,
    required this.notes,
    required this.nextAction,
  });

  final TextEditingController bloodGroup;
  final TextEditingController rhFactor;
  final TextEditingController antibodyScreen;
  final TextEditingController haemoglobin;
  final TextEditingController anaemiaStatus;
  final TextEditingController bpConcern;
  final TextEditingController proteinuriaConcern;
  final TextEditingController hivStatus;
  final TextEditingController syphilisStatus;
  final TextEditingController malariaIptp;
  final TextEditingController previousComplications;
  final TextEditingController notes;
  final TextEditingController nextAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _Field(controller: bloodGroup, label: 'Blood group'),
            _Field(controller: rhFactor, label: 'Rh factor'),
            _Field(controller: antibodyScreen, label: 'Antibody screen status'),
            _Field(controller: haemoglobin, label: 'Haemoglobin / Hb'),
            _Field(controller: anaemiaStatus, label: 'Anaemia status'),
            _Field(controller: bpConcern, label: 'BP concern'),
            _Field(
              controller: proteinuriaConcern,
              label: 'Proteinuria concern',
            ),
            _SensitiveField(
              controller: hivStatus,
              label: 'HIV screening status',
            ),
            _SensitiveField(
              controller: syphilisStatus,
              label: 'Syphilis screening status',
            ),
            _Field(controller: malariaIptp, label: 'Malaria / IPTp status'),
            _Field(
              controller: previousComplications,
              label: 'Previous pregnancy complications',
              minLines: 2,
            ),
            _Field(
              controller: nextAction,
              label: 'Next ANC action',
              minLines: 2,
            ),
            _Field(controller: notes, label: 'Notes', minLines: 2),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.minLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        minLines: minLines,
        maxLines: minLines == 1 ? 1 : 4,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _SensitiveField extends StatelessWidget {
  const _SensitiveField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline, size: 16, color: AppTheme.warning),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Verified status'),
          ),
        ],
      ),
    );
  }
}

class _AncReadOnlyProfile extends StatelessWidget {
  const _AncReadOnlyProfile({required this.profile});

  final AncProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = [
      ('Blood group', profile.bloodGroup),
      ('Rh factor', profile.rhFactor),
      ('Antibody screen', profile.antibodyScreenStatus),
      (
        'Haemoglobin / anaemia',
        _join(profile.haemoglobin, profile.anaemiaStatus),
      ),
      (
        'BP / proteinuria',
        _join(profile.bpConcern, profile.proteinuriaConcern),
      ),
      ('HIV screening', profile.hivScreeningStatus),
      ('Syphilis screening', profile.syphilisScreeningStatus),
      ('Malaria / IPTp', profile.malariaIptpStatus),
      ('Previous complications', profile.previousComplications),
      ('Next ANC action', profile.nextAncAction),
    ];

    if (profile.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(l10n.askProviderToUpdateAnc),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            for (final row in rows)
              if (row.$2.trim().isNotEmpty)
                _AncStatusRow(label: row.$1, value: row.$2),
            if (profile.updatedAt != null)
              _AncStatusRow(
                label: 'Updated',
                value: profile.updatedAt!.toLocal().toString().split('.').first,
              ),
          ],
        ),
      ),
    );
  }

  String _join(String a, String b) {
    final parts = [a, b].where((part) => part.trim().isNotEmpty).toList();
    return parts.join(' • ');
  }
}

class _AncStatusRow extends StatelessWidget {
  const _AncStatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _AncError extends StatelessWidget {
  const _AncError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(padding: const EdgeInsets.all(24), child: Text(message)),
    );
  }
}
