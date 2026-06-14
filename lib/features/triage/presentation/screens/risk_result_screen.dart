import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/features/anc/presentation/controllers/anc_profile_controller.dart';
import 'package:repair_ai/features/auth/presentation/controllers/report_history_providers.dart';
import 'package:repair_ai/features/care_journey/presentation/widgets/follow_up_prompt.dart';
import 'package:repair_ai/features/triage/application/triage_controller.dart';
import 'package:repair_ai/features/triage/domain/triage_result.dart';
import 'package:repair_ai/features/triage/domain/triage_rules.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/core/widgets/loading_error_state.dart';
import 'package:repair_ai/features/triage/presentation/widgets/explainability_card.dart';
import 'package:repair_ai/shared/widgets/repair_app_bar.dart';
import 'package:repair_ai/shared/widgets/repair_buttons.dart';
import 'package:repair_ai/shared/widgets/responsive_page.dart';
import 'package:repair_ai/core/utils/launch_helpers.dart';
import 'package:repair_ai/core/utils/responsive.dart';
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

    _persisted = true;
    _savedSymptoms = List<String>.from(draft.symptoms);
    _savedGestationalAge = draft.gestationalAge;
    _savedSeverity = draft.severity;
    _savedDuration = draft.duration;
    _savedNotes = draft.notes;

    ref.read(reportHistoryProvider.notifier).addReport(SymptomReport(
          id: DateTime.now().toIso8601String(),
          date: DateTime.now(),
          symptoms: _savedSymptoms!,
          gestationalAge: _savedGestationalAge!,
          severity: _savedSeverity!,
          duration: _savedDuration!,
          notes: _savedNotes ?? '',
          riskLevel: result.riskLevel.storageKey,
          recommendation: result.recommendation,
          confidence: result.confidence,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final result = ref.watch(triageResultProvider);
    final draft = ref.read(symptomReportDraftProvider);
    final ancProfileAsync = ref.watch(ancProfileProvider);
    final ancProfile = ancProfileAsync.maybeWhen(
      data: (profile) => profile,
      orElse: () => null,
    );

    if (result == null) {
      return Scaffold(body: LoadingState(message: l10n.onDeviceAnalysis));
    }

    final symptoms = _savedSymptoms ?? draft?.symptoms ?? const <String>[];
    final gestationalAge = _savedGestationalAge ?? draft?.gestationalAge ?? 8.0;
    final severity = _savedSeverity ?? draft?.severity ?? 'moderate';
    final notes = _savedNotes ?? draft?.notes ?? '';
    final trimester = TriageRules.trimesterLabel(gestationalAge, l10n);
    final confidencePct = (result.confidence * 100).round();
    final compact = RepairBreakpoints.isCompactPhone(context);
    final riskColor = result.riskLevel.color;

    return Scaffold(
      appBar: RepairAppBar(title: l10n.yourAssessment),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 20),
          child: ResponsivePageShell(
            maxWidth: RepairSizing.formMaxWidth(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),

                // Risk banner — dramatic full-width
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(compact ? 22 : 30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        riskColor.withValues(alpha: 0.18),
                        riskColor.withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: riskColor.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: riskColor.withValues(alpha: 0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        result.riskLevel == RiskLevel.high
                            ? Icons.warning_rounded
                            : result.riskLevel == RiskLevel.moderate
                                ? Icons.info_outline_rounded
                                : Icons.check_circle_outline_rounded,
                        size: compact ? 56 : 72,
                        color: riskColor,
                      ),
                      const SizedBox(height: 12),
                      RiskLevelChip(level: result.riskLevel),
                      const SizedBox(height: 6),
                      _ScreeningSourceChip(result: result, l10n: l10n),
                      const SizedBox(height: 12),
                      Text(
                        result.riskLevel == RiskLevel.high
                            ? l10n.riskCallToActionHigh
                            : result.riskLevel == RiskLevel.moderate
                                ? l10n.riskCallToActionModerate
                                : l10n.riskCallToActionLow,
                        style: TextStyle(
                          fontSize: RepairSizing.textScale(context, 28),
                          fontWeight: FontWeight.w900,
                          color: riskColor,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _riskSubtitle(result.riskLevel, l10n),
                        style: TextStyle(
                          fontSize: RepairSizing.textScale(context, 15),
                          color: riskColor.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: riskColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          l10n.confidenceLabel(confidencePct.toString()),
                          style: TextStyle(
                            color: riskColor,
                            fontWeight: FontWeight.w800,
                            fontSize: RepairSizing.textScale(context, 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Urgency banner for high risk
                if (result.riskLevel == RiskLevel.high) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.priority_high_rounded,
                            color: AppTheme.error, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.riskUrgentInstructions,
                            style: TextStyle(
                              color: AppTheme.error,
                              fontWeight: FontWeight.w800,
                              fontSize: RepairSizing.textScale(context, 14),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: RepairSizing.buttonHeight(context),
                    child: ElevatedButton.icon(
                      onPressed: launchEmergencyCall,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18)),
                      ),
                      icon: const Icon(Icons.phone),
                      label: Text(l10n.callEmergency,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const FollowUpPrompt(compact: true),
                ],

                const SizedBox(height: 20),

                // What you reported
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceTinted,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.whatYouReported,
                          style: TextStyle(
                            fontSize: RepairSizing.textScale(context, 17),
                            fontWeight: FontWeight.w800,
                          )),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: symptoms
                            .map((s) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    SymptomCatalog.label(l10n, s),
                                    style: TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize:
                                          RepairSizing.textScale(context, 13),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.weeksPregnantWithTrimester(
                          gestationalAge.toStringAsFixed(1),
                          trimester,
                        ),
                        style: TextStyle(
                          color: AppTheme.primary.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Why this result
                ExplainabilityCard(
                  title: l10n.whyThisResult,
                  reasons: result.reasons,
                ),

                const SizedBox(height: 16),

                // AI source note
                if (result.aiScreened)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.psychology_alt_outlined,
                            color: AppTheme.primary, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.aiScreeningReferralChecked,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),

                if ((ancProfile?.contextFlags ?? const []).isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _AncContextCard(
                    title: l10n.ancContextForRisk,
                    flags: ancProfile!.contextFlags,
                  ),
                ],

                const SizedBox(height: 16),

                // Recommendation
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withValues(alpha: 0.1),
                        AppTheme.primary.withValues(alpha: 0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.whatYouShouldDo,
                          style: TextStyle(
                            fontSize: RepairSizing.textScale(context, 17),
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          )),
                      const SizedBox(height: 8),
                      Text(
                        result.recommendation,
                        style: TextStyle(
                          fontSize: RepairSizing.textScale(context, 15),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Bottom actions
                Row(
                  children: [
                    Expanded(
                      child: RepairOutlinedButton(
                        label: l10n.newCheck,
                        icon: Icons.refresh,
                        onPressed: () {
                          ref.read(triageResultProvider.notifier).state = null;
                          context.push('/triage/symptom-report');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RepairPrimaryButton(
                        label: result.needsReferral
                            ? l10n.findFacility
                            : l10n.viewCare,
                        icon: result.needsReferral
                            ? Icons.local_hospital
                            : Icons.favorite_border,
                        onPressed: () {
                          context.push(
                              result.needsReferral ? '/referral' : '/care');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/care'),
                    icon: const Icon(Icons.chat_outlined),
                    label: Text(l10n.discussResultWithAi),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primary,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _riskSubtitle(RiskLevel level, AppLocalizations l10n) {
    switch (level) {
      case RiskLevel.high:
        return l10n.riskSubtitleHigh;
      case RiskLevel.moderate:
        return l10n.riskSubtitleModerate;
      case RiskLevel.low:
        return l10n.riskSubtitleLow;
    }
  }
}

class _ScreeningSourceChip extends StatelessWidget {
  const _ScreeningSourceChip({required this.result, required this.l10n});
  final TriageResult result;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final label = result.aiScreened
        ? l10n.screeningSourceAiAssisted
        : l10n.screeningSourceQuickCheck;
    final icon = result.aiScreened ? Icons.auto_awesome : Icons.speed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              )),
        ],
      ),
    );
  }
}

class _AncContextCard extends StatelessWidget {
  const _AncContextCard({required this.title, required this.flags});
  final String title;
  final List<dynamic> flags;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: AppTheme.warning)),
          const SizedBox(height: 8),
          ...flags.take(3).map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('• $f',
                    style: const TextStyle(fontSize: 13, height: 1.35)),
              )),
        ],
      ),
    );
  }
}
