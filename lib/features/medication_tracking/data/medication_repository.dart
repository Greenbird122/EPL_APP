import 'package:hive_flutter/hive_flutter.dart';
import 'package:repair_ai/features/medication_tracking/domain/medication_model.dart';

class MedicationRepository {
  static const _boxName = 'medication_registry';
  static bool _hiveReady = false;

  Future<Box<dynamic>> _openBox() async {
    if (!_hiveReady) {
      await Hive.initFlutter();
      _hiveReady = true;
    }
    if (Hive.isBoxOpen(_boxName)) return Hive.box<dynamic>(_boxName);
    return Hive.openBox<dynamic>(_boxName);
  }

  Future<List<MedicationModel>> fetchMedications({String? patientId}) async {
    final box = await _openBox();
    final medications =
        box.values
            .whereType<Map<dynamic, dynamic>>()
            .map(MedicationModel.fromMap)
            .where(
              (medication) =>
                  patientId == null || medication.patientId == patientId,
            )
            .map(_withComputedStatus)
            .toList()
          ..sort((a, b) => b.registrationDate.compareTo(a.registrationDate));

    await _persistComputedStatuses(box, medications);
    return medications;
  }

  Future<void> saveMedication(MedicationModel medication) async {
    final box = await _openBox();
    await box.put(medication.id, medication.toMap());
  }

  Future<void> updateStatus(String id, MedicationStatus status) async {
    final box = await _openBox();
    final raw = box.get(id);
    if (raw is! Map) return;
    final medication = MedicationModel.fromMap(raw);
    await box.put(id, medication.copyWith(status: status.label).toMap());
  }

  MedicationModel _withComputedStatus(MedicationModel medication) {
    if (medication.remainingTablets == 0 &&
        medication.status != MedicationStatus.completed.label) {
      return medication.copyWith(status: MedicationStatus.completed.label);
    }
    return medication;
  }

  Future<void> _persistComputedStatuses(
    Box<dynamic> box,
    List<MedicationModel> medications,
  ) async {
    for (final medication in medications) {
      if (medication.status == MedicationStatus.completed.label) {
        await box.put(medication.id, medication.toMap());
      }
    }
  }
}
