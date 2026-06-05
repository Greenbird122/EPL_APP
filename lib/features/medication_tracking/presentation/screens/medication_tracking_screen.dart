import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/responsive.dart';
import 'package:repair_ai/features/medication_tracking/domain/medication_model.dart';
import 'package:repair_ai/features/medication_tracking/presentation/controllers/medication_registry_controller.dart';
import 'package:repair_ai/shared/widgets/responsive_page.dart';

enum MedicationTrackingMode {
  patientReadOnly,
  providerManage,
}

class MedicationTrackingScreen extends ConsumerWidget {
  const MedicationTrackingScreen({
    super.key,
    this.mode = MedicationTrackingMode.patientReadOnly,
    this.patientId = 'current-patient',
    this.patientName,
  });

  final MedicationTrackingMode mode;
  final String patientId;
  final String? patientName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManage = mode == MedicationTrackingMode.providerManage;
    final title = canManage
        ? '${patientName ?? 'Patient'} medication registry'
        : 'Treatment & supplement tracker';

    if (!canManage) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: MedicationDashboardView(
          patientId: patientId,
          patientName: patientName,
          canManage: false,
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Dashboard'),
              Tab(icon: Icon(Icons.add_circle_outline), text: 'Register'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            MedicationDashboardView(
              patientId: patientId,
              patientName: patientName,
              canManage: true,
            ),
            MedicationEntryFormView(
              patientId: patientId,
              patientName: patientName,
              canManage: true,
            ),
          ],
        ),
      ),
    );
  }
}

class MedicationEntryFormView extends ConsumerStatefulWidget {
  const MedicationEntryFormView({
    super.key,
    required this.patientId,
    required this.canManage,
    this.patientName,
  });

  final String patientId;
  final String? patientName;
  final bool canManage;

  @override
  ConsumerState<MedicationEntryFormView> createState() =>
      _MedicationEntryFormViewState();
}

class _MedicationEntryFormViewState
    extends ConsumerState<MedicationEntryFormView> {
  final _formKey = GlobalKey<FormState>();
  final _drugNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _periodController = TextEditingController();
  final _instructionsController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _drugNameController.dispose();
    _quantityController.dispose();
    _periodController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      await ref
          .read(medicationRegistryControllerProvider.notifier)
          .addMedication(
            patientId: widget.patientId,
            patientName: widget.patientName,
            canManage: widget.canManage,
            drugName: _drugNameController.text,
            totalAmountIssued: int.parse(_quantityController.text),
            periodDays: int.parse(_periodController.text),
            prescriptionInstructions: _instructionsController.text,
          );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    _formKey.currentState?.reset();
    _drugNameController.clear();
    _quantityController.clear();
    _periodController.clear();
    _instructionsController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medication registered successfully.')),
    );
    DefaultTabController.of(context).animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: RepairInsets.page(context).copyWith(
        bottom: viewInsets.bottom + 24,
      ),
      child: ResponsivePageShell(
        maxWidth: RepairSizing.formMaxWidth(context),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Register issued medicine',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Log tablets issued to a patient. Remaining tablets are calculated automatically from the registration date.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _drugNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Drug name',
                  hintText: 'Iron and Zinc Tablets',
                  prefixIcon: Icon(Icons.medication_outlined),
                ),
                validator: (value) {
                  if ((value ?? '').trim().length < 2) {
                    return 'Enter the medicine name.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Total quantity issued',
                  hintText: '30',
                  prefixIcon: Icon(Icons.numbers_outlined),
                ),
                validator: _positiveIntegerValidator,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _periodController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Duration in days',
                  hintText: '30',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
                validator: _positiveIntegerValidator,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _instructionsController,
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Prescription instructions',
                  hintText: 'Take 1 tablet daily after meals.',
                  prefixIcon: Icon(Icons.receipt_long_outlined),
                ),
                validator: (value) {
                  if ((value ?? '').trim().length < 3) {
                    return 'Enter patient-facing prescription instructions.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Save record'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _positiveIntegerValidator(String? value) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null || parsed <= 0) return 'Enter a number greater than 0.';
    return null;
  }
}

class MedicationDashboardView extends ConsumerStatefulWidget {
  const MedicationDashboardView({
    super.key,
    required this.patientId,
    required this.canManage,
    this.patientName,
  });

  final String patientId;
  final String? patientName;
  final bool canManage;

  @override
  ConsumerState<MedicationDashboardView> createState() =>
      _MedicationDashboardViewState();
}

class _MedicationDashboardViewState
    extends ConsumerState<MedicationDashboardView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_loadMedications);
  }

  @override
  void didUpdateWidget(covariant MedicationDashboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patientId != widget.patientId) {
      Future.microtask(_loadMedications);
    }
  }

  Future<void> _loadMedications() {
    return ref
        .read(medicationRegistryControllerProvider.notifier)
        .loadMedications(patientId: widget.patientId);
  }

  @override
  Widget build(BuildContext context) {
    final medications = ref.watch(medicationRegistryControllerProvider);

    return medications.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text('Could not load medication records: $error'),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return _EmptyMedicationState(
            canManage: widget.canManage,
            patientName: widget.patientName,
          );
        }
        return RefreshIndicator(
          onRefresh: _loadMedications,
          child: ListView(
            padding: RepairInsets.scroll(context),
            children: [
              ResponsivePageShell(
                maxWidth: RepairSizing.formMaxWidth(context),
                child: Column(
                  children: [
                    for (final item in items) MedicationCard(medication: item),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MedicationCard extends StatelessWidget {
  const MedicationCard({super.key, required this.medication});

  final MedicationModel medication;

  @override
  Widget build(BuildContext context) {
    final completed = medication.isCompleted;
    final progressColor = completed
        ? AppTheme.error
        : medication.remainingFraction <= 0.25
            ? AppTheme.warning
            : AppTheme.success;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: progressColor.withValues(alpha: 0.12),
                  child: Icon(Icons.medication_liquid, color: progressColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.drugName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${medication.dailyDosage} tab/day • ${medication.periodDays} days',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(
                  status: medication.effectiveStatus,
                  color: progressColor,
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: medication.remainingFraction,
                minHeight: 9,
                color: progressColor,
                backgroundColor: progressColor.withValues(alpha: 0.14),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 4,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                  '${medication.remainingTablets} / ${medication.totalAmountIssued} tablets remaining',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${medication.daysLeft} days left',
                  style: TextStyle(
                    color: completed
                        ? AppTheme.error
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if ((medication.prescriptionInstructions ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 18,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        medication.prescriptionInstructions!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          height: 1.32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (completed) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.error.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.error.withValues(alpha: 0.32),
                  ),
                ),
                child: const Text(
                  'Inventory depleted. Treatment is marked as completed.',
                  style: TextStyle(
                    color: AppTheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.color});

  final String status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 104),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyMedicationState extends StatelessWidget {
  const _EmptyMedicationState({
    required this.canManage,
    this.patientName,
  });

  final bool canManage;
  final String? patientName;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: RepairInsets.scroll(context),
      children: [
        ResponsivePageShell(
          maxWidth: RepairSizing.formMaxWidth(context),
          child: Column(
            children: [
              SizedBox(
                  height: RepairBreakpoints.isShortScreen(context) ? 28 : 72),
              Icon(
                Icons.inventory_2_outlined,
                size: 72,
                color: AppTheme.primary.withValues(alpha: 0.55),
              ),
              const SizedBox(height: 18),
              Text(
                canManage
                    ? 'No medication has been registered for this patient yet.'
                    : 'No medicine has been registered for you yet.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                canManage
                    ? 'Use the Register tab to add issued tablets and prescription instructions for ${patientName ?? 'this patient'}.'
                    : 'Your care team will add issued medicine and prescription instructions when available.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
