import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_ai/features/medication_tracking/data/medication_repository.dart';
import 'package:repair_ai/features/medication_tracking/domain/medication_model.dart';
import 'package:uuid/uuid.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepository();
});

final medicationRegistryControllerProvider = StateNotifierProvider<
    MedicationRegistryController, AsyncValue<List<MedicationModel>>>((ref) {
  return MedicationRegistryController(ref.watch(medicationRepositoryProvider));
});

class MedicationRegistryController
    extends StateNotifier<AsyncValue<List<MedicationModel>>> {
  MedicationRegistryController(this._repository)
      : super(const AsyncValue.loading()) {
    loadMedications();
  }

  final MedicationRepository _repository;
  final _uuid = const Uuid();
  String? _activePatientId;

  Future<void> loadMedications({String? patientId}) async {
    _activePatientId = patientId ?? _activePatientId;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.fetchMedications(patientId: _activePatientId),
    );
  }

  Future<void> addMedication({
    required String patientId,
    required bool canManage,
    required String drugName,
    required int totalAmountIssued,
    required int periodDays,
    String? patientName,
    String? prescriptionInstructions,
  }) async {
    if (!canManage) {
      throw StateError('Only CHP/provider users can register medication.');
    }
    final medication = MedicationModel(
      id: _uuid.v4(),
      patientId: patientId,
      patientName: patientName,
      drugName: drugName.trim(),
      totalAmountIssued: totalAmountIssued,
      periodDays: periodDays,
      registrationDate: DateTime.now(),
      prescriptionInstructions: prescriptionInstructions?.trim(),
    );
    await _repository.saveMedication(medication);
    await loadMedications(patientId: patientId);
  }

  Future<void> updateStatus(String id, MedicationStatus status) async {
    await _repository.updateStatus(id, status);
    await loadMedications();
  }
}
