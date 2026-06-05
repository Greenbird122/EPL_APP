enum MedicationStatus {
  active('Active'),
  completed('Completed'),
  paused('Paused');

  const MedicationStatus(this.label);

  final String label;

  static MedicationStatus fromLabel(String value) {
    return MedicationStatus.values.firstWhere(
      (status) => status.label.toLowerCase() == value.toLowerCase(),
      orElse: () => MedicationStatus.active,
    );
  }
}

class MedicationModel {
  const MedicationModel({
    required this.id,
    required this.patientId,
    required this.drugName,
    required this.totalAmountIssued,
    required this.periodDays,
    required this.registrationDate,
    this.patientName,
    this.prescriptionInstructions,
    this.status = 'Active',
  });

  final String id;
  final String patientId;
  final String? patientName;
  final String drugName;
  final int totalAmountIssued;
  final int periodDays;
  final DateTime registrationDate;
  final String? prescriptionInstructions;
  final String status;

  int get dailyDosage {
    if (periodDays <= 0) return 1;
    final dosage = totalAmountIssued ~/ periodDays;
    return dosage <= 0 ? 1 : dosage;
  }

  int get daysElapsed {
    final elapsed = DateTime.now().difference(registrationDate).inDays;
    return elapsed < 0 ? 0 : elapsed;
  }

  int get remainingTablets {
    final consumed = daysElapsed * dailyDosage;
    final remaining = totalAmountIssued - consumed;
    return remaining.clamp(0, totalAmountIssued);
  }

  int get daysLeft {
    if (remainingTablets == 0) return 0;
    return (remainingTablets / dailyDosage).ceil();
  }

  double get remainingFraction {
    if (totalAmountIssued <= 0) return 0;
    return (remainingTablets / totalAmountIssued).clamp(0, 1);
  }

  MedicationStatus get resolvedStatus {
    if (remainingTablets == 0) return MedicationStatus.completed;
    return MedicationStatus.fromLabel(status);
  }

  String get effectiveStatus => resolvedStatus.label;

  bool get isCompleted => resolvedStatus == MedicationStatus.completed;

  MedicationModel copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? drugName,
    int? totalAmountIssued,
    int? periodDays,
    DateTime? registrationDate,
    String? prescriptionInstructions,
    String? status,
  }) {
    return MedicationModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      drugName: drugName ?? this.drugName,
      totalAmountIssued: totalAmountIssued ?? this.totalAmountIssued,
      periodDays: periodDays ?? this.periodDays,
      registrationDate: registrationDate ?? this.registrationDate,
      prescriptionInstructions:
          prescriptionInstructions ?? this.prescriptionInstructions,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'patientName': patientName,
      'drugName': drugName,
      'totalAmountIssued': totalAmountIssued,
      'periodDays': periodDays,
      'registrationDate': registrationDate.toIso8601String(),
      'prescriptionInstructions': prescriptionInstructions,
      'status': effectiveStatus,
    };
  }

  factory MedicationModel.fromMap(Map<dynamic, dynamic> map) {
    return MedicationModel(
      id: map['id'] as String,
      patientId: map['patientId'] as String? ?? 'legacy-general',
      patientName: map['patientName'] as String?,
      drugName: map['drugName'] as String,
      totalAmountIssued: map['totalAmountIssued'] as int,
      periodDays: map['periodDays'] as int,
      registrationDate: DateTime.parse(map['registrationDate'] as String),
      prescriptionInstructions: map['prescriptionInstructions'] as String?,
      status: map['status'] as String? ?? MedicationStatus.active.label,
    );
  }
}
