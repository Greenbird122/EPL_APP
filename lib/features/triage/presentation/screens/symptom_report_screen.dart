import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/network/backend_heartbeat_provider.dart';
import 'package:repair_ai/core/network/backend_services.dart';
import 'package:repair_ai/core/utils/app_error_handler.dart';
import 'package:repair_ai/core/utils/launch_helpers.dart';
import 'package:repair_ai/core/utils/responsive.dart';
import 'package:repair_ai/features/auth/presentation/controllers/report_history_providers.dart';
import 'package:repair_ai/features/triage/domain/symptom_catalog.dart';
import 'package:repair_ai/features/triage/domain/triage_rules.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:record/record.dart';
import 'package:repair_ai/shared/widgets/bottom_nav.dart';
import 'package:repair_ai/shared/widgets/repair_app_bar.dart';
import 'package:repair_ai/shared/widgets/repair_buttons.dart';
import 'package:repair_ai/shared/widgets/repair_card.dart';
import 'package:repair_ai/shared/widgets/responsive_page.dart';

enum TriageInputMode { text, voiceRecording, voiceCall }

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
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _recordingSub;
  Timer? _recordingTimer;
  final List<int> _recordedPcmBytes = [];
  TriageInputMode _inputMode = TriageInputMode.text;
  bool _isRecording = false;
  bool _isTranscribing = false;
  int _recordingSeconds = 0;
  String? _voiceStatus;

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _recordingSub?.cancel();
    _recorder.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    final l10n = AppLocalizations.of(context);
    if (_isRecording) {
      await _stopAndTranscribe();
      return;
    }
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!mounted) return;
      if (!hasPermission) {
        showAppErrorSnackBar(context, l10n.voiceRecordingUnavailable);
        return;
      }
      _recordedPcmBytes.clear();
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );
      _recordingSub = stream.listen(_recordedPcmBytes.addAll);
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordingSeconds += 1);
      });
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
        _voiceStatus = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _voiceStatus = l10n.voiceRecordingUnavailable);
      }
    }
  }

  Future<void> _stopAndTranscribe() async {
    final l10n = AppLocalizations.of(context);
    try {
      await _recorder.stop();
      await _recordingSub?.cancel();
      _recordingTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _isTranscribing = true;
        _voiceStatus = l10n.transcribingVoice;
      });
      final audioBytes = _wavFromPcm16(
        Uint8List.fromList(_recordedPcmBytes),
        sampleRate: 16000,
        channels: 1,
      );
      final data = await ref.read(triageApiProvider).transcribeAudio(
            fileBytes: audioBytes,
            fileName: 'repair_ai_symptoms.wav',
            language: AppLocalizations.of(context).locale == 'sw' ? 'sw' : 'en',
          );
      final transcript = '${data['transcript'] ?? ''}'.trim();
      if (transcript.isEmpty) {
        setState(() => _voiceStatus = l10n.voiceRecordingUnavailable);
        return;
      }
      _notesController.text = transcript;
      _notesController.selection = TextSelection.fromPosition(
        TextPosition(offset: _notesController.text.length),
      );
      setState(() => _voiceStatus = l10n.voiceRecordingReady);
    } catch (_) {
      if (mounted) {
        setState(() => _voiceStatus = l10n.voiceRecordingUnavailable);
      }
    } finally {
      if (mounted) {
        setState(() => _isTranscribing = false);
      }
    }
  }

  Uint8List _wavFromPcm16(
    Uint8List pcmBytes, {
    required int sampleRate,
    required int channels,
  }) {
    final byteRate = sampleRate * channels * 2;
    final dataLength = pcmBytes.length;
    final output = BytesBuilder();

    void writeString(String value) => output.add(value.codeUnits);
    void writeUint16(int value) {
      output.add([value & 0xff, (value >> 8) & 0xff]);
    }

    void writeUint32(int value) {
      output.add([
        value & 0xff,
        (value >> 8) & 0xff,
        (value >> 16) & 0xff,
        (value >> 24) & 0xff,
      ]);
    }

    writeString('RIFF');
    writeUint32(36 + dataLength);
    writeString('WAVE');
    writeString('fmt ');
    writeUint32(16);
    writeUint16(1);
    writeUint16(channels);
    writeUint32(sampleRate);
    writeUint32(byteRate);
    writeUint16(channels * 2);
    writeUint16(16);
    writeString('data');
    writeUint32(dataLength);
    output.add(pcmBytes);
    return output.toBytes();
  }

  Future<void> _callVoiceAssistant() async {
    final launched = await launchRepairAiVoiceAssistant();
    if (!mounted || launched) return;
    showAppErrorSnackBar(
      context,
      AppLocalizations.of(context).voiceAssistantUnavailable,
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
    final statedAge = _patientStatedAge();

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
            if (statedAge != null) ...[
              const SizedBox(height: 10),
              _InfoPill(
                icon: Icons.person_search_outlined,
                label: '${l10n.patientStatedAge}: $statedAge',
              ),
            ] else ...[
              const SizedBox(height: 10),
              _InfoPill(
                icon: Icons.info_outline,
                label: l10n.ageNotProvided,
              ),
            ],
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
    final l10n = AppLocalizations.of(context);
    switch (value) {
      case 'mild':
        return l10n.symptomSeverityMild;
      case 'moderate':
        return l10n.symptomSeverityModerate;
      case 'severe':
        return l10n.symptomSeveritySevere;
      case 'today':
        return l10n.symptomDurationToday;
      case 'two_days':
        return l10n.symptomDurationTwoDays;
      case 'three_plus':
        return l10n.symptomDurationThreePlus;
      default:
        return value;
    }
  }

  String? _patientStatedAge() {
    final notes = _notesController.text.trim();
    if (notes.isEmpty) return null;
    final patterns = [
      RegExp(r"\b(?:i\s*am|i'm|im|aged|age)\s*(\d{1,2})\b",
          caseSensitive: false),
      RegExp(r'\b(\d{1,2})\s*(?:years?|yrs?)\b', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(notes);
      final value = match?.group(1);
      if (value == null) continue;
      final age = int.tryParse(value);
      if (age != null && age >= 10 && age <= 55) {
        return '$age';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trimester = TriageRules.trimesterLabel(gestationalAge, l10n);
    final compact = RepairBreakpoints.isCompactPhone(context);
    final pageInsets = RepairInsets.page(context);
    final heartbeat = ref.watch(backendHeartbeatProvider);

    return Scaffold(
      appBar: RepairAppBar(title: l10n.reportSymptomsTitle),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: pageInsets.copyWith(
            bottom: RepairInsets.scrollBottom(context),
          ),
          child: ResponsivePageShell(
            maxWidth: RepairSizing.formMaxWidth(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: compact ? 12 : 16),
                _GuidedAiHeader(
                  compact: compact,
                  heartbeat: heartbeat,
                ),
                SizedBox(height: compact ? 14 : 18),
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
                            label: _labelFor('today'),
                            selected: duration == 'today',
                            onTap: () => setState(() => duration = 'today'),
                          ),
                          _ChoiceChip(
                            label: _labelFor('two_days'),
                            selected: duration == 'two_days',
                            onTap: () => setState(() => duration = 'two_days'),
                          ),
                          _ChoiceChip(
                            label: _labelFor('three_plus'),
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
                _InputModeSelector(
                  selectedMode: _inputMode,
                  onSelected: (mode) {
                    setState(() {
                      _inputMode = mode;
                      _voiceStatus = null;
                    });
                    if (mode == TriageInputMode.voiceCall) {
                      _callVoiceAssistant();
                    }
                  },
                ),
                if (_inputMode == TriageInputMode.voiceRecording) ...[
                  const SizedBox(height: 10),
                  _VoiceRecordingPanel(
                    isRecording: _isRecording,
                    isTranscribing: _isTranscribing,
                    recordingSeconds: _recordingSeconds,
                    status: _voiceStatus,
                    onToggle: _toggleRecording,
                  ),
                ],
                if (_inputMode == TriageInputMode.voiceCall) ...[
                  const SizedBox(height: 10),
                  RepairCard(
                    child: Row(
                      children: [
                        const Icon(Icons.call_outlined,
                            color: AppTheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.triageVoiceCallSubtitle,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _callVoiceAssistant,
                          child: Text(l10n.callRepairAiVoiceAssistant),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: compact ? 12 : 16),
                RepairCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.record_voice_over_outlined,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.describeSymptomsNaturally,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  l10n.describeSymptomsNaturallyHint,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notesController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: l10n.symptomNotesHint,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      if (_patientStatedAge() != null) ...[
                        const SizedBox(height: 10),
                        _InfoPill(
                          icon: Icons.verified_user_outlined,
                          label:
                              '${l10n.patientStatedAge}: ${_patientStatedAge()}',
                        ),
                      ],
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

class _InputModeSelector extends StatelessWidget {
  const _InputModeSelector({
    required this.selectedMode,
    required this.onSelected,
  });

  final TriageInputMode selectedMode;
  final ValueChanged<TriageInputMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = [
      (
        mode: TriageInputMode.text,
        icon: Icons.chat_bubble_outline,
        title: l10n.triageTextMode,
        subtitle: l10n.triageTextModeSubtitle,
      ),
      (
        mode: TriageInputMode.voiceRecording,
        icon: Icons.mic_none,
        title: l10n.triageVoiceRecordingMode,
        subtitle: l10n.triageVoiceRecordingSubtitle,
      ),
      (
        mode: TriageInputMode.voiceCall,
        icon: Icons.call_outlined,
        title: l10n.triageVoiceCallMode,
        subtitle: l10n.triageVoiceCallSubtitle,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 620;
        final itemWidth =
            wide ? (constraints.maxWidth - 16) / 3 : constraints.maxWidth;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final selected = selectedMode == option.mode;
            return SizedBox(
              width: itemWidth,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onSelected(option.mode),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary.withValues(alpha: 0.12)
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected
                          ? AppTheme.primary
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        option.icon,
                        color: selected
                            ? AppTheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: selected ? AppTheme.primary : null,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              option.subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.25,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _VoiceRecordingPanel extends StatelessWidget {
  const _VoiceRecordingPanel({
    required this.isRecording,
    required this.isTranscribing,
    required this.recordingSeconds,
    required this.status,
    required this.onToggle,
  });

  final bool isRecording;
  final bool isTranscribing;
  final int recordingSeconds;
  final String? status;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final minutes = (recordingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (recordingSeconds % 60).toString().padLeft(2, '0');
    final color = isRecording ? AppTheme.error : AppTheme.primary;

    return RepairCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRecording ? Icons.graphic_eq : Icons.mic_none,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTranscribing
                          ? l10n.transcribingVoice
                          : isRecording
                              ? '$minutes:$seconds'
                              : l10n.triageVoiceRecordingMode,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    if (status != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        status!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RepairPrimaryButton(
            label: isRecording
                ? l10n.stopVoiceRecording
                : l10n.startVoiceRecording,
            icon: isRecording ? Icons.stop : Icons.mic,
            onPressed: isTranscribing ? null : onToggle,
          ),
        ],
      ),
    );
  }
}

class _GuidedAiHeader extends StatelessWidget {
  const _GuidedAiHeader({required this.compact, required this.heartbeat});

  final bool compact;
  final BackendHeartbeatState heartbeat;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isOnline = heartbeat == BackendHeartbeatState.online;
    final isChecking = heartbeat == BackendHeartbeatState.checking;
    final toneColor = isOnline
        ? AppTheme.success
        : isChecking
            ? AppTheme.warning
            : AppTheme.error;
    final toneLabel = isOnline
        ? l10n.aiReady
        : isChecking
            ? l10n.aiReadinessChecking
            : l10n.aiUnavailable;

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.16),
            AppTheme.accent.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _InfoPill(
                icon: Icons.auto_awesome,
                label: l10n.guidedAiCheck,
                color: AppTheme.primary,
              ),
              _InfoPill(
                icon: isOnline
                    ? Icons.cloud_done_outlined
                    : isChecking
                        ? Icons.sync
                        : Icons.cloud_off_outlined,
                label: toneLabel,
                color: toneColor,
              ),
            ],
          ),
          SizedBox(height: compact ? 10 : 12),
          Text(
            l10n.guidedAiCheckTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.guidedAiCheckSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.noAgeGuessingSafety,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    this.color = AppTheme.primary,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: (MediaQuery.sizeOf(context).width - 110).clamp(
                  120.0,
                  360.0,
                ),
              ),
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
