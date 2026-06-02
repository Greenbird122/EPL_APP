import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SymptomReport {
  final String id;
  final DateTime date;
  final List<String> symptoms;
  final double gestationalAge;
  final String riskLevel;
  final String recommendation;
  final double confidence;

  SymptomReport({
    required this.id,
    required this.date,
    required this.symptoms,
    required this.gestationalAge,
    required this.riskLevel,
    required this.recommendation,
    this.confidence = 0.85,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'symptoms': symptoms,
        'gestationalAge': gestationalAge,
        'riskLevel': riskLevel,
        'recommendation': recommendation,
        'confidence': confidence,
      };

  factory SymptomReport.fromJson(Map<String, dynamic> json) => SymptomReport(
        id: json['id'],
        date: DateTime.parse(json['date']),
        symptoms: List<String>.from(json['symptoms']),
        gestationalAge: (json['gestationalAge'] as num).toDouble(),
        riskLevel: json['riskLevel'] as String,
        recommendation: json['recommendation'] as String,
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0.85,
      );
}

class SymptomReportDraft {
  final List<String> symptoms;
  final double gestationalAge;

  const SymptomReportDraft({
    required this.symptoms,
    required this.gestationalAge,
  });
}

class ReportHistoryNotifier extends StateNotifier<List<SymptomReport>> {
  ReportHistoryNotifier() : super([]) {
    _loadReports();
  }

  Future<void> _loadReports() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('report_history');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      state = decoded.map((e) => SymptomReport.fromJson(e)).toList();
    }
  }

  Future<void> addReport(SymptomReport report) async {
    state = [...state, report];
    await _saveReports();
  }

  Future<void> _saveReports() async {
    final prefs = await SharedPreferences.getInstance();
    final data = state.map((e) => e.toJson()).toList();
    await prefs.setString('report_history', jsonEncode(data));
  }
}

final reportHistoryProvider =
    StateNotifierProvider<ReportHistoryNotifier, List<SymptomReport>>((ref) {
  return ReportHistoryNotifier();
});

final symptomReportDraftProvider =
    StateProvider<SymptomReportDraft?>((ref) => null);
