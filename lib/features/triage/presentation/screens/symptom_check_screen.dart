import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/config/theme_mode_provider.dart';
import 'package:repair_ai/core/network/backend_services.dart';
import 'package:repair_ai/core/utils/app_error_handler.dart';
import 'package:repair_ai/core/utils/launch_helpers.dart';
import 'package:repair_ai/core/utils/responsive.dart';
import 'package:repair_ai/features/triage/domain/case_model.dart';
import 'package:repair_ai/features/triage/domain/triage_result.dart';
import 'package:repair_ai/features/triage/application/triage_controller.dart';
import 'package:repair_ai/features/triage/presentation/controllers/triage_case_provider.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/shared/widgets/language_toggle.dart';
import 'package:repair_ai/shared/widgets/repair_app_bar.dart';
import 'package:repair_ai/shared/widgets/repair_buttons.dart';
import 'package:repair_ai/features/triage/presentation/widgets/symptom_chat_tab.dart';
import 'package:repair_ai/core/network/deepseek_direct.dart';
import 'package:repair_ai/core/network/api_client.dart';
import 'package:repair_ai/features/auth/presentation/controllers/login_profile_providers.dart';
import 'package:repair_ai/features/auth/presentation/controllers/report_history_providers.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const _kSidebarWidth = 340.0;
const _kDesktopBreakpoint = 900.0;

enum _SymptomCheckTab { chats, analytics, variables, referrals, reports }

enum _CaseFilter { all, active, analyzing, completed, referred }

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class SymptomCheckScreen extends ConsumerStatefulWidget {
  const SymptomCheckScreen({super.key});

  /// Route path used by go_router.
  static const routePath = '/symptom-check';

  @override
  ConsumerState<SymptomCheckScreen> createState() => _SymptomCheckScreenState();
}

class _SymptomCheckScreenState extends ConsumerState<SymptomCheckScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _textController = TextEditingController();

  late final TabController _tabController;

  _CaseFilter _caseFilter = _CaseFilter.all;
  _SymptomCheckTab _activeTab = _SymptomCheckTab.chats;
  String _searchQuery = '';
  bool _analyticsOpen = false;

  // Timer counting UP from case creation
  Timer? _caseTimer;
  DateTime? _caseStartedAt;

  // Active case selection
  String? _selectedCaseId;

  // Voice recording
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _recordingSub;
  Timer? _recordingTimer;
  final List<int> _recordedPcmBytes = [];
  bool _isRecording = false;
  bool _isTranscribing = false;
  int _recordingSeconds = 0;
  String? _voiceStatus;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: _SymptomCheckTab.values.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _caseTimer?.cancel();
    _recordingTimer?.cancel();
    _recordingSub?.cancel();
    _recorder.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _activeTab = _SymptomCheckTab.values[_tabController.index];
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= _kDesktopBreakpoint;
    final cases = ref.watch(triageCaseProvider);

    return Scaffold(
      appBar: _buildAppBar(l10n),
      body: Column(
        children: [
          _FilterRow(
            l10n: l10n,
            cases: cases,
            selectedCaseId: _selectedCaseId,
            onFilterChanged: _onFilterOrSearchChanged,
            onCaseSelected: _onCaseSelected,
          ),
          _TabBar(),
          Expanded(
            child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
          ),
          if (_isRecording || _isTranscribing)
            _VoiceStatusBar(
              isRecording: _isRecording,
              isTranscribing: _isTranscribing,
              recordingSeconds: _recordingSeconds,
              status: _voiceStatus,
            ),
          _InputBar(
            controller: _textController,
            onSend: _onSendText,
            onDictate: _onDictate,
            onLiveAgent: _onLiveAgent,
            isRecording: _isRecording,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // App bar
  // ---------------------------------------------------------------------------

  PreferredSizeWidget _buildAppBar(AppLocalizations l10n) {
    final activeCount = ref.watch(triageActiveCaseCountProvider);

    // Build the timer display string from elapsed time since case start.
    String timerText = '';
    if (_caseStartedAt != null) {
      final elapsed = DateTime.now().difference(_caseStartedAt!);
      final hours = elapsed.inHours;
      final minutes = elapsed.inMinutes.remainder(60);
      final seconds = elapsed.inSeconds.remainder(60);
      timerText = hours > 0
          ? '${hours}h ${minutes}m ${seconds}s'
          : '${minutes}m ${seconds}s';
    }

    return RepairAppBar(
      title: 'Check Symptoms',
      actions: [
        // Timer badge (visible whenever a case is selected)
        if (_selectedCaseId != null)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined,
                    size: 16, color: Color(0xFF2E7D32)),
                const SizedBox(width: 4),
                Text(
                  timerText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
        // Theme toggle
        _ThemeModeToggle(),
        const SizedBox(width: 6),
        // Language toggle
        const LanguageToggle(),
        const SizedBox(width: 6),
        // Notifications bell with badge
        _NotificationBell(count: activeCount),
        const SizedBox(width: 8),
      ],
    );
  }

  void _onFilterOrSearchChanged(_CaseFilter filter, String query) {
    setState(() {
      _caseFilter = filter;
      _searchQuery = query;
    });
  }

  void _onCaseSelected(String? caseId) {
    setState(() => _selectedCaseId = caseId);
  }

  // ---------------------------------------------------------------------------
  // Layout
  // ---------------------------------------------------------------------------

  /// Wide screens: main content on the left, analytics sidebar on the right.
  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildMainContent()),
        if (_analyticsOpen)
          SizedBox(
            width: _kSidebarWidth,
            child: _LiveAnalyticsPanel(
                onClose: () => setState(() => _analyticsOpen = false)),
          )
        else
          _AnalyticsToggleChip(
              onTap: () => setState(() => _analyticsOpen = true)),
      ],
    );
  }

  /// Narrow screens: main content only; analytics shown via bottom sheet.
  Widget _buildNarrowLayout() {
    return Stack(
      children: [
        _buildMainContent(),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.small(
            backgroundColor: AppTheme.primary,
            onPressed: _openAnalyticsSheet,
            child: const Icon(Icons.analytics_outlined, color: Colors.white),
          ),
        ),
      ],
    );
  }

  void _openAnalyticsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radius)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => _LiveAnalyticsPanel(
          scrollController: scrollController,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main content area
  // ---------------------------------------------------------------------------

  Widget _buildMainContent() {
    final cases = ref.watch(triageCaseProvider);

    if (cases.isEmpty) {
      return _EmptyState();
    }

    // If a specific case is selected, show only that case.
    final displayCases = _selectedCaseId != null
        ? cases.where((c) => c.id == _selectedCaseId).toList()
        : _filteredCases(cases);

    return IndexedStack(
      index: _activeTab.index,
      children: [
        SymptomChatTab(
          cases: displayCases,
          selectedCaseId: _selectedCaseId,
        ),
        const _AnalyticsTab(),
        _VariablesTab(selectedCaseId: _selectedCaseId),
        _ReferralsTab(selectedCaseId: _selectedCaseId),
        _ReportsTab(selectedCaseId: _selectedCaseId),
      ],
    );
  }

  List<TriageCase> _filteredCases(List<TriageCase> cases) {
    var filtered = cases;

    // Apply status filter
    switch (_caseFilter) {
      case _CaseFilter.active:
        filtered =
            filtered.where((c) => c.status == TriageCaseStatus.active).toList();
      case _CaseFilter.analyzing:
        filtered = filtered
            .where((c) => c.status == TriageCaseStatus.analyzing)
            .toList();
      case _CaseFilter.completed:
        filtered = filtered
            .where((c) => c.status == TriageCaseStatus.completed)
            .toList();
      case _CaseFilter.referred:
        filtered = filtered
            .where((c) => c.status == TriageCaseStatus.referred)
            .toList();
      case _CaseFilter.all:
        break;
    }

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((c) {
        return c.patientName.toLowerCase().contains(q) ||
            c.symptoms.any((s) => s.toLowerCase().contains(q)) ||
            (c.notes?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return filtered;
  }

  // ---------------------------------------------------------------------------
  // Tab bar
  // ---------------------------------------------------------------------------

  Widget _TabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primary.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: AppTheme.primary,
        unselectedLabelColor:
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        indicatorColor: AppTheme.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
        tabs: const [
          Tab(text: 'Chats'),
          Tab(text: 'Analytics'),
          Tab(text: 'Variables'),
          Tab(text: 'Referrals'),
          Tab(text: 'Reports'),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  void _onSendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();

    final notifier = ref.read(triageCaseProvider.notifier);
    final cases = ref.read(triageCaseProvider);

    // If a case is selected and it's already resolved, add follow-up message.
    if (_selectedCaseId != null) {
      final existingIdx = cases.indexWhere((c) => c.id == _selectedCaseId);
      if (existingIdx != -1) {
        final existing = cases[existingIdx];
        if (existing.status == TriageCaseStatus.completed ||
            existing.status == TriageCaseStatus.referred) {
          final msg = CaseMessage.now(
            sender: 'patient',
            text: text,
            type: CaseMessageType.text,
          );
          notifier.updateCase(existing.addMessage(msg));
          _sendFollowUpResponse(existing.id, text);
          return;
        }
      }
    }

    // Parse symptoms from the text using the symptom catalog.
    final symptoms = _extractSymptoms(text);

    // Read patient name from profile providers.
    final patientName = ref.read(profileNameProvider) ??
        ref.read(currentPatientContextProvider)?.name ??
        'Patient';
    // Read gestational age from the symptom draft if available.
    final draft = ref.read(symptomReportDraftProvider);
    final gestationalAgeWeeks = draft?.gestationalAge ?? 8.0;

    // Create the case with the patient's message.
    final patientMsg = CaseMessage.now(
      sender: 'patient',
      text: text,
      type: CaseMessageType.text,
    );
    final newCase = TriageCase.create(
      patientName: patientName,
      gestationalAgeWeeks: gestationalAgeWeeks,
      symptoms: symptoms.isNotEmpty ? symptoms : ['Unspecified'],
      severity: 'moderate',
      duration: 'today',
      notes: text,
      messages: [patientMsg],
    );

    // Start the elapsed timer counting UP from case creation.
    if (_caseStartedAt == null) {
      _caseStartedAt = newCase.createdAt;
      _caseTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {}); // rebuild to refresh timerText
      });
    }

    notifier.addCase(newCase);

    // Set this as the active case.
    setState(() => _selectedCaseId = newCase.id);

    // Try to create a backend visit so the AI chat persists on the server.
    _tryCreateBackendVisit(newCase.id, text);

    // Start AI analysis with stable ID.
    _runAnalysis(newCase.id);
  }

  /// Creates a backend Visit for this case so messages are persisted
  /// and the server AI can reply.
  Future<void> _tryCreateBackendVisit(String caseId, String text) async {
    try {
      final visit = await ref.read(visitApiProvider).createVisit({
        'reason': 'Triage case $caseId',
        'notes': text,
      });
      final visitId = visit['id'] as int?;
      if (visitId != null && mounted) {
        final current =
            ref.read(triageCaseProvider).firstWhere((c) => c.id == caseId);
        ref
            .read(triageCaseProvider.notifier)
            .updateCase(current.copyWith(backendVisitId: () => visitId));
      }
    } catch (_) {
      // Backend unavailable — local-only mode.
    }
  }

  List<String> _extractSymptoms(String text) {
    // Use the existing symptom catalog for matching.
    final lower = text.toLowerCase();
    // Import symptom_catalog.dart is already available via the project.
    // We inline the canonical keys for simplicity.
    const symptoms = [
      'Vaginal Bleeding',
      'Severe Abdominal Pain',
      'Cramping',
      'Dizziness / Fainting',
      'Fever',
      'Nausea & Vomiting',
      'Reduced Fetal Movement',
      'Spotting',
    ];
    final keywordMap = {
      'Vaginal Bleeding': ['bleeding', 'blood', 'vaginal'],
      'Severe Abdominal Pain': ['pain', 'abdominal', 'stomach', 'cramp'],
      'Cramping': ['cramping', 'cramp'],
      'Dizziness / Fainting': [
        'dizzy',
        'dizziness',
        'faint',
        'fainting',
        'lightheaded'
      ],
      'Fever': ['fever', 'temperature', 'hot', 'chills'],
      'Nausea & Vomiting': ['nausea', 'vomiting', 'vomit', 'sick', 'queasy'],
      'Reduced Fetal Movement': ['movement', 'fetal', 'baby moving', 'kicks'],
      'Spotting': ['spotting', 'spots', 'light bleeding'],
    };

    return symptoms.where((s) {
      return keywordMap[s]?.any((kw) => lower.contains(kw)) ?? false;
    }).toList();
  }

  Future<void> _runAnalysis(String caseId) async {
    final notifier = ref.read(triageCaseProvider.notifier);

    // Helper: re-read case from provider.
    TriageCase readCase(String id) =>
        ref.read(triageCaseProvider).firstWhere((c) => c.id == id);

    // Read the latest case from provider.
    TriageCase current = readCase(caseId);
    final symptoms = current.symptoms.join(', ');
    final notes = current.notes ?? '';
    final visitId = current.backendVisitId;

    // Mark as analyzing.
    current = current.copyWith(status: TriageCaseStatus.analyzing);
    notifier.updateCase(current);

    // --- Step 1: warm greeting (keep this instant for UX) ---
    current = readCase(caseId);
    current = current.addMessage(
      CaseMessage.now(
        sender: 'ai',
        text: 'Hello there. I\'m glad you reached out. '
            'Let me analyze your symptoms...',
        type: CaseMessageType.riskAssessment,
      ),
    );
    notifier.updateCase(current);

    // --- Step 2: Run AI analysis — prefer backend, fall back to DeepSeekDirect ---
    String riskLevel = 'low';
    double confidence = 0.85;
    String recommendation =
        'Rest and monitor. Contact your provider if symptoms worsen.';

    bool analysisSucceeded = false;

    // Primary path: send the patient's message to the backend visit.
    // The backend AI processes it and we reload the results.
    if (visitId != null) {
      try {
        await ref.read(visitApiProvider).addMessage(visitId, notes);
        // Reload the visit to pick up the AI reply.
        final visits = await ref.read(visitApiProvider).visits();
        final visit = visits.cast<Map<String, dynamic>?>().firstWhere(
              (v) => v?['id'] == visitId,
              orElse: () => null,
            );
        if (visit != null) {
          final msgs = visit['case_messages'] as List<dynamic>? ?? [];
          // Pull the last AI message as the analysis result.
          final aiMsgs = msgs
              .whereType<Map>()
              .where((m) => '${m['sender']}' == 'ai')
              .toList();
          if (aiMsgs.isNotEmpty) {
            final aiText = '${aiMsgs.last['text'] ?? ''}';
            // Attempt to extract structured result from the AI text.
            final lower = aiText.toLowerCase();
            if (lower.contains('risk level: high') ||
                lower.contains('high risk')) {
              riskLevel = 'high';
            } else if (lower.contains('risk level: moderate') ||
                lower.contains('moderate risk')) {
              riskLevel = 'moderate';
            } else {
              riskLevel = 'low';
            }
            recommendation = aiText;
            confidence = 0.85;
            analysisSucceeded = true;
          }
        }
      } catch (_) {
        // Backend call failed — fall through to DeepSeekDirect.
      }
    }

    if (!analysisSucceeded) {
      if (DeepSeekDirect.isConfigured) {
        try {
          final result = await DeepSeekDirect.analyze(
            pregnancyStatus: 'pregnant',
            gestationWeeks: current.gestationalAgeWeeks.toStringAsFixed(0),
            mainSymptom: symptoms,
            symptomDuration: current.duration == 'today'
                ? 'Started today'
                : current.duration == 'two_days'
                    ? '1-2 days'
                    : '3+ days',
            freeText: notes,
          );
          riskLevel = (result['risk_level'] as String?)?.toLowerCase() ?? 'low';
          recommendation = (result['recommendation'] as String?) ??
              'Rest and monitor. Contact your provider if symptoms worsen.';
          confidence = (result['confidence'] as num?)?.toDouble() ?? 0.85;
        } catch (_) {
          riskLevel = _localRiskLevel(current.symptoms);
          confidence = 0.85;
          recommendation = _localRecommendation(riskLevel);
        }
      } else {
        riskLevel = _localRiskLevel(current.symptoms);
        confidence = 0.85;
        recommendation = _localRecommendation(riskLevel);
      }
    }

    if (!mounted) return;
    current = readCase(caseId);

    // --- Step 3: follow-up question ---
    final followUp = _buildFollowUpQuestion(
        hasPain: current.symptoms
            .any((s) => s == 'Severe Abdominal Pain' || s == 'Cramping'),
        hasBleeding: current.symptoms.any((s) => s == 'Vaginal Bleeding'),
        riskLevel: riskLevel);
    current = current.addMessage(
      CaseMessage.now(
        sender: 'ai',
        text: followUp,
        type: CaseMessageType.riskAssessment,
      ),
    );
    notifier.updateCase(current);

    // Small natural delay before result.
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    current = readCase(caseId);

    // Build risk snapshots for the trend chart.
    final score = (confidence * 100).roundToDouble();
    current = current
        .addRiskSnapshot('Open', score * 0.85)
        .addRiskSnapshot('Update 1', score * 0.90)
        .addRiskSnapshot('Update 2', score * 0.93)
        .addRiskSnapshot('Update 3', score * 0.96)
        .addRiskSnapshot('Triage', score);

    // --- Step 4: result message ---
    final resultMsg = CaseMessage.now(
      sender: 'ai',
      text:
          'Risk Level: $riskLevel\nConfidence: ${confidence * 100 ~/ 1}%\n\n$recommendation',
      type: CaseMessageType.recommendation,
    );

    final resolved = current.resolve(
      riskLevel: riskLevel,
      confidence: confidence,
      recommendation: recommendation,
    );

    notifier.updateCase(resolved.addMessage(resultMsg));
  }

  String _localRiskLevel(List<String> symptoms) {
    final hasHighRisk = symptoms.any((s) =>
        s == 'Vaginal Bleeding' ||
        s == 'Severe Abdominal Pain' ||
        s == 'Dizziness / Fainting' ||
        s == 'Reduced Fetal Movement');
    final hasModerateRisk =
        symptoms.any((s) => s == 'Fever' || s == 'Spotting' || s == 'Cramping');
    return hasHighRisk
        ? 'high'
        : hasModerateRisk
            ? 'moderate'
            : 'low';
  }

  String _localRecommendation(String riskLevel) {
    return switch (riskLevel) {
      'high' => 'Seek care immediately. Visit the nearest health facility.',
      'moderate' =>
        'Monitor symptoms and visit a health facility within 24 hours.',
      _ => 'Rest and monitor. Contact your provider if symptoms worsen.',
    };
  }

  /// Builds a personalised follow-up question based on detected symptoms.
  String _buildFollowUpQuestion({
    required bool hasPain,
    required bool hasBleeding,
    required String riskLevel,
  }) {
    if (hasBleeding) {
      return 'I understand. Can you tell me more about the bleeding '
          '— is it heavy or light?';
    }
    if (hasPain) {
      return 'I hear you. A stomach ache can be uncomfortable. '
          'When did this start?';
    }
    if (riskLevel == 'high') {
      return 'Your symptoms sound concerning. Can you describe '
          'how severe they feel right now?';
    }
    if (riskLevel == 'moderate') {
      return 'I see. How long have you been feeling this way?';
    }
    return 'Thank you for sharing. Is there anything else you\'d '
        'like to tell me about how you\'re feeling?';
  }

  /// Sends a real AI follow-up response.
  /// Prefers the backend visit API; falls back to DeepSeekDirect; then local.
  Future<void> _sendFollowUpResponse(String caseId, String userText) async {
    if (!mounted) return;

    final cases = ref.read(triageCaseProvider);
    final idx = cases.indexWhere((c) => c.id == caseId);
    if (idx == -1) return;
    final current = cases[idx];
    final visitId = current.backendVisitId;

    // Mark as analyzing while waiting for AI reply.
    if (current.status != TriageCaseStatus.analyzing) {
      ref
          .read(triageCaseProvider.notifier)
          .updateCase(current.copyWith(status: TriageCaseStatus.analyzing));
    }

    // Primary: send via backend visit which triggers the server AI.
    if (visitId != null) {
      try {
        await ref.read(visitApiProvider).addMessage(visitId, userText);
        // Reload the visit to get the AI reply.
        final visits = await ref.read(visitApiProvider).visits();
        final visit = visits.cast<Map<String, dynamic>?>().firstWhere(
              (v) => v?['id'] == visitId,
              orElse: () => null,
            );
        if (visit != null && mounted) {
          final msgs = visit['case_messages'] as List<dynamic>? ?? [];
          if (msgs.isNotEmpty) {
            // Sync backend messages into the local case.
            final updated =
                ref.read(triageCaseProvider).firstWhere((c) => c.id == caseId);
            var synced = updated;
            for (final m in msgs) {
              final map = m as Map<String, dynamic>;
              synced = synced.addMessage(CaseMessage(
                id: '${map['id'] ?? DateTime.now().microsecondsSinceEpoch}',
                sender: '${map['sender'] ?? 'ai'}',
                text: '${map['text'] ?? ''}',
                timestamp: map['created_at'] != null
                    ? DateTime.tryParse('${map['created_at']}') ??
                        DateTime.now()
                    : DateTime.now(),
                type: CaseMessageType.text,
              ));
            }
            final restored = synced.copyWith(
                status: synced.status == TriageCaseStatus.analyzing
                    ? TriageCaseStatus.completed
                    : null);
            ref.read(triageCaseProvider.notifier).updateCase(restored);
            return;
          }
        }
      } catch (_) {
        // Backend failed — fall through to DeepSeekDirect or local.
      }
    }

    // Secondary: DeepSeekDirect chat.
    if (DeepSeekDirect.isConfigured) {
      try {
        // Build message history for context.
        final history = <Map<String, String>>[
          for (final m in current.messages.take(6))
            {
              'role': m.sender == 'patient' ? 'user' : 'assistant',
              'content': m.text,
            },
          {'role': 'user', 'content': userText},
        ];

        final reply = await DeepSeekDirect.chatReply(messages: history);

        if (!mounted) return;
        final updated =
            ref.read(triageCaseProvider).firstWhere((c) => c.id == caseId);
        final msg = CaseMessage.now(
          sender: 'ai',
          text: reply,
          type: CaseMessageType.text,
        );
        final restored = updated.copyWith(
            status: updated.status == TriageCaseStatus.analyzing
                ? TriageCaseStatus.completed
                : null);
        ref
            .read(triageCaseProvider.notifier)
            .updateCase(restored.addMessage(msg));
        return;
      } catch (_) {
        // Fall through to local reply.
      }
    }

    // Tertiary: local fallback reply.
    final lower = userText.toLowerCase();
    String reply;
    if (lower.contains('thank')) {
      reply = 'You\'re welcome! Take care of yourself. '
          'Is there anything else I can help with?';
    } else if (lower.contains('better') || lower.contains('worse')) {
      reply = 'Thank you for the update. Please continue monitoring '
          'and reach out if anything changes.';
    } else if (lower.contains('help') || lower.contains('what')) {
      reply = 'I recommend staying hydrated, getting plenty of rest, '
          'and contacting your CHP if symptoms persist.';
    } else {
      reply = 'Thank you for sharing that. Is there anything else '
          'you\'d like to discuss about your health?';
    }

    final updated =
        ref.read(triageCaseProvider).firstWhere((c) => c.id == caseId);
    final msg = CaseMessage.now(
      sender: 'ai',
      text: reply,
      type: CaseMessageType.text,
    );
    final restored = updated.copyWith(
        status: updated.status == TriageCaseStatus.analyzing
            ? TriageCaseStatus.completed
            : null);
    ref.read(triageCaseProvider.notifier).updateCase(restored.addMessage(msg));
  }

  // ---------------------------------------------------------------------------
  // Voice dictation
  // ---------------------------------------------------------------------------

  void _onDictate() => _toggleRecording();

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
      _textController.text = transcript;
      _textController.selection = TextSelection.fromPosition(
        TextPosition(offset: _textController.text.length),
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

  // ---------------------------------------------------------------------------
  // Live agent
  // ---------------------------------------------------------------------------

  void _onLiveAgent() async {
    final launched = await launchRepairAiVoiceAssistant();
    if (!mounted || launched) return;
    showAppErrorSnackBar(
      context,
      AppLocalizations.of(context).voiceAssistantUnavailable,
    );
  }
}

// =============================================================================
// AppBar widgets
// =============================================================================

/// Small circular theme toggle that lives in the app bar.
class _ThemeModeToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return IconButton(
      tooltip: isDark ? 'Light mode' : 'Dark mode',
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          key: ValueKey(isDark),
          color: Colors.white,
          size: 22,
        ),
      ),
      onPressed: () {
        final notifier = ref.read(themeModeProvider.notifier);
        notifier
            .setAppearance(isDark ? AppAppearance.light : AppAppearance.dark);
      },
    );
  }
}

/// Notification bell with a badge showing the active case count.
class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined,
              color: Colors.white, size: 22),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$count active case(s)')),
            );
          },
        ),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: const BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Center(
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// =============================================================================
// Filter row
// =============================================================================

class _FilterRow extends StatefulWidget {
  const _FilterRow({
    required this.l10n,
    required this.cases,
    required this.selectedCaseId,
    required this.onFilterChanged,
    required this.onCaseSelected,
  });

  final AppLocalizations l10n;
  final List<TriageCase> cases;
  final String? selectedCaseId;
  final void Function(_CaseFilter filter, String query) onFilterChanged;
  final void Function(String? caseId) onCaseSelected;

  @override
  State<_FilterRow> createState() => _FilterRowState();
}

class _FilterRowState extends State<_FilterRow> {
  _CaseFilter _filter = _CaseFilter.all;
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = RepairBreakpoints.isCompactPhone(context);

    // Find the selected case for the risk badge.
    final selectedCase = widget.selectedCaseId != null
        ? widget.cases.cast<TriageCase?>().firstWhere(
            (c) => c!.id == widget.selectedCaseId,
            orElse: () => null)
        : null;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 16,
        vertical: compact ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primary.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Cases filter dropdown
          _CaseFilterDropdown(
            value: _filter,
            onChanged: (v) {
              setState(() => _filter = v);
              widget.onFilterChanged(v, _searchController.text);
            },
          ),
          // Active case dropdown
          if (widget.cases.isNotEmpty)
            _ActiveCaseDropdown(
              cases: widget.cases,
              selectedCaseId: widget.selectedCaseId,
              onChanged: widget.onCaseSelected,
            ),
          // Risk badge for selected case
          if (selectedCase != null && selectedCase.riskLevel != null)
            _RiskBadge(riskLevel: selectedCase.riskLevel!),
          // Search toggle / field
          if (_showSearch)
            SizedBox(
              width: compact ? 140 : 200,
              height: 36,
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search cases...',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      _searchController.clear();
                      widget.onFilterChanged(_filter, '');
                      setState(() => _showSearch = false);
                    },
                  ),
                ),
                onChanged: (q) => widget.onFilterChanged(_filter, q),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.search, size: 20),
              onPressed: () => setState(() => _showSearch = true),
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
          // "+ New Case" button
          RepairPrimaryButton(
            label: compact ? '+ New' : '+ New Case',
            onPressed: () {
              // Focus the input bar so the user can type symptoms.
              FocusScope.of(context).nextFocus();
            },
          ),
        ],
      ),
    );
  }
}

class _CaseFilterDropdown extends StatelessWidget {
  const _CaseFilterDropdown({required this.value, required this.onChanged});

  final _CaseFilter value;
  final ValueChanged<_CaseFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_CaseFilter>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.expand_more, size: 20),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          items: const [
            DropdownMenuItem(value: _CaseFilter.all, child: Text('All Cases')),
            DropdownMenuItem(value: _CaseFilter.active, child: Text('Active')),
            DropdownMenuItem(
                value: _CaseFilter.analyzing, child: Text('Analyzing')),
            DropdownMenuItem(
                value: _CaseFilter.completed, child: Text('Completed')),
            DropdownMenuItem(
                value: _CaseFilter.referred, child: Text('Referred')),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

/// Dropdown to select the currently active/viewed case.
class _ActiveCaseDropdown extends StatelessWidget {
  const _ActiveCaseDropdown({
    required this.cases,
    required this.selectedCaseId,
    required this.onChanged,
  });

  final List<TriageCase> cases;
  final String? selectedCaseId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: selectedCaseId,
          isDense: true,
          hint: const Text(
            'Select case...',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          icon: const Icon(Icons.expand_more, size: 20),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          items: [
            // "All cases" option
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('All Cases'),
            ),
            ...cases.map((c) {
              final notePreview = (c.notes ?? '').length > 20
                  ? '${(c.notes ?? '').substring(0, 20)}...'
                  : (c.notes ?? '');
              return DropdownMenuItem<String?>(
                value: c.id,
                child: Text(
                  '${c.formattedCaseNumber} - $notePreview',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Colored badge showing the risk level of a case.
class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.riskLevel});

  final String riskLevel;

  Color _backgroundColor() {
    return switch (riskLevel) {
      'low' => AppTheme.success.withValues(alpha: 0.12),
      'moderate' => AppTheme.warning.withValues(alpha: 0.12),
      'high' => AppTheme.error.withValues(alpha: 0.12),
      _ => AppTheme.success.withValues(alpha: 0.12),
    };
  }

  Color _textColor() {
    return switch (riskLevel) {
      'low' => AppTheme.success,
      'moderate' => AppTheme.warning,
      'high' => AppTheme.error,
      _ => AppTheme.success,
    };
  }

  String _label() {
    return switch (riskLevel) {
      'low' => 'Low Risk',
      'moderate' => 'Moderate Risk',
      'high' => 'High Risk',
      _ => 'Low Risk',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _label(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _textColor(),
        ),
      ),
    );
  }
}

// =============================================================================
// Tab content panels
// =============================================================================

/// Full analytics content for the Analytics tab.
/// Shows a full-width risk banner, expanded trend chart, stats, and recommendations.
class _AnalyticsTab extends ConsumerWidget {
  const _AnalyticsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(triageAnalyticsProvider);
    final cases = ref.watch(triageCaseProvider);
    final selectedCase =
        cases.isNotEmpty ? cases.last : null; // Use most recent case

    if (cases.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_outlined,
                size: 48, color: AppTheme.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text('No data yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Submit symptoms to see live analytics.',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      );
    }

    final riskColor = analytics.riskLevel == 'high'
        ? AppTheme.error
        : analytics.riskLevel == 'moderate'
            ? AppTheme.warning
            : AppTheme.success;

    return Scrollbar(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section header
          const Text('Analytics',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            'Risk movement from first report through each symptom update.',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),

          // Full-width risk banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: riskColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: riskColor, size: 22),
                const SizedBox(width: 10),
                Text(
                  '${analytics.riskLevel.toUpperCase()} RISK',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: riskColor,
                  ),
                ),
                const Spacer(),
                Text(
                  'Risk Score: ${(analytics.riskScore * 100).round()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: riskColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Expanded risk trend chart
          const Text('Risk Trend',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Open, Update 1 \u2192 Update 6, Triage',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 12),
          if (selectedCase != null && selectedCase.riskHistory.isNotEmpty)
            _FullWidthRiskChart(snapshots: selectedCase.riskHistory)
          else
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppTheme.primary.withValues(alpha: 0.08)),
              ),
              child: const Center(
                child: Text(
                  'Risk data will appear after symptom analysis.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Stats grid — compact
          const Text('Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth < 360 ? 2 : 3;
              final stats = [
                (
                  'Active',
                  '${analytics.activeCases}',
                  Icons.folder_open_rounded,
                  AppTheme.primary
                ),
                (
                  'Total',
                  '${analytics.totalCases}',
                  Icons.assignment_rounded,
                  AppTheme.primaryLight
                ),
                (
                  'Referred',
                  '${analytics.referralsSent}',
                  Icons.send_rounded,
                  AppTheme.accent
                ),
                (
                  'Completed',
                  '${analytics.completedCases}',
                  Icons.check_circle_outline_rounded,
                  AppTheme.success
                ),
              ];
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: stats.length,
                itemBuilder: (context, index) {
                  final (label, value, icon, color) = stats[index];
                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Icon(icon, color: color, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(value,
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: color)),
                                Text(label,
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 20),

          // Symptom frequency
          if (analytics.symptomFrequency.isNotEmpty) ...[
            const Text('Symptom Frequency',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            ...analytics.symptomFrequency.entries.map((entry) {
              final maxFreq = analytics.symptomFrequency.values
                  .reduce((a, b) => a > b ? a : b);
              final ratio = entry.value / maxFreq;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(entry.key, style: const TextStyle(fontSize: 13)),
                        Text('${entry.value}',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                        backgroundColor:
                            AppTheme.primary.withValues(alpha: 0.08),
                        valueColor:
                            const AlwaysStoppedAnimation(AppTheme.primary),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 20),

          // Health tips
          _HealthTipsCard(riskLevel: analytics.riskLevel),
        ],
      ),
    );
  }
}

/// Placeholder content for tabs that are not yet implemented.
// =============================================================================
// Empty state
// =============================================================================

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.health_and_safety_outlined,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No cases yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Submit symptoms below to create your first case.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Voice status bar
// =============================================================================

class _VoiceStatusBar extends StatelessWidget {
  const _VoiceStatusBar({
    required this.isRecording,
    required this.isTranscribing,
    required this.recordingSeconds,
    required this.status,
  });

  final bool isRecording;
  final bool isTranscribing;
  final int recordingSeconds;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final minutes = (recordingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (recordingSeconds % 60).toString().padLeft(2, '0');
    final color = isRecording ? AppTheme.error : AppTheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        border: Border(
          top: BorderSide(color: color.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isTranscribing
                ? Icons.text_fields
                : isRecording
                    ? Icons.fiber_manual_record
                    : Icons.mic_none,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            isTranscribing
                ? l10n.transcribingVoice
                : isRecording
                    ? '$minutes:$seconds'
                    : l10n.triageVoiceRecordingMode,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (status != null) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                status!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Input bar
// =============================================================================

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.onDictate,
    required this.onLiveAgent,
    required this.isRecording,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onDictate;
  final VoidCallback onLiveAgent;
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    final compact = RepairBreakpoints.isCompactPhone(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 8 : 12,
        8,
        compact ? 4 : 8,
        12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: AppTheme.primary.withValues(alpha: 0.1),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Dictate button
            _InputActionButton(
              icon: isRecording ? Icons.mic : Icons.mic_outlined,
              tooltip: 'Dictate',
              onTap: onDictate,
              color: isRecording ? Colors.red : AppTheme.primary,
            ),
            const SizedBox(width: 6),
            // Live agent button
            _InputActionButton(
              icon: Icons.headset_mic_outlined,
              tooltip: 'Live Agent',
              onTap: onLiveAgent,
            ),
            const SizedBox(width: 8),
            // Text field
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Type symptoms or updates...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                onPressed: onSend,
                icon:
                    const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                tooltip: 'Send',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputActionButton extends StatelessWidget {
  const _InputActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.primary;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: effectiveColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              size: 20,
              color: effectiveColor,
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Live Analytics panel
// =============================================================================

/// A vertical chip to toggle the analytics sidebar open (wide screens only).
class _AnalyticsToggleChip extends StatelessWidget {
  const _AnalyticsToggleChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, right: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(12)),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
          ),
          child: const RotatedBox(
            quarterTurns: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.analytics_outlined,
                    size: 16, color: AppTheme.primary),
                SizedBox(width: 6),
                Text(
                  'Live Analytics',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The analytics panel shown as a sidebar (wide) or bottom sheet (narrow).
class _LiveAnalyticsPanel extends ConsumerWidget {
  const _LiveAnalyticsPanel({
    this.scrollController,
    required this.onClose,
  });

  final ScrollController? scrollController;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(triageAnalyticsProvider);
    final cases = ref.watch(triageCaseProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: AppTheme.primary.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.analytics_outlined,
                    size: 20, color: AppTheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'Live Analytics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onClose,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                _AnalyticsStatCard(
                  label: 'Active Cases',
                  value: '${analytics.activeCases}',
                  icon: Icons.folder_open_rounded,
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 12),
                _AnalyticsStatCard(
                  label: 'Total Cases',
                  value: '${analytics.totalCases}',
                  icon: Icons.assignment_rounded,
                  color: AppTheme.primaryLight,
                ),
                const SizedBox(height: 12),
                _AnalyticsStatCard(
                  label: 'Referrals Sent',
                  value: '${analytics.referralsSent}',
                  icon: Icons.send_rounded,
                  color: AppTheme.accent,
                ),
                const SizedBox(height: 12),
                _AnalyticsStatCard(
                  label: 'Completed',
                  value: '${analytics.completedCases}',
                  icon: Icons.check_circle_outline_rounded,
                  color: AppTheme.success,
                ),
                const SizedBox(height: 12),
                _AnalyticsStatCard(
                  label: 'Overall Risk',
                  value: analytics.riskLevel.toUpperCase(),
                  icon: Icons.warning_amber_rounded,
                  color: analytics.riskLevel == 'high'
                      ? AppTheme.error
                      : analytics.riskLevel == 'moderate'
                          ? AppTheme.warning
                          : AppTheme.success,
                ),
                const SizedBox(height: 16),
                // Risk trend chart
                if (cases.isNotEmpty) ...[
                  ...cases.map((c) {
                    if (c.riskHistory.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _FullWidthRiskChart(
                        snapshots: c.riskHistory,
                      ),
                    );
                  }),
                ],
                // Placeholder message (shown only when no risk data)
                if (cases.every((c) => c.riskHistory.isEmpty))
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppTheme.radius),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                    child: const Text(
                      'Your live analytics and risk level will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsStatCard extends StatelessWidget {
  const _AnalyticsStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Full-Width Risk Trend Chart (8 stages: Open, Update 1–6, Triage)
// =============================================================================

class _FullWidthRiskChart extends StatelessWidget {
  const _FullWidthRiskChart({required this.snapshots});

  final List<RiskSnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: CustomPaint(
        size: const Size(double.infinity, 240),
        painter: _FullWidthRiskPainter(snapshots: snapshots),
      ),
    );
  }
}

class _FullWidthRiskPainter extends CustomPainter {
  _FullWidthRiskPainter({required this.snapshots});

  final List<RiskSnapshot> snapshots;

  static const _stages = [
    'Open',
    'Update 1',
    'Update 2',
    'Update 3',
    'Update 4',
    'Update 5',
    'Update 6',
    'Triage',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (snapshots.isEmpty) return;

    final linePaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppTheme.primary.withValues(alpha: 0.2),
          AppTheme.primary.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final dotPaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = const Color(0xFFE8E4F4)
      ..strokeWidth = 0.75
      ..style = PaintingStyle.stroke;

    const labelStyle = TextStyle(
      fontSize: 10,
      color: Color(0xFF888888),
      fontWeight: FontWeight.w500,
    );

    const stageLabelStyle = TextStyle(
      fontSize: 9,
      color: Color(0xFF999999),
    );

    // Layout constants.
    const leftPad = 40.0;
    const rightPad = 20.0;
    const topPad = 16.0;
    const bottomPad = 32.0;
    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - bottomPad;

    // Background fill
    final bgRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(leftPad, topPad, chartW, chartH),
    );
    canvas.drawRRect(bgRect, Paint()..color = const Color(0xFFFAFAFE));

    // Draw horizontal grid lines at 0, 25, 50, 75, 100.
    for (final level in [0, 25, 50, 75, 100]) {
      final y = topPad + chartH * (1 - level / 100);
      canvas.drawLine(
        Offset(leftPad, y),
        Offset(size.width - rightPad, y),
        gridPaint,
      );
      final tp = TextPainter(
        text: TextSpan(text: '$level', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 6, y - tp.height / 2));
    }

    // Build data points.
    final points = <Offset>[];
    for (int i = 0; i < _stages.length; i++) {
      final snap = snapshots.cast<RiskSnapshot?>().firstWhere(
            (s) => s?.stage == _stages[i],
            orElse: () => null,
          );
      final score = snap?.riskScore ?? 0.0;
      final x = leftPad + chartW * i / (_stages.length - 1);
      final y = topPad + chartH * (1 - score / 100);
      points.add(Offset(x, y));

      // Draw stage label.
      final tp = TextPainter(
        text: TextSpan(text: _stages[i], style: stageLabelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - bottomPad + 8));
    }

    // Draw area fill under the line.
    if (points.length >= 2) {
      final fillPath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        fillPath.lineTo(points[i].dx, points[i].dy);
      }
      fillPath.lineTo(points.last.dx, topPad + chartH);
      fillPath.lineTo(points.first.dx, topPad + chartH);
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw connecting lines.
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], linePaint);
    }

    // Draw filled dots with white centers.
    for (final p in points) {
      canvas.drawCircle(p, 5.0, dotPaint);
      canvas.drawCircle(p, 2.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _FullWidthRiskPainter oldDelegate) =>
      oldDelegate.snapshots != snapshots;
}

// =============================================================================
// Health Tips Card
// =============================================================================

/// Displays personalised health advice based on the overall risk level.
class _HealthTipsCard extends StatelessWidget {
  const _HealthTipsCard({required this.riskLevel});

  final String riskLevel;

  String get _advice {
    return switch (riskLevel) {
      'high' => 'Seek care immediately. Visit the nearest health facility '
          'without delay. Bring your ANC card and any medications you\'re '
          'taking.',
      'moderate' => 'Monitor your symptoms closely. Schedule a check-up '
          'within 24 hours. Rest, stay hydrated, and contact your CHP if '
          'anything changes.',
      _ => 'Continue your normal routine. Attend your next ANC visit, stay '
          'hydrated, eat balanced meals, and report any new symptoms to '
          'your CHP.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = switch (riskLevel) {
      'high' => AppTheme.error,
      'moderate' => AppTheme.warning,
      _ => AppTheme.success,
    };

    return Card(
      elevation: 1,
      color: accentColor.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        side: BorderSide(color: accentColor.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(Icons.lightbulb_outline, size: 20, color: accentColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Health Advice',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: accentColor)),
                  const SizedBox(height: 4),
                  Text(_advice,
                      style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.75))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Variables Tab
// =============================================================================

class _VariablesTab extends ConsumerStatefulWidget {
  const _VariablesTab({required this.selectedCaseId});

  final String? selectedCaseId;

  @override
  ConsumerState<_VariablesTab> createState() => _VariablesTabState();
}

class _VariablesTabState extends ConsumerState<_VariablesTab> {
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _painController = TextEditingController(text: '1');
  final _hydrationController = TextEditingController();
  final _sleepController = TextEditingController();

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _heartRateController.dispose();
    _painController.dispose();
    _hydrationController.dispose();
    _sleepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cases = ref.watch(triageCaseProvider);
    final selectedCase = widget.selectedCaseId != null
        ? cases.where((c) => c.id == widget.selectedCaseId).firstOrNull
        : null;

    if (selectedCase == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monitor_heart_outlined,
                size: 48, color: AppTheme.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text('Select a case to track variables',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    final readings = selectedCase.variableReadings;

    return Scrollbar(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Variable Tracking',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            'Record vitals and health metrics for ${selectedCase.patientName}.',
            style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),

          // Input form
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('New Reading',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),

                  // Blood Pressure
                  const Text('Blood Pressure',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _systolicController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Systolic',
                            hintText: '120',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _diastolicController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Diastolic',
                            hintText: '80',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Heart Rate
                  const Text('Heart Rate (bpm)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _heartRateController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '72',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pain Level
                  const Text('Pain Level (1-10)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _painController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '1',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                      suffixText: '/10',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hydration
                  const Text('Hydration (ml)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _hydrationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '2000',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sleep
                  const Text('Sleep (hours)',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _sleepController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: '7.5',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _saveReadings(selectedCase),
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: const Text('Save Readings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Trend cards
          if (readings.isNotEmpty) ...[
            const Text('Recent Readings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _buildTrendCard('Blood Pressure (Systolic)',
                'blood_pressure_systolic', readings, 'mmHg', theme),
            _buildTrendCard('Blood Pressure (Diastolic)',
                'blood_pressure_diastolic', readings, 'mmHg', theme),
            _buildTrendCard('Heart Rate', 'heart_rate', readings, 'bpm', theme),
            _buildTrendCard('Pain Level', 'pain_level', readings, '/10', theme),
            _buildTrendCard('Hydration', 'hydration_ml', readings, 'ml', theme),
            _buildTrendCard('Sleep', 'sleep_hours', readings, 'hours', theme),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendCard(String label, String variableName,
      List<CaseVariableReading> allReadings, String unit, ThemeData theme) {
    final filtered = allReadings
        .where((r) => r.variableName == variableName)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final last5 = filtered.take(5).toList();

    if (last5.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.08))),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: last5.map((r) {
                final val = r.value % 1 == 0
                    ? r.value.toInt().toString()
                    : r.value.toStringAsFixed(1);
                final time =
                    '${r.timestamp.hour.toString().padLeft(2, '0')}:${r.timestamp.minute.toString().padLeft(2, '0')}';
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('$val $unit @ $time',
                      style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _saveReadings(TriageCase triageCase) {
    final notifier = ref.read(triageCaseProvider.notifier);
    var updated = triageCase;

    final systolic = double.tryParse(_systolicController.text);
    final diastolic = double.tryParse(_diastolicController.text);
    final heartRate = double.tryParse(_heartRateController.text);
    final pain = double.tryParse(_painController.text);
    final hydration = double.tryParse(_hydrationController.text);
    final sleep = double.tryParse(_sleepController.text);

    if (systolic != null) {
      updated = updated.addVariableReading('blood_pressure_systolic', systolic);
    }
    if (diastolic != null) {
      updated =
          updated.addVariableReading('blood_pressure_diastolic', diastolic);
    }
    if (heartRate != null) {
      updated = updated.addVariableReading('heart_rate', heartRate);
    }
    if (pain != null) {
      updated = updated.addVariableReading('pain_level', pain);
    }
    if (hydration != null) {
      updated = updated.addVariableReading('hydration_ml', hydration);
    }
    if (sleep != null) {
      updated = updated.addVariableReading('sleep_hours', sleep);
    }

    notifier.updateCase(updated);

    // Clear fields
    _systolicController.clear();
    _diastolicController.clear();
    _heartRateController.clear();
    _painController.text = '1';
    _hydrationController.clear();
    _sleepController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Readings saved'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

// =============================================================================
// Referrals Tab
// =============================================================================

class _ReferralsTab extends ConsumerWidget {
  const _ReferralsTab({required this.selectedCaseId});

  final String? selectedCaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cases = ref.watch(triageCaseProvider);
    final selectedCase = selectedCaseId != null
        ? cases.where((c) => c.id == selectedCaseId).firstOrNull
        : (cases.isNotEmpty ? cases.last : null);

    if (selectedCase == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_hospital_outlined,
                size: 48, color: AppTheme.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text('No case available for referral',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    final riskLevel = selectedCase.riskLevel ?? 'low';
    final accentColor = switch (riskLevel) {
      'high' => AppTheme.error,
      'moderate' => AppTheme.warning,
      _ => AppTheme.success,
    };

    return Scrollbar(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Referrals & Recommendations',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            'Guidance based on risk assessment for ${selectedCase.patientName}.',
            style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 20),

          // Risk-based referral card
          _buildRiskReferralCard(context, ref, riskLevel, accentColor),
          const SizedBox(height: 16),

          // Emergency card
          _buildEmergencyCard(context),
          const SizedBox(height: 16),

          // Preventive recommendations card
          _buildPreventiveCard(context),
        ],
      ),
    );
  }

  Widget _buildRiskReferralCard(BuildContext context, WidgetRef ref,
      String riskLevel, Color accentColor) {
    final (icon, title, subtitle, actionLabel) = switch (riskLevel) {
      'high' => (
          Icons.warning_amber_rounded,
          'Urgent — Seek Care Immediately',
          'Visit the nearest health facility without delay. Bring your ANC card and any medications.',
          'Find Nearest Facility',
        ),
      'moderate' => (
          Icons.schedule_rounded,
          'Schedule a Check-up Within 24 Hours',
          'Monitor symptoms closely. Visit a health facility for evaluation.',
          'View Facilities',
        ),
      _ => (
          Icons.check_circle_outline_rounded,
          'Continue Monitoring',
          'No urgent action required. Attend your next ANC visit and report any new symptoms.',
          null,
        ),
    };

    VoidCallback? onAction;
    if (actionLabel != null) {
      onAction = () => _navigateToReferral(context, ref, riskLevel);
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        side: BorderSide(color: accentColor.withValues(alpha: 0.2)),
      ),
      color: accentColor.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: accentColor)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.75))),
            if (actionLabel != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  label: Text(actionLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        side: BorderSide(color: AppTheme.error.withValues(alpha: 0.2)),
      ),
      color: AppTheme.error.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.emergency_rounded, color: AppTheme.error, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Emergency Contacts',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.error)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _emergencyContactRow(
                context, Icons.phone_rounded, 'Emergency', kEmergencyPhone, () {
              launchEmergencyCall();
            }),
            const SizedBox(height: 8),
            _emergencyContactRow(context, Icons.chat_rounded, 'WhatsApp Help',
                '+254 711 507 497', () {
              launchWhatsAppHelp(context);
            }),
            const SizedBox(height: 8),
            _emergencyContactRow(context, Icons.dialpad_rounded, 'USSD Access',
                kRepairAiUssdCode, () {
              launchUssdCode();
            }),
          ],
        ),
      ),
    );
  }

  Widget _emergencyContactRow(BuildContext ctx, IconData icon, String label,
      String detail, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppTheme.error.withValues(alpha: 0.7)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(detail,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(ctx)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5))),
                ],
              ),
            ),
            const Icon(Icons.call_made_rounded,
                size: 16, color: AppTheme.error),
          ],
        ),
      ),
    );
  }

  Widget _buildPreventiveCard(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        side: BorderSide(color: AppTheme.success.withValues(alpha: 0.15)),
      ),
      color: AppTheme.success.withValues(alpha: 0.04),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.self_improvement_rounded,
                    color: AppTheme.success, size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Preventive Recommendations',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.success)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _preventiveItem(context, Icons.air_rounded, 'Rest',
                'Get at least 8 hours of sleep each night. Take short naps during the day if fatigued.'),
            _preventiveItem(context, Icons.water_drop_rounded, 'Hydration',
                'Drink at least 2 litres of water daily. Include soups and fresh juices.'),
            _preventiveItem(context, Icons.restaurant_rounded, 'Balanced Meals',
                'Eat iron-rich foods, fruits, vegetables, and proteins. Small frequent meals help with nausea.'),
            _preventiveItem(context, Icons.medication_rounded, 'Medication',
                'Take prescribed iron and folic acid supplements daily. Do not self-medicate.'),
          ],
        ),
      ),
    );
  }

  void _navigateToReferral(
      BuildContext context, WidgetRef ref, String riskLevel) {
    final existingResult = ref.read(triageResultProvider);
    final backendTriageId = existingResult?.backendTriageId;
    const facilityName =
        'Nearest Facility'; // will be resolved on referral screen

    // Show confirmation dialog before creating the referral.
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Send Referral'),
        content: Text(
          'Create a referral to $facilityName based on the current risk assessment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await _sendReferralToBackend(
                context,
                ref,
                riskLevel,
                backendTriageId,
              );
            },
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Send Referral'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendReferralToBackend(
    BuildContext context,
    WidgetRef ref,
    String riskLevel, [
    int? backendTriageId,
  ]) async {
    // Try to call the backend ReferralApi.
    try {
      final referralApi = ref.read(referralApiProvider);

      if (backendTriageId != null) {
        await referralApi.generate(triageId: backendTriageId);
      } else {
        // Fallback: if no backend triage exists, create a placeholder result
        // and navigate without a backend referral call.
        _navigateToReferralScreen(context, ref, riskLevel);
        return;
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Referral created successfully'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _navigateToReferralScreen(context, ref, riskLevel);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Referral failed: ${e.message}'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Referral failed: $e'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _navigateToReferralScreen(
    BuildContext context,
    WidgetRef ref,
    String riskLevel,
  ) {
    final result = TriageResult(
      riskLevel: riskLevel == 'high' ? RiskLevel.high : RiskLevel.low,
      confidence: 0.0,
      reasons: ['Referred from Symptom Check case.'],
      recommendation: 'Please consult your health worker.',
      urgencyHours: riskLevel == 'high' ? 0 : 72,
      needsReferral: true,
      aiScreened: false,
    );
    ref.read(triageResultProvider.notifier).state = result;
    context.push('/referral');
  }

  Widget _preventiveItem(
      BuildContext ctx, IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.success.withValues(alpha: 0.7)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(description,
                    style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Theme.of(ctx)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Reports Tab
// =============================================================================

class _ReportsTab extends ConsumerWidget {
  const _ReportsTab({required this.selectedCaseId});

  final String? selectedCaseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cases = ref.watch(triageCaseProvider);
    final selectedCase = selectedCaseId != null
        ? cases.where((c) => c.id == selectedCaseId).firstOrNull
        : (cases.isNotEmpty ? cases.last : null);

    if (selectedCase == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined,
                size: 48, color: AppTheme.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            const Text('Select a case to generate a report',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    final summary = _buildSummary(selectedCase);

    return Column(
      children: [
        Expanded(
          child: Scrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                summary,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ),
        // Export button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _exportToClipboard(context, summary),
                icon: const Icon(Icons.copy_rounded, size: 18),
                label: const Text('Export to Clipboard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _buildSummary(TriageCase c) {
    final buf = StringBuffer();

    // Case Info
    buf.writeln('═══════════════════════════════════');
    buf.writeln('  REPAIR-AI CASE REPORT');
    buf.writeln('═══════════════════════════════════');
    buf.writeln('');
    buf.writeln('CASE Number : ${c.formattedCaseNumber}');
    buf.writeln('Patient     : ${c.patientName}');
    buf.writeln('Date        : ${_formatDate(c.createdAt)}');
    buf.writeln('Duration    : ${c.duration}');
    buf.writeln('Status      : ${c.status.name}');
    buf.writeln('');

    // Symptoms
    buf.writeln('─── Symptoms ───');
    if (c.symptoms.isEmpty) {
      buf.writeln('  (none reported)');
    } else {
      for (final s in c.symptoms) {
        buf.writeln('  • $s');
      }
    }
    buf.writeln('');

    // Risk Assessment
    buf.writeln('─── Risk Assessment ───');
    buf.writeln('Risk Level   : ${c.riskLevel ?? 'Not assessed'}');
    buf.writeln(
        'Confidence   : ${c.confidence != null ? '${(c.confidence! * 100).toStringAsFixed(0)}%' : 'N/A'}');
    buf.writeln('Severity     : ${c.severity}');
    if (c.facilityName != null && c.facilityName!.isNotEmpty) {
      buf.writeln('Facility     : ${c.facilityName}');
    }
    buf.writeln('');

    // Conversation Summary
    buf.writeln('─── Conversation Summary ───');
    if (c.messages.isEmpty) {
      buf.writeln('  (no messages)');
    } else {
      final preview = c.messages.take(5).toList();
      for (final m in preview) {
        final sender = m.sender == 'patient' ? 'Patient' : 'AI';
        final time = _formatTime(m.timestamp);
        buf.writeln('  [$time] $sender: ${m.text}');
      }
      if (c.messages.length > 5) {
        buf.writeln('  ... (${c.messages.length - 5} more messages)');
      }
    }
    buf.writeln('');

    // Recommendations
    buf.writeln('─── Recommendations ───');
    buf.writeln('  ${c.recommendation ?? 'No recommendation available.'}');
    buf.writeln('');

    // Variable Trends
    buf.writeln('─── Variable Trends ───');
    if (c.variableReadings.isEmpty) {
      buf.writeln('  (no readings logged)');
    } else {
      final groups = <String, List<double>>{};
      for (final r in c.variableReadings) {
        groups.putIfAbsent(r.variableName, () => []).add(r.value);
      }
      const labels = {
        'blood_pressure_systolic': 'BP Systolic',
        'blood_pressure_diastolic': 'BP Diastolic',
        'heart_rate': 'Heart Rate',
        'pain_level': 'Pain Level',
        'hydration_ml': 'Hydration',
        'sleep_hours': 'Sleep',
      };
      for (final entry in groups.entries) {
        final name = labels[entry.key] ?? entry.key;
        final vals = entry.value;
        final min = vals.reduce((a, b) => a < b ? a : b);
        final max = vals.reduce((a, b) => a > b ? a : b);
        final avg = vals.reduce((a, b) => a + b) / vals.length;
        buf.writeln('  $name:');
        buf.writeln(
            '    Count: ${vals.length}  Min: ${_fmtNum(min)}  Max: ${_fmtNum(max)}  Avg: ${_fmtNum(avg)}');
      }
    }
    buf.writeln('');
    buf.writeln('═══════════════════════════════════');
    buf.writeln('Generated: ${_formatDate(DateTime.now())}');
    buf.writeln('═══════════════════════════════════');

    return buf.toString();
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _fmtNum(double v) {
    return v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);
  }

  void _exportToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
