import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/network/api_client.dart';
import 'package:repair_ai/core/utils/async_guard.dart';
import 'package:repair_ai/features/auth/presentation/controllers/report_history_providers.dart';
import 'package:repair_ai/features/triage/application/triage_controller.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/shared/widgets/demo_disclaimer_banner.dart';
import 'package:repair_ai/shared/widgets/motherly_quote_card.dart';
import 'package:repair_ai/shared/widgets/repair_app_bar.dart';
import 'package:repair_ai/shared/widgets/repair_buttons.dart';
import 'package:repair_ai/core/widgets/loading_error_state.dart';

import '../widgets/analysis_step_indicator.dart';

class AiAnalyzingScreen extends ConsumerStatefulWidget {
  const AiAnalyzingScreen({super.key});

  @override
  ConsumerState<AiAnalyzingScreen> createState() => _AiAnalyzingScreenState();
}

class _AiAnalyzingScreenState extends ConsumerState<AiAnalyzingScreen> {
  int _stepIndex = 0;
  int _quoteIndex = 0;
  Timer? _quoteTimer;
  bool _failed = false;
  bool _timedOut = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAnalysis());
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    final l10n = AppLocalizations.of(context);
    _quoteTimer?.cancel();
    final draft = ref.read(symptomReportDraftProvider);
    if (draft == null || draft.symptoms.isEmpty) {
      if (mounted) {
        setState(() {
          _failed = true;
          _errorMessage = l10n.selectSymptomHint;
        });
      }
      return;
    }

    final quotes = MotherlyQuoteCard.quotesFor(l10n);
    _quoteTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        setState(() => _quoteIndex = (_quoteIndex + 1) % quotes.length);
      }
    });

    final steps = [
      l10n.analyzingStep1,
      l10n.analyzingStep2,
      l10n.analyzingStep3,
    ];

    try {
      await runWithMinimumDuration(() async {
        for (var i = 0; i < steps.length; i++) {
          if (!mounted) return;
          setState(() => _stepIndex = i);
          await Future<void>.delayed(const Duration(milliseconds: 1200));
        }

        final result = await runWithTimeout(
          () async {
            return ref.read(triageControllerProvider).runBackendAssessment(
                  draft: draft,
                  l10n: l10n,
                );
          },
          timeout: const Duration(seconds: 20),
        );

        if (result == null) {
          if (mounted) setState(() => _timedOut = true);
          return;
        }
      }, minimum: const Duration(seconds: 5));
    } on ApiException catch (error) {
      _quoteTimer?.cancel();
      if (mounted) {
        setState(() {
          _failed = true;
          _errorMessage = _friendlyAnalysisError(error, l10n);
        });
      }
      return;
    } catch (error) {
      _quoteTimer?.cancel();
      if (mounted) {
        setState(() {
          _failed = true;
          _errorMessage = _friendlyUnknownError(error, l10n);
        });
      }
      return;
    }

    _quoteTimer?.cancel();
    if (!mounted) return;

    if (_timedOut) return;

    context.go('/triage/risk-result');
  }

  void _useLocalFallback() {
    final l10n = AppLocalizations.of(context);
    final draft = ref.read(symptomReportDraftProvider);
    if (draft == null || draft.symptoms.isEmpty) {
      setState(() => _errorMessage = l10n.selectSymptomHint);
      return;
    }
    ref.read(triageControllerProvider).runLocalFallbackAssessment(
          draft: draft,
          l10n: l10n,
        );
    context.go('/triage/risk-result');
  }

  String _friendlyAnalysisError(ApiException error, AppLocalizations l10n) {
    final message = error.message;
    return switch (error.statusCode) {
      401 => '${message.trim()} ${l10n.patientProfileRequiredForAi}',
      403 => message,
      503 => l10n.aiServiceUnavailable,
      502 || 504 => l10n.aiServiceUnavailable,
      _ => message.trim().isEmpty ? l10n.aiServiceUnavailable : message,
    };
  }

  String _friendlyUnknownError(Object error, AppLocalizations l10n) {
    final message = error.toString();
    if (message.contains('Patient profile') || message.contains('profile')) {
      return l10n.patientProfileRequiredForAi;
    }
    return l10n.aiServiceUnavailable;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quotes = MotherlyQuoteCard.quotesFor(l10n);

    return Scaffold(
      appBar: RepairAppBar(
        title: l10n.aiRiskAssessment,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DemoDisclaimerBanner(),
              const SizedBox(height: 24),
              if (_failed || _timedOut) ...[
                ErrorState(
                  message: _timedOut
                      ? l10n.timeoutError
                      : (_errorMessage ?? l10n.aiServiceUnavailable),
                  retryText: l10n.retry,
                  onRetry: () {
                    setState(() {
                      _failed = false;
                      _timedOut = false;
                      _errorMessage = null;
                    });
                    _runAnalysis();
                  },
                ),
                const SizedBox(height: 12),
                RepairPrimaryButton(
                  label: l10n.useLocalSafetyScreening,
                  icon: Icons.health_and_safety_outlined,
                  onPressed: _useLocalFallback,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.go('/triage/symptom-report'),
                  child: Text(l10n.triageBack),
                ),
              ] else ...[
                const Center(
                  child: SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Running backend AI screening',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.analyzingSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                AnalysisStepIndicator(
                  steps: [
                    l10n.analyzingStep1,
                    l10n.analyzingStep2,
                    l10n.analyzingStep3,
                  ],
                  currentIndex: _stepIndex,
                ),
                const SizedBox(height: 20),
                MotherlyQuoteCard(
                  quote: quotes[_quoteIndex % quotes.length],
                  author: l10n.motherQuoteAuthor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
