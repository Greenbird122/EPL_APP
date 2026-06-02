import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/app_error_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:repair_ai/features/auth/presentation/controllers/report_history_providers.dart';
import 'package:repair_ai/features/triage/domain/symptom_catalog.dart';
import 'package:repair_ai/features/triage/domain/triage_rules.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/shared/widgets/bottom_nav.dart';
import 'package:repair_ai/shared/widgets/demo_disclaimer_banner.dart';
import 'package:repair_ai/shared/widgets/repair_app_bar.dart';
import 'package:repair_ai/shared/widgets/repair_buttons.dart';
import 'package:repair_ai/shared/widgets/repair_card.dart';

class SymptomReportScreen extends ConsumerStatefulWidget {
  const SymptomReportScreen({super.key});

  @override
  ConsumerState<SymptomReportScreen> createState() =>
      _SymptomReportScreenState();
}

class _SymptomReportScreenState extends ConsumerState<SymptomReportScreen> {
  final List<String> selectedSymptoms = [];
  double gestationalAge = 8.0;
  final _notesController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _toggleListen() async {
    final l10n = AppLocalizations.of(context);
    if (!_speechAvailable) {
      showAppErrorSnackBar(context, l10n.voiceNotAvailable);
      return;
    }
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }
    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        _notesController.text = result.recognizedWords;
        _notesController.selection = TextSelection.fromPosition(
          TextPosition(offset: _notesController.text.length),
        );
      },
    );
  }

  void _submitSymptoms() {
    if (selectedSymptoms.isEmpty) return;

    ref.read(symptomReportDraftProvider.notifier).state = SymptomReportDraft(
      symptoms: List<String>.from(selectedSymptoms),
      gestationalAge: gestationalAge,
    );

    context.push('/triage/analyzing');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trimester = TriageRules.trimesterLabel(gestationalAge, l10n);

    return Scaffold(
      appBar: RepairAppBar(
        title: l10n.reportSymptomsTitle,
        showDemoChip: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DemoDisclaimerBanner(compact: true),
              const SizedBox(height: 16),
              RepairCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.weeksPregnant,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Slider(
                      value: gestationalAge,
                      min: 4,
                      max: 40,
                      divisions: 72,
                      label: '${gestationalAge.toStringAsFixed(1)} ${l10n.weeksPregnantLabel}',
                      onChanged: (value) =>
                          setState(() => gestationalAge = value),
                    ),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            '${gestationalAge.toStringAsFixed(1)} ${l10n.weeksPregnantLabel}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                          ),
                          Text(
                            trimester,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text(
                    l10n.selectSymptoms,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (selectedSymptoms.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppTheme.primary,
                      child: Text(
                        '${selectedSymptoms.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: SymptomCatalog.canonicalKeys.length,
                itemBuilder: (context, index) {
                  final symptom = SymptomCatalog.canonicalKeys[index];
                  final isSelected = selectedSymptoms.contains(symptom);

                  return AnimatedScale(
                    scale: isSelected ? 1.02 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedSymptoms.remove(symptom);
                          } else {
                            selectedSymptoms.add(symptom);
                          }
                        });
                      },
                      child: Card(
                        elevation: isSelected ? 8 : 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected
                                ? AppTheme.primary
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                                  Icon(
                                    SymptomCatalog.iconFor(symptom),
                              size: 30,
                              color: isSelected
                                  ? AppTheme.primary
                                  : Colors.grey[700],
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    SymptomCatalog.label(l10n, symptom),
                                    textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected ? AppTheme.primary : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              RepairCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.symptomNotesHint,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: l10n.symptomNotesHint,
                        suffixIcon: IconButton(
                          onPressed: _toggleListen,
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening
                                ? AppTheme.error
                                : AppTheme.primary,
                          ),
                          tooltip: _isListening
                              ? l10n.voiceStop
                              : l10n.voiceListen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              RepairPrimaryButton(
                label: l10n.getAIRiskAssessment,
                icon: Icons.auto_awesome,
                onPressed:
                    selectedSymptoms.isNotEmpty ? _submitSymptoms : null,
              ),
              if (selectedSymptoms.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.selectSymptomHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Text(
                  l10n.symptomNote,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}
