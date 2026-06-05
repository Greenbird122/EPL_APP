import 'package:flutter/material.dart';
import 'package:repair_ai/core/config/themes.dart';

enum RiskLevel { low, moderate, high }

extension RiskLevelX on RiskLevel {
  /// Storage key for report history (locale-independent).
  String get storageKey {
    switch (this) {
      case RiskLevel.low:
        return 'low';
      case RiskLevel.moderate:
        return 'moderate';
      case RiskLevel.high:
        return 'high';
    }
  }

  Color get color {
    switch (this) {
      case RiskLevel.low:
        return AppTheme.success;
      case RiskLevel.moderate:
        return AppTheme.warning;
      case RiskLevel.high:
        return AppTheme.error;
    }
  }
}

class TriageResult {
  const TriageResult({
    required this.riskLevel,
    required this.confidence,
    required this.reasons,
    required this.recommendation,
    required this.urgencyHours,
    this.needsReferral = false,
    this.aiScreened = false,
    this.backendTriageId,
  });

  final RiskLevel riskLevel;
  final double confidence;
  final List<String> reasons;
  final String recommendation;
  final int urgencyHours;
  final bool needsReferral;
  final bool aiScreened;
  final int? backendTriageId;
}
