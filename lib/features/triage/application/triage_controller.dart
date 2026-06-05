import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_ai/core/network/backend_services.dart';
import 'package:repair_ai/localization/app_localizations.dart';

import '../domain/symptom_catalog.dart';
import '../domain/triage_result.dart';
import '../domain/triage_rules.dart';
import '../../../features/auth/presentation/controllers/report_history_providers.dart';

final triageResultProvider = StateProvider<TriageResult?>((ref) => null);

final triageControllerProvider = Provider<TriageController>((ref) {
  return TriageController(ref);
});

class TriageController {
  TriageController(this._ref);

  final Ref _ref;

  TriageResult runAssessment({
    required List<String> symptoms,
    required double gestationalAgeWeeks,
    required AppLocalizations l10n,
  }) {
    final result = TriageRules.evaluate(
      symptoms: symptoms,
      gestationalAgeWeeks: gestationalAgeWeeks,
      l10n: l10n,
    );
    _ref.read(triageResultProvider.notifier).state = result;
    return result;
  }

  Future<TriageResult> runBackendAssessment({
    required SymptomReportDraft draft,
    required AppLocalizations l10n,
  }) async {
    final patientApi = _ref.read(patientApiProvider);
    final visitApi = _ref.read(visitApiProvider);
    final triageApi = _ref.read(triageApiProvider);

    final profile = await patientApi.myProfile();
    final patientId = profile['id'] as int?;
    if (patientId == null) {
      throw Exception('Patient profile is missing an id.');
    }

    final symptomsText = _symptomText(draft, l10n);
    final visit = await visitApi.createVisit({
      'patient': patientId,
      'channel': 'in_person',
      'symptoms_raw': symptomsText,
      'gestation_weeks': draft.gestationalAge.round(),
    });
    final visitData = visit['visit'];
    final visitId = switch (visitData) {
      final Map<String, dynamic> data => data['id'] as int?,
      _ => visit['id'] as int?,
    };
    int? persistedTriageId;

    if (visitId != null) {
      try {
        final persisted = await triageApi.runTriage(visitId);
        final persistedResult = persisted['result'];
        if (persistedResult is Map<String, dynamic>) {
          persistedTriageId = persistedResult['id'] as int?;
        }
      } catch (_) {
        persistedTriageId = null;
      }
    }

    final data = await triageApi.deepseekAnalyze({
      'pregnancy_status': 'currently pregnant',
      'gestation_weeks': _gestationBucket(draft.gestationalAge),
      'main_symptom': draft.symptoms.isEmpty
          ? 'other'
          : SymptomCatalog.label(l10n, draft.symptoms.first),
      'symptom_duration': _durationLabel(draft.duration),
      'free_text': symptomsText,
    });

    final result = _resultFromBackend(
      data,
      l10n,
      backendTriageId: persistedTriageId,
    );
    _ref.read(triageResultProvider.notifier).state = result;
    return result;
  }

  TriageResult runLocalFallbackAssessment({
    required SymptomReportDraft draft,
    required AppLocalizations l10n,
  }) {
    final result = TriageRules.evaluate(
      symptoms: draft.symptoms,
      gestationalAgeWeeks: draft.gestationalAge,
      l10n: l10n,
    );
    _ref.read(triageResultProvider.notifier).state = result;
    return result;
  }

  void clear() {
    _ref.read(triageResultProvider.notifier).state = null;
  }

  SymptomReportDraft? get currentDraft => _ref.read(symptomReportDraftProvider);

  String _symptomText(SymptomReportDraft draft, AppLocalizations l10n) {
    final labels = draft.symptoms.map((s) => SymptomCatalog.label(l10n, s));
    final parts = [
      'Symptoms: ${labels.join(', ')}',
      'Severity: ${draft.severity}',
      'Duration: ${_durationLabel(draft.duration)}',
      'Gestation weeks: ${draft.gestationalAge.toStringAsFixed(1)}',
      if (draft.notes.trim().isNotEmpty) 'Patient notes: ${draft.notes.trim()}',
    ];
    return parts.join(' | ');
  }

  String _gestationBucket(double weeks) {
    if (weeks < 12) return 'less than 12';
    if (weeks <= 20) return '12-20';
    if (weeks <= 28) return '20-28';
    return 'more than 28';
  }

  String _durationLabel(String duration) {
    return switch (duration) {
      'today' => 'today',
      'two_days' => '2-3 days',
      'three_plus' => 'more than a week',
      _ => 'ongoing',
    };
  }

  TriageResult _resultFromBackend(
      Map<String, dynamic> data, AppLocalizations l10n,
      {int? backendTriageId}) {
    final level = switch ('${data['risk_level']}'.toLowerCase()) {
      'high' => RiskLevel.high,
      'moderate' => RiskLevel.moderate,
      _ => RiskLevel.low,
    };
    final urgency = '${data['urgency']}'.toLowerCase();
    final urgencyHours = switch (urgency) {
      'emergency' => 0,
      'urgent' => 24,
      _ => 72,
    };
    final recommendation =
        '${data['recommendation'] ?? 'Please consult your health worker.'}';
    final needsReferral = data['needs_referral'] == true;

    return TriageResult(
      riskLevel: level,
      confidence: level == RiskLevel.high ? 0.92 : 0.86,
      reasons: [
        'Backend AI screening reviewed your symptoms.',
        if (needsReferral) 'Referral support may be needed.',
        if (urgency.isNotEmpty && urgency != 'null') 'Urgency: $urgency.',
      ],
      recommendation: recommendation,
      urgencyHours: urgencyHours,
      needsReferral: needsReferral,
      aiScreened: true,
      backendTriageId: backendTriageId,
    );
  }
}
