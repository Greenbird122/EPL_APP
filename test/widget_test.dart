import 'package:flutter_test/flutter_test.dart';
import 'package:repair_ai/features/triage/domain/triage_result.dart';
import 'package:repair_ai/features/triage/domain/triage_rules.dart';
import 'package:repair_ai/localization/languages/app_localizations_en.dart';

void main() {
  testWidgets('Smoke test', (tester) async {
    expect(true, isTrue);
  });

  test('widget test imports triage rules', () {
    final l10n = AppLocalizationsEn('en');
    final r = TriageRules.evaluate(
      symptoms: ['Fever'],
      gestationalAgeWeeks: 12,
      l10n: l10n,
    );
    expect(r.riskLevel, isA<RiskLevel>());
  });
}
