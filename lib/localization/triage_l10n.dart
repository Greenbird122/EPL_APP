import 'app_localizations.dart';
import '../features/triage/domain/triage_result.dart';

extension TriageL10n on AppLocalizations {
  String riskLabel(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return riskLow;
      case RiskLevel.moderate:
        return riskModerate;
      case RiskLevel.high:
        return riskHigh;
    }
  }

  RiskLevel? riskFromStored(String stored) {
    switch (stored.toLowerCase()) {
      case 'low':
        return RiskLevel.low;
      case 'moderate':
        return RiskLevel.moderate;
      case 'high':
        return RiskLevel.high;
      default:
        if (stored == riskLow) return RiskLevel.low;
        if (stored == riskModerate) return RiskLevel.moderate;
        if (stored == riskHigh) return RiskLevel.high;
        return null;
    }
  }

  String trimesterLabel(double weeks) {
    if (weeks < 14) return trimesterFirst;
    if (weeks < 28) return trimesterSecond;
    return trimesterThird;
  }
}
