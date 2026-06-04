import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/features/auth/presentation/controllers/report_history_providers.dart';
import 'package:repair_ai/features/care_journey/presentation/widgets/follow_up_prompt.dart';
import 'package:repair_ai/features/triage/application/triage_controller.dart';
import 'package:repair_ai/features/triage/domain/triage_result.dart';
import 'package:repair_ai/features/triage/domain/triage_rules.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/localization/triage_l10n.dart';
import 'package:repair_ai/core/widgets/loading_error_state.dart';
import 'package:repair_ai/shared/widgets/demo_disclaimer_banner.dart';
import 'package:repair_ai/features/triage/presentation/widgets/explainability_card.dart';
import 'package:repair_ai/shared/widgets/repair_app_bar.dart';
import 'package:repair_ai/shared/widgets/repair_buttons.dart';
import 'package:repair_ai/core/utils/launch_helpers.dart';
import 'package:repair_ai/features/triage/domain/symptom_catalog.dart';
import 'package:repair_ai/shared/widgets/risk_level_chip.dart';

class RiskResultScreen extends ConsumerStatefulWidget {
  const RiskResultScreen({super.key});

  @override
  ConsumerState<RiskResultScreen> createState() => _RiskResultScreenState();
}

class _RiskResultScreenState extends ConsumerState<RiskResultScreen> {
  bool _persisted = false;
  List<String>? _savedSymptoms;
  double? _savedGestationalAge;
  String? _savedSeverity;
  String? _savedDuration;
  String? _savedNotes;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePersist());
  }

  void _maybePersist() {
    if (_persisted) return;
    final result = ref.read(triageResultProvider);
    final draft = ref.read(symptomReportDraftProvider);
    if (result == null || draft == null) return;

    _savedSymptoms = List<String>.from(draft.symptoms);
    _savedGestationalAge = draft.gestationalAge;
    _savedSeverity = draft.severity;
    _savedDuration = draft.duration;
    _savedNotes = draft.notes;

    ref.read(reportHistoryProvider.notifier).addReport(
          SymptomReport(
            id: DateTime.now().toIso8601String(),
            date: DateTime.now(),
            symptoms: draft.symptoms,
            gestationalAge: draft.gestationalAge,
            severity: draft.severity,
            duration: draft.duration,
            notes: draft.notes,
            riskLevel: result.riskLevel.storageKey,
            recommendation: result.recommendation,
            confidence: result.confidence,
          ),
        );
    ref.read(symptomReportDraftProvider.notifier).state = null;
    _persisted = true;

    if (result.riskLevel == RiskLevel.high) {
      HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final result = ref.watch(triageResultProvider);
    final draft = ref.watch(symptomReportDraftProvider);

    if (result == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/triage/symptom-report');
      });
      return Scaffold(
        body: LoadingState(message: l10n.onDeviceAnalysis),
      );
    }

    final symptoms = _savedSymptoms ?? draft?.symptoms ?? const <String>[];
    final gestationalAge = _savedGestationalAge ?? draft?.gestationalAge ?? 8.0;
    final severity = _savedSeverity ?? draft?.severity ?? 'moderate';
    final duration = _savedDuration ?? draft?.duration ?? 'today';
    final notes = _savedNotes ?? draft?.notes ?? '';
    final trimester = TriageRules.trimesterLabel(gestationalAge, l10n);
    final confidencePct = (result.confidence * 100).round();

    final size = MediaQuery.of(context).size;
    final shortest = size.shortestSide;
    final horizontalPadding = shortest < 380 ? 12.0 : 16.0;
    final cardRadius = shortest < 380 ? 20.0 : 24.0;
    final titleSize = shortest < 380 ? 26.0 : 32.0;
    final iconSize = shortest < 380 ? 64.0 : 80.0;
    final riskCardPadding = shortest < 380 ? 20.0 : 32.0;

    return Scaffold(
      appBar: RepairAppBar(
        title: l10n.aiRiskAssessment,
        showDemoChip: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const DemoDisclaimerBanner(compact: true),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Card(
                  key: ValueKey(result.riskLevel),
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(cardRadius),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(riskCardPadding),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(cardRadius),
                      gradient: LinearGradient(
                        colors: [
                          result.riskLevel.color.withValues(alpha: 0.12),
                          Theme.of(context).colorScheme.surface,
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          size: iconSize,
                          color: result.riskLevel.color,
                        ),
                        const SizedBox(height: 12),
                        RiskLevelChip(level: result.riskLevel),
                        const SizedBox(height: 8),
                        Text(
                          l10n.riskLabel(result.riskLevel).toUpperCase(),
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.bold,
                            color: result.riskLevel.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.riskLevel,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.modelConfidenceLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: result.confidence,
                  minHeight: 10,
                  backgroundColor: Colors.grey.shade200,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$confidencePct%',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.basedOnSymptoms,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...symptoms.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '• ${SymptomCatalog.label(l10n, s)}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${gestationalAge.toStringAsFixed(1)} ${l10n.weeksPregnantLabel} — $trimester',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_labelFor(severity)} • ${_labelFor(duration)}',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          notes,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ExplainabilityCard(
                title: l10n.whyThisResult,
                reasons: result.reasons,
              ),
              const SizedBox(height: 16),
              Card(
                color: AppTheme.primary.withValues(alpha: 0.08),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.recommendation,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        result.recommendation,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              if (result.riskLevel == RiskLevel.high) ...[
                const SizedBox(height: 12),
                Card(
                  color: AppTheme.error.withValues(alpha: 0.12),
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text(
                      'Urgent: do not wait for a digital referral if symptoms are severe. Go to care now or call emergency support.',
                      style: TextStyle(
                        color: AppTheme.error,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: launchEmergencyCall,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.phone),
                    label: Text(l10n.callEmergency),
                  ),
                ),
                const SizedBox(height: 12),
                const FollowUpPrompt(compact: true),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: RepairOutlinedButton(
                      label: l10n.triageBack,
                      onPressed: () => context.go('/triage/symptom-report'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RepairPrimaryButton(
                      label: l10n.startReferral,
                      icon: Icons.local_hospital,
                      onPressed: () => context.push('/referral'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.push('/history'),
                child: Text(l10n.viewHistory),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _labelFor(String value) {
    switch (value) {
      case 'mild':
        return 'Mild';
      case 'moderate':
        return 'Moderate';
      case 'severe':
        return 'Severe';
      case 'today':
        return 'Started today';
      case 'two_days':
        return '1-2 days';
      case 'three_plus':
        return '3+ days';
      default:
        return value;
    }
  }
}
