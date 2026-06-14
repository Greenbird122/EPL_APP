import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// Where a triage case sits in its lifecycle.
enum TriageCaseStatus {
  active,
  analyzing,
  completed,
  referred;

  String toJson() => name;

  static TriageCaseStatus fromJson(String value) {
    return TriageCaseStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TriageCaseStatus.active,
    );
  }
}

/// The kind of chat message within a triage case.
enum CaseMessageType {
  text,
  symptomReport,
  riskAssessment,
  referral,
  recommendation;

  String toJson() => name;

  static CaseMessageType fromJson(String value) {
    return CaseMessageType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CaseMessageType.text,
    );
  }
}

// ---------------------------------------------------------------------------
// CaseMessage
// ---------------------------------------------------------------------------

/// A single chat message within a [TriageCase].
class CaseMessage {
  final String id;
  final String sender; // 'patient', 'ai', 'provider'
  final String text;
  final DateTime timestamp;
  final CaseMessageType type;

  const CaseMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.timestamp,
    required this.type,
  });

  /// Creates a new message with an auto-generated UUID and the current time.
  factory CaseMessage.now({
    required String sender,
    required String text,
    CaseMessageType type = CaseMessageType.text,
  }) {
    return CaseMessage(
      id: _uuid.v4(),
      sender: sender,
      text: text,
      timestamp: DateTime.now(),
      type: type,
    );
  }

  factory CaseMessage.fromJson(Map<String, dynamic> json) {
    return CaseMessage(
      id: json['id'] as String? ?? _uuid.v4(),
      sender: json['sender'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: CaseMessageType.fromJson(json['type'] as String? ?? 'text'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toJson(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaseMessage && id == other.id && timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(id, timestamp);

  @override
  String toString() => 'CaseMessage(id: $id, sender: $sender, type: $type)';
}

// ---------------------------------------------------------------------------
// RiskSnapshot
// ---------------------------------------------------------------------------

/// A point-in-time risk assessment within a triage case's lifecycle.
class RiskSnapshot {
  final String stage; // "Open", "Update 1", "Update 2", "Update 3", "Triage"
  final double riskScore; // 0-100
  final DateTime timestamp;

  const RiskSnapshot({
    required this.stage,
    required this.riskScore,
    required this.timestamp,
  });

  factory RiskSnapshot.fromJson(Map<String, dynamic> json) {
    return RiskSnapshot(
      stage: json['stage'] as String,
      riskScore: (json['riskScore'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stage': stage,
      'riskScore': riskScore,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RiskSnapshot &&
          stage == other.stage &&
          riskScore == other.riskScore &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(stage, riskScore, timestamp);

  @override
  String toString() => 'RiskSnapshot(stage: $stage, score: $riskScore)';
}

// ---------------------------------------------------------------------------
// CaseVariableReading
// ---------------------------------------------------------------------------

/// A physiological variable reading recorded during a triage case.
class CaseVariableReading {
  final String id;
  final String
      variableName; // 'blood_pressure_systolic', 'blood_pressure_diastolic', 'heart_rate', 'pain_level', 'hydration_ml', 'sleep_hours'
  final double value;
  final DateTime timestamp;

  const CaseVariableReading({
    required this.id,
    required this.variableName,
    required this.value,
    required this.timestamp,
  });

  factory CaseVariableReading.now({
    required String variableName,
    required double value,
  }) {
    return CaseVariableReading(
      id: _uuid.v4(),
      variableName: variableName,
      value: value,
      timestamp: DateTime.now(),
    );
  }

  factory CaseVariableReading.fromJson(Map<String, dynamic> json) {
    return CaseVariableReading(
      id: json['id'] as String? ?? _uuid.v4(),
      variableName: json['variableName'] as String,
      value: (json['value'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'variableName': variableName,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CaseVariableReading &&
          id == other.id &&
          timestamp == other.timestamp;

  @override
  int get hashCode => Object.hash(id, timestamp);

  @override
  String toString() =>
      'CaseVariableReading(variable: $variableName, value: $value)';
}

// ---------------------------------------------------------------------------
// TriageCase
// ---------------------------------------------------------------------------

/// A single symptom-check case. Created when a patient submits symptoms,
/// updated as the AI processes and generates recommendations.
class TriageCase {
  static int _counter = 0;
  final String id;
  final int caseNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  final TriageCaseStatus status;
  final String patientName;
  final double gestationalAgeWeeks;
  final List<String> symptoms;
  final String severity; // mild, moderate, severe
  final String duration; // today, two_days, three_plus
  final String? notes;
  final String? riskLevel; // low, moderate, high (set after analysis)
  final double? confidence; // AI confidence 0.0 – 1.0
  final String? recommendation;
  final String? facilityName; // if referred
  final List<CaseMessage> messages;
  final List<RiskSnapshot> riskHistory;
  final List<CaseVariableReading> variableReadings;
  final int? backendVisitId; // Set when the case is synced to the backend.

  /// Formatted case number, e.g. "CASE-42".
  String get formattedCaseNumber => 'CASE-$caseNumber';

  const TriageCase({
    required this.id,
    required this.caseNumber,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    required this.patientName,
    required this.gestationalAgeWeeks,
    required this.symptoms,
    required this.severity,
    required this.duration,
    this.notes,
    this.riskLevel,
    this.confidence,
    this.recommendation,
    this.facilityName,
    this.messages = const [],
    this.riskHistory = const [],
    this.variableReadings = const [],
    this.backendVisitId,
  });

  /// Creates a new case with an auto-generated UUID, timestamps set to now,
  /// and [status] defaulting to [TriageCaseStatus.active].
  factory TriageCase.create({
    required String patientName,
    required double gestationalAgeWeeks,
    required List<String> symptoms,
    String severity = 'mild',
    String duration = 'today',
    String? notes,
    List<CaseMessage> messages = const [],
    List<RiskSnapshot> riskHistory = const [],
    List<CaseVariableReading> variableReadings = const [],
  }) {
    _counter++;
    final now = DateTime.now();
    return TriageCase(
      id: _uuid.v4(),
      caseNumber: _counter,
      createdAt: now,
      updatedAt: now,
      status: TriageCaseStatus.active,
      patientName: patientName,
      gestationalAgeWeeks: gestationalAgeWeeks,
      symptoms: List.unmodifiable(symptoms),
      severity: severity,
      duration: duration,
      notes: notes,
      messages: messages,
      riskHistory: riskHistory,
      variableReadings: variableReadings,
      backendVisitId: null,
    );
  }

  factory TriageCase.fromJson(Map<String, dynamic> json) {
    final caseNumber = json['caseNumber'] as int?;
    if (caseNumber != null && caseNumber > _counter) {
      _counter = caseNumber;
    }
    return TriageCase(
      id: json['id'] as String? ?? _uuid.v4(),
      caseNumber: caseNumber ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      status: TriageCaseStatus.fromJson(json['status'] as String? ?? 'active'),
      patientName: json['patientName'] as String,
      gestationalAgeWeeks: (json['gestationalAgeWeeks'] as num).toDouble(),
      symptoms: List<String>.from(json['symptoms'] as List),
      severity: json['severity'] as String? ?? 'mild',
      duration: json['duration'] as String? ?? 'today',
      notes: json['notes'] as String?,
      riskLevel: json['riskLevel'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      recommendation: json['recommendation'] as String?,
      facilityName: json['facilityName'] as String?,
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => CaseMessage.fromJson(m as Map<String, dynamic>))
              .toList(growable: false) ??
          const [],
      riskHistory: (json['riskHistory'] as List<dynamic>?)
              ?.map((s) => RiskSnapshot.fromJson(s as Map<String, dynamic>))
              .toList(growable: false) ??
          const [],
      variableReadings: (json['variableReadings'] as List<dynamic>?)
              ?.map((r) =>
                  CaseVariableReading.fromJson(r as Map<String, dynamic>))
              .toList(growable: false) ??
          const [],
      backendVisitId: json['backendVisitId'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caseNumber': caseNumber,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'status': status.toJson(),
      'patientName': patientName,
      'gestationalAgeWeeks': gestationalAgeWeeks,
      'symptoms': symptoms,
      'severity': severity,
      'duration': duration,
      if (notes != null) 'notes': notes,
      if (riskLevel != null) 'riskLevel': riskLevel,
      if (confidence != null) 'confidence': confidence,
      if (recommendation != null) 'recommendation': recommendation,
      if (facilityName != null) 'facilityName': facilityName,
      'messages': messages.map((m) => m.toJson()).toList(growable: false),
      'riskHistory': riskHistory.map((s) => s.toJson()).toList(growable: false),
      'variableReadings':
          variableReadings.map((r) => r.toJson()).toList(growable: false),
      if (backendVisitId != null) 'backendVisitId': backendVisitId,
    };
  }

  TriageCase copyWith({
    String? id,
    int? caseNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
    TriageCaseStatus? status,
    String? patientName,
    double? gestationalAgeWeeks,
    List<String>? symptoms,
    String? severity,
    String? duration,
    String? Function()? notes,
    String? Function()? riskLevel,
    double? Function()? confidence,
    String? Function()? recommendation,
    String? Function()? facilityName,
    List<CaseMessage>? messages,
    List<RiskSnapshot>? riskHistory,
    List<CaseVariableReading>? variableReadings,
    int? Function()? backendVisitId,
  }) {
    return TriageCase(
      id: id ?? this.id,
      caseNumber: caseNumber ?? this.caseNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      patientName: patientName ?? this.patientName,
      gestationalAgeWeeks: gestationalAgeWeeks ?? this.gestationalAgeWeeks,
      symptoms: symptoms ?? this.symptoms,
      severity: severity ?? this.severity,
      duration: duration ?? this.duration,
      notes: notes != null ? notes() : this.notes,
      riskLevel: riskLevel != null ? riskLevel() : this.riskLevel,
      confidence: confidence != null ? confidence() : this.confidence,
      recommendation:
          recommendation != null ? recommendation() : this.recommendation,
      facilityName: facilityName != null ? facilityName() : this.facilityName,
      messages: messages ?? this.messages,
      riskHistory: riskHistory ?? this.riskHistory,
      variableReadings: variableReadings ?? this.variableReadings,
      backendVisitId:
          backendVisitId != null ? backendVisitId() : this.backendVisitId,
    );
  }

  // Convenience ------------------------------------------------------------------

  /// Whether this case still needs attention (not completed / referred).
  bool get isOpen =>
      status == TriageCaseStatus.active || status == TriageCaseStatus.analyzing;

  /// The latest message, or `null` when the conversation is empty.
  CaseMessage? get latestMessage => messages.isNotEmpty ? messages.last : null;

  /// Pushes one message onto the conversation and bumps [updatedAt].
  TriageCase addMessage(CaseMessage message) {
    return copyWith(
      updatedAt: DateTime.now(),
      messages: [...messages, message],
    );
  }

  /// Adds a physiological variable reading and returns a new [TriageCase].
  TriageCase addVariableReading(String name, double value) {
    final reading = CaseVariableReading.now(
      variableName: name,
      value: value,
    );
    return copyWith(
      updatedAt: DateTime.now(),
      variableReadings: [...variableReadings, reading],
    );
  }

  /// Appends a risk snapshot and returns a new [TriageCase] with it.
  TriageCase addRiskSnapshot(String stage, double score) {
    final snapshot = RiskSnapshot(
      stage: stage,
      riskScore: score,
      timestamp: DateTime.now(),
    );
    return copyWith(
      updatedAt: DateTime.now(),
      riskHistory: [...riskHistory, snapshot],
    );
  }

  /// Marks the case as completed / referred based on the resolved risk level.
  TriageCase resolve({
    required String riskLevel,
    required double confidence,
    required String recommendation,
    String? facilityName,
  }) {
    final needsReferral =
        riskLevel == 'high' && facilityName != null && facilityName.isNotEmpty;

    return copyWith(
      updatedAt: DateTime.now(),
      status: needsReferral
          ? TriageCaseStatus.referred
          : TriageCaseStatus.completed,
      riskLevel: () => riskLevel,
      confidence: () => confidence,
      recommendation: () => recommendation,
      facilityName: () => facilityName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TriageCase &&
          id == other.id &&
          updatedAt == other.updatedAt &&
          backendVisitId == other.backendVisitId;

  @override
  int get hashCode => Object.hash(id, updatedAt, backendVisitId);

  @override
  String toString() =>
      'TriageCase(id: $id, patient: $patientName, status: $status)';
}

// ---------------------------------------------------------------------------
// TriageAnalytics
// ---------------------------------------------------------------------------

/// Live analytics snapshot for the right sidebar, computed from a list of
/// [TriageCase] instances.
class TriageAnalytics {
  final String riskLevel; // low, moderate, high
  final double riskScore; // 0.0 – 1.0
  final int activeCases;
  final int totalCases;
  final int referralsSent;
  final int completedCases;
  final Map<String, int> symptomFrequency;
  final List<String> recentRecommendations;

  const TriageAnalytics({
    required this.riskLevel,
    required this.riskScore,
    required this.activeCases,
    required this.totalCases,
    required this.referralsSent,
    required this.completedCases,
    required this.symptomFrequency,
    required this.recentRecommendations,
  });

  /// Derives aggregate analytics from a list of cases.
  factory TriageAnalytics.fromCases(List<TriageCase> cases) {
    if (cases.isEmpty) {
      return const TriageAnalytics(
        riskLevel: 'low',
        riskScore: 0.0,
        activeCases: 0,
        totalCases: 0,
        referralsSent: 0,
        completedCases: 0,
        symptomFrequency: {},
        recentRecommendations: [],
      );
    }

    final activeCases =
        cases.where((c) => c.status == TriageCaseStatus.active).length;
    final referralsSent =
        cases.where((c) => c.status == TriageCaseStatus.referred).length;
    final completedCases =
        cases.where((c) => c.status == TriageCaseStatus.completed).length;

    // Accumulate symptom frequency across all cases.
    final symptomFrequency = <String, int>{};
    for (final c in cases) {
      for (final s in c.symptoms) {
        symptomFrequency[s] = (symptomFrequency[s] ?? 0) + 1;
      }
    }

    // Aggregate risk scores from cases that have a confidence value.
    final scoredCases = cases.where((c) => c.confidence != null);
    final riskScore = scoredCases.isNotEmpty
        ? scoredCases.fold<double>(0, (sum, c) => sum + c.confidence!) /
            scoredCases.length
        : 0.0;

    // Determine overall risk level from the majority of completed / referred.
    final resolvedCases =
        cases.where((c) => c.riskLevel != null && c.riskLevel!.isNotEmpty);
    final highCount = resolvedCases.where((c) => c.riskLevel == 'high').length;
    final moderateCount =
        resolvedCases.where((c) => c.riskLevel == 'moderate').length;
    final lowCount = resolvedCases.where((c) => c.riskLevel == 'low').length;

    String riskLevel;
    if (highCount >= moderateCount && highCount >= lowCount) {
      riskLevel = 'high';
    } else if (moderateCount >= lowCount) {
      riskLevel = 'moderate';
    } else {
      riskLevel = 'low';
    }

    // Collect the 5 most recent non-null recommendations.
    final recentRecommendations = cases
        .where((c) => c.recommendation != null)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final recommendations = recentRecommendations
        .take(5)
        .map((c) => c.recommendation!)
        .toList(growable: false);

    return TriageAnalytics(
      riskLevel: riskLevel,
      riskScore: riskScore,
      activeCases: activeCases,
      totalCases: cases.length,
      referralsSent: referralsSent,
      completedCases: completedCases,
      symptomFrequency: symptomFrequency,
      recentRecommendations: recommendations,
    );
  }

  factory TriageAnalytics.fromJson(Map<String, dynamic> json) {
    return TriageAnalytics(
      riskLevel: json['riskLevel'] as String? ?? 'low',
      riskScore: (json['riskScore'] as num?)?.toDouble() ?? 0.0,
      activeCases: json['activeCases'] as int? ?? 0,
      totalCases: json['totalCases'] as int? ?? 0,
      referralsSent: json['referralsSent'] as int? ?? 0,
      completedCases: json['completedCases'] as int? ?? 0,
      symptomFrequency:
          (json['symptomFrequency'] as Map<String, dynamic>?)?.map(
                (k, v) => MapEntry(k, v as int),
              ) ??
              {},
      recentRecommendations: (json['recentRecommendations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(growable: false) ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'riskLevel': riskLevel,
      'riskScore': riskScore,
      'activeCases': activeCases,
      'totalCases': totalCases,
      'referralsSent': referralsSent,
      'completedCases': completedCases,
      'symptomFrequency': symptomFrequency,
      'recentRecommendations': recentRecommendations,
    };
  }

  @override
  String toString() =>
      'TriageAnalytics(riskLevel: $riskLevel, totalCases: $totalCases)';
}
