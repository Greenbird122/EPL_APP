class AncProfile {
  const AncProfile({
    required this.patientId,
    this.patientName,
    this.bloodGroup = '',
    this.rhFactor = '',
    this.antibodyScreenStatus = '',
    this.haemoglobin = '',
    this.anaemiaStatus = '',
    this.bpConcern = '',
    this.proteinuriaConcern = '',
    this.hivScreeningStatus = '',
    this.syphilisScreeningStatus = '',
    this.malariaIptpStatus = '',
    this.previousComplications = '',
    this.notes = '',
    this.nextAncAction = '',
    this.updatedBy = '',
    this.updatedAt,
  });

  final String patientId;
  final String? patientName;
  final String bloodGroup;
  final String rhFactor;
  final String antibodyScreenStatus;
  final String haemoglobin;
  final String anaemiaStatus;
  final String bpConcern;
  final String proteinuriaConcern;
  final String hivScreeningStatus;
  final String syphilisScreeningStatus;
  final String malariaIptpStatus;
  final String previousComplications;
  final String notes;
  final String nextAncAction;
  final String updatedBy;
  final DateTime? updatedAt;

  bool get isEmpty =>
      bloodGroup.trim().isEmpty &&
      rhFactor.trim().isEmpty &&
      antibodyScreenStatus.trim().isEmpty &&
      haemoglobin.trim().isEmpty &&
      anaemiaStatus.trim().isEmpty &&
      bpConcern.trim().isEmpty &&
      proteinuriaConcern.trim().isEmpty &&
      hivScreeningStatus.trim().isEmpty &&
      syphilisScreeningStatus.trim().isEmpty &&
      malariaIptpStatus.trim().isEmpty &&
      previousComplications.trim().isEmpty &&
      nextAncAction.trim().isEmpty &&
      notes.trim().isEmpty;

  List<AncContextFlag> get contextFlags {
    final flags = <AncContextFlag>[];
    final rh = rhFactor.toLowerCase();
    final anaemia = anaemiaStatus.toLowerCase();
    final bp = bpConcern.toLowerCase();
    final protein = proteinuriaConcern.toLowerCase();

    if (rh.contains('negative')) {
      flags.add(
        const AncContextFlag(
          label: 'Rh-negative recorded',
          detail:
              'Facility follow-up may be needed during ANC or bleeding events.',
          severity: AncFlagSeverity.warning,
        ),
      );
    }
    if (anaemia.contains('severe') || anaemia.contains('low')) {
      flags.add(
        const AncContextFlag(
          label: 'Anaemia concern recorded',
          detail: 'Haemoglobin status should be considered during referral.',
          severity: AncFlagSeverity.warning,
        ),
      );
    }
    if (bp.contains('high') ||
        bp.contains('yes') ||
        protein.contains('positive') ||
        protein.contains('yes')) {
      flags.add(
        const AncContextFlag(
          label: 'BP/proteinuria concern',
          detail: 'Review for pre-eclampsia risk if symptoms are present.',
          severity: AncFlagSeverity.urgent,
        ),
      );
    }
    return flags;
  }

  AncProfile copyWith({
    String? patientId,
    String? patientName,
    String? bloodGroup,
    String? rhFactor,
    String? antibodyScreenStatus,
    String? haemoglobin,
    String? anaemiaStatus,
    String? bpConcern,
    String? proteinuriaConcern,
    String? hivScreeningStatus,
    String? syphilisScreeningStatus,
    String? malariaIptpStatus,
    String? previousComplications,
    String? notes,
    String? nextAncAction,
    String? updatedBy,
    DateTime? updatedAt,
  }) {
    return AncProfile(
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      rhFactor: rhFactor ?? this.rhFactor,
      antibodyScreenStatus: antibodyScreenStatus ?? this.antibodyScreenStatus,
      haemoglobin: haemoglobin ?? this.haemoglobin,
      anaemiaStatus: anaemiaStatus ?? this.anaemiaStatus,
      bpConcern: bpConcern ?? this.bpConcern,
      proteinuriaConcern: proteinuriaConcern ?? this.proteinuriaConcern,
      hivScreeningStatus: hivScreeningStatus ?? this.hivScreeningStatus,
      syphilisScreeningStatus:
          syphilisScreeningStatus ?? this.syphilisScreeningStatus,
      malariaIptpStatus: malariaIptpStatus ?? this.malariaIptpStatus,
      previousComplications:
          previousComplications ?? this.previousComplications,
      notes: notes ?? this.notes,
      nextAncAction: nextAncAction ?? this.nextAncAction,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'bloodGroup': bloodGroup,
      'rhFactor': rhFactor,
      'antibodyScreenStatus': antibodyScreenStatus,
      'haemoglobin': haemoglobin,
      'anaemiaStatus': anaemiaStatus,
      'bpConcern': bpConcern,
      'proteinuriaConcern': proteinuriaConcern,
      'hivScreeningStatus': hivScreeningStatus,
      'syphilisScreeningStatus': syphilisScreeningStatus,
      'malariaIptpStatus': malariaIptpStatus,
      'previousComplications': previousComplications,
      'notes': notes,
      'nextAncAction': nextAncAction,
      'updatedBy': updatedBy,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory AncProfile.fromMap(Map<dynamic, dynamic> map) {
    return AncProfile(
      patientId:
          '${map['patientId'] ?? map['patient_id'] ?? 'current-patient'}',
      patientName:
          map['patientName'] as String? ?? map['patient_name'] as String?,
      bloodGroup: '${map['bloodGroup'] ?? map['blood_group'] ?? ''}',
      rhFactor: '${map['rhFactor'] ?? map['rh_factor'] ?? ''}',
      antibodyScreenStatus:
          '${map['antibodyScreenStatus'] ?? map['antibody_screen_status'] ?? ''}',
      haemoglobin: '${map['haemoglobin'] ?? map['hemoglobin'] ?? ''}',
      anaemiaStatus: '${map['anaemiaStatus'] ?? map['anaemia_status'] ?? ''}',
      bpConcern: '${map['bpConcern'] ?? map['bp_concern'] ?? ''}',
      proteinuriaConcern:
          '${map['proteinuriaConcern'] ?? map['proteinuria_concern'] ?? ''}',
      hivScreeningStatus:
          '${map['hivScreeningStatus'] ?? map['hiv_screening_status'] ?? ''}',
      syphilisScreeningStatus:
          '${map['syphilisScreeningStatus'] ?? map['syphilis_screening_status'] ?? ''}',
      malariaIptpStatus:
          '${map['malariaIptpStatus'] ?? map['malaria_iptp_status'] ?? ''}',
      previousComplications:
          '${map['previousComplications'] ?? map['previous_complications'] ?? ''}',
      notes: '${map['notes'] ?? ''}',
      nextAncAction: '${map['nextAncAction'] ?? map['next_anc_action'] ?? ''}',
      updatedBy: '${map['updatedBy'] ?? map['updated_by'] ?? ''}',
      updatedAt: _parseDate(map['updatedAt'] ?? map['updated_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse('$value');
  }
}

class AncContextFlag {
  const AncContextFlag({
    required this.label,
    required this.detail,
    required this.severity,
  });

  final String label;
  final String detail;
  final AncFlagSeverity severity;
}

enum AncFlagSeverity { warning, urgent }

enum AncProfileMode { patientReadOnly, providerManage }
