import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_ai/localization/app_localizations.dart';

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

  void clear() {
    _ref.read(triageResultProvider.notifier).state = null;
  }

  SymptomReportDraft? get currentDraft => _ref.read(symptomReportDraftProvider);
}
