import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/app_error_handler.dart';
import 'package:repair_ai/core/utils/responsive.dart';
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
import 'package:repair_ai/shared/widgets/responsive_page.dart';

class SymptomReportScreen extends ConsumerStatefulWidget {
  const SymptomReportScreen({super.key});

  @override
  ConsumerState<SymptomReportScreen> createState() =>
      _SymptomReportScreenState();
}

class _SymptomReportScreenState extends ConsumerState<SymptomReportScreen> {
  final List<String> selectedSymptoms = [];
  double gestationalAge = 8.0;
  String severity = 'moderate';
  String duration = 'today';
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
      severity: severity,
      duration: duration,
      notes: _notesController.text.trim(),
    );

    context.push('/triage/analyzing');
  }

  void _reviewAndSubmit() {
    final l10n = AppLocalizations.of(context);
    if (selectedSymptoms.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.reviewForAiScreening,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              selectedSymptoms
                  .map((s) => SymptomCatalog.label(l10n, s))
                  .join(', '),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '${gestationalAge.toStringAsFixed(1)} ${l10n.weeksPregnantLabel} • ${_labelFor(severity)} • ${_labelFor(duration)}',
            ),
            if (_notesController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_notesController.text.trim()),
            ],
            const SizedBox(height: 16),
            Text(
              l10n.screeningSafetyCopy,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 18),
            RepairPrimaryButton(
              label: l10n.runAiRiskScreening,
              icon: Icons.fact_check,
              onPressed: () {
                Navigator.of(ctx).pop();
                _submitSymptoms();
              },
            ),
          ],
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trimester = TriageRules.trimesterLabel(gestationalAge, l10n);
    final compact = RepairBreakpoints.isCompactPhone(context);
    final pageInsets = RepairInsets.page(context);

    return Scaffold(
      appBar: RepairAppBar(
        title: l10n.reportSymptomsTitle,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              pageInsets.copyWith(bottom: RepairInsets.scrollBottom(context)),
          child: ResponsivePageShell(
            maxWidth: RepairSizing.formMaxWidth(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const DemoDisclaimerBanner(compact: true),
                SizedBox(height: compact ? 12 : 16),
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
                        label:
                            '${gestationalAge.toStringAsFixed(1)} ${l10n.weeksPregnantLabel}',
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
                SizedBox(height: compact ? 16 : 24),
                RepairCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.symptomStrengthQuestion,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 12),
                      Wrap(
                        spacing: compact ? 6 : 8,
                        runSpacing: compact ? 6 : 8,
                        children: [
                          _ChoiceChip(
                            label: _labelFor('mild'),
                            selected: severity == 'mild',
                            onTap: () => setState(() => severity = 'mild'),
                          ),
                          _ChoiceChip(
                            label: _labelFor('moderate'),
                            selected: severity == 'moderate',
                            onTap: () => setState(() => severity = 'moderate'),
                          ),
                          _ChoiceChip(
                            label: _labelFor('severe'),
                            selected: severity == 'severe',
                            onTap: () => setState(() => severity = 'severe'),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 12 : 16),
                      Text(
                        l10n.symptomStartQuestion,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: compact ? 8 : 10),
                      Wrap(
                        spacing: compact ? 6 : 8,
                        runSpacing: compact ? 6 : 8,
                        children: [
                          _ChoiceChip(
                            label: 'Today',
                            selected: duration == 'today',
                            onTap: () => setState(() => duration = 'today'),
                          ),
                          _ChoiceChip(
                            label: '1-2 days',
                            selected: duration == 'two_days',
                            onTap: () => setState(() => duration = 'two_days'),
                          ),
                          _ChoiceChip(
                            label: '3+ days',
                            selected: duration == 'three_plus',
                            onTap: () =>
                                setState(() => duration = 'three_plus'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: compact ? 18 : 24),
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
                SizedBox(height: compact ? 10 : 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final spacing = compact ? 8.0 : 12.0;
                    final textScale = MediaQuery.textScalerOf(context).scale(1);
                    final tileHeight =
                        (compact ? 126.0 : 138.0) + (textScale - 1) * 34;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: constraints.maxWidth >= 620 ? 3 : 2,
                        mainAxisExtent: tileHeight.clamp(126.0, 176.0),
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                      ),
                      itemCount: SymptomCatalog.canonicalKeys.length,
                      itemBuilder: (context, index) {
                        final symptom = SymptomCatalog.canonicalKeys[index];
                        final isSelected = selectedSymptoms.contains(symptom);

                        return AnimatedScale(
                          scale: isSelected ? 1.01 : 1.0,
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
                              elevation: isSelected ? 6 : 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(compact ? 8 : 10),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      SymptomCatalog.iconFor(symptom),
                                      size: compact ? 22 : 28,
                                      color: isSelected
                                          ? AppTheme.primary
                                          : Colors.grey[700],
                                    ),
                                    SizedBox(height: compact ? 6 : 8),
                                    Text(
                                      SymptomCatalog.label(l10n, symptom),
                                      textAlign: TextAlign.center,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: compact ? 12 : 13,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? AppTheme.primary
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                SizedBox(height: compact ? 12 : 16),
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
                SizedBox(height: compact ? 18 : 24),
                RepairPrimaryButton(
                  label: l10n.reviewForAiScreening,
                  icon: Icons.fact_check,
                  onPressed:
                      selectedSymptoms.isNotEmpty ? _reviewAndSubmit : null,
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
                    l10n.screeningSafetyCopy,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
                SizedBox(height: compact ? 12 : 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppTheme.primary.withValues(alpha: 0.16),
      labelStyle: TextStyle(
        color: selected ? AppTheme.primary : null,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
