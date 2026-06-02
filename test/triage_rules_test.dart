import 'package:flutter_test/flutter_test.dart';
import 'package:repair_ai/features/triage/domain/triage_result.dart';
import 'package:repair_ai/features/triage/domain/triage_rules.dart';
import 'package:repair_ai/localization/languages/app_localizations_en.dart';

void main() {
  final l10n = AppLocalizationsEn('en');

  group('TriageRules', () {
    test('high risk for bleeding and severe pain', () {
      final result = TriageRules.evaluate(
        symptoms: ['Vaginal Bleeding', 'Severe Abdominal Pain'],
        gestationalAgeWeeks: 8,
        l10n: l10n,
      );
      expect(result.riskLevel, RiskLevel.high);
      expect(result.urgencyHours, 0);
      expect(result.reasons, isNotEmpty);
    });

    test('moderate risk for bleeding alone', () {
      final result = TriageRules.evaluate(
        symptoms: ['Vaginal Bleeding'],
        gestationalAgeWeeks: 10,
        l10n: l10n,
      );
      expect(result.riskLevel, RiskLevel.moderate);
    });

    test('low risk for single mild symptom', () {
      final result = TriageRules.evaluate(
        symptoms: ['Cramping'],
        gestationalAgeWeeks: 8,
        l10n: l10n,
      );
      expect(result.riskLevel, RiskLevel.low);
      expect(result.confidence, greaterThanOrEqualTo(0.72));
    });

    test('nausea contributes to assessment', () {
      final result = TriageRules.evaluate(
        symptoms: ['Nausea & Vomiting'],
        gestationalAgeWeeks: 12,
        l10n: l10n,
      );
      expect(result.reasons, contains(l10n.reasonNausea));
    });
  });
}
