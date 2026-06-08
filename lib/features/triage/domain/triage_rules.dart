import 'package:repair_ai/localization/app_localizations.dart';

import 'triage_result.dart';

/// Client-side rule engine for demo triage (not a medical diagnosis).
class TriageRules {
  static const _bleeding = 'Vaginal Bleeding';
  static const _severePain = 'Severe Abdominal Pain';
  static const _dizziness = 'Dizziness / Fainting';
  static const _reducedMovement = 'Reduced Fetal Movement';
  static const _fever = 'Fever';
  static const _spotting = 'Spotting';
  static const _cramping = 'Cramping';
  static const _nausea = 'Nausea & Vomiting';

  static TriageResult evaluate({
    required List<String> symptoms,
    required double gestationalAgeWeeks,
    required AppLocalizations l10n,
  }) {
    final set = symptoms.toSet();
    final reasons = <String>[];

    var score = 0;

    if (set.contains(_bleeding)) {
      score += 3;
      reasons.add(l10n.reasonBleeding);
    }
    if (set.contains(_severePain)) {
      score += 3;
      reasons.add(l10n.reasonSeverePain);
    }
    if (set.contains(_dizziness)) {
      score += 3;
      reasons.add(l10n.reasonDizziness);
    }
    if (set.contains(_reducedMovement) && gestationalAgeWeeks >= 20) {
      score += 3;
      reasons.add(l10n.reasonReducedMovement);
    }
    if (set.contains(_fever)) {
      score += 2;
      reasons.add(l10n.reasonFever);
    }
    if (set.contains(_spotting)) {
      score += 2;
      reasons.add(l10n.reasonSpotting);
    }
    if (set.contains(_cramping)) {
      score += 1;
      reasons.add(l10n.reasonCramping);
    }
    if (set.contains(_nausea)) {
      score += 1;
      reasons.add(l10n.reasonNausea);
    }

    if (set.length >= 3 && score < 2) {
      score += 2;
      reasons.add(l10n.reasonMultiple);
    }

    final RiskLevel level;
    int urgencyHours;
    String recommendation;

    if (score >= 5 ||
        (set.contains(_bleeding) && set.contains(_severePain)) ||
        set.contains(_dizziness)) {
      level = RiskLevel.high;
      urgencyHours = 0;
      recommendation = l10n.recHigh;
    } else if (score >= 2 || set.contains(_bleeding) || set.contains(_fever)) {
      level = RiskLevel.moderate;
      urgencyHours = 24;
      recommendation = l10n.recModerate;
    } else {
      level = RiskLevel.low;
      urgencyHours = 72;
      recommendation = l10n.recLow;
    }

    if (reasons.isEmpty) {
      reasons.add(l10n.reasonDefault);
    }

    final symptomCount = symptoms.length.clamp(1, 5);
    final confidence = (0.72 + (symptomCount * 0.05) + (score * 0.02)).clamp(
      0.72,
      0.95,
    );

    return TriageResult(
      riskLevel: level,
      confidence: confidence,
      reasons: reasons,
      recommendation: recommendation,
      urgencyHours: urgencyHours,
      needsReferral: level != RiskLevel.low,
    );
  }

  static String trimesterLabel(double weeks, AppLocalizations l10n) {
    if (weeks < 14) return l10n.trimesterFirst;
    if (weeks < 28) return l10n.trimesterSecond;
    return l10n.trimesterThird;
  }
}
