import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/network/backend_services.dart';
import 'package:repair_ai/features/triage/domain/case_model.dart';
import 'package:repair_ai/localization/app_localizations.dart';

/// Shows the real-time chat conversation for the selected case.
/// Falls back to the case list when no case is selected.
class SymptomChatTab extends ConsumerStatefulWidget {
  const SymptomChatTab({
    super.key,
    required this.cases,
    required this.selectedCaseId,
  });

  final List<TriageCase> cases;
  final String? selectedCaseId;

  @override
  ConsumerState<SymptomChatTab> createState() => _SymptomChatTabState();
}

class _SymptomChatTabState extends ConsumerState<SymptomChatTab> {
  final _scrollController = ScrollController();
  List<CaseMessage> _mergedMessages = [];
  bool _loadingBackend = false;
  String? _lastLoadedVisitId;

  TriageCase? get _activeCase {
    if (widget.selectedCaseId == null) return null;
    try {
      return widget.cases.firstWhere((c) => c.id == widget.selectedCaseId);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _syncMergedMessages();
  }

  @override
  void didUpdateWidget(covariant SymptomChatTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final active = _activeCase;
    if (oldWidget.selectedCaseId != widget.selectedCaseId ||
        active?.backendVisitId != null &&
            active!.backendVisitId.toString() != _lastLoadedVisitId) {
      _syncMergedMessages();
    }
  }

  /// Merges local case messages with any messages from the backend visit.
  void _syncMergedMessages() {
    final active = _activeCase;
    if (active == null) {
      _mergedMessages = [];
      return;
    }
    _mergedMessages = List.unmodifiable(active.messages);
    if (active.backendVisitId != null &&
        active.backendVisitId.toString() != _lastLoadedVisitId) {
      _loadBackendMessages(active.backendVisitId!);
    }
  }

  Future<void> _loadBackendMessages(int visitId) async {
    if (_loadingBackend) return;
    setState(() => _loadingBackend = true);
    try {
      final visits = await ref.read(visitApiProvider).visits();
      final visit = visits.cast<Map<String, dynamic>?>().firstWhere(
            (v) => v?['id'] == visitId,
            orElse: () => null,
          );
      if (visit == null || !mounted) return;
      final msgs = visit['case_messages'] as List<dynamic>? ?? [];
      final backendMessages = msgs
          .whereType<Map>()
          .map((m) => CaseMessage(
                id: 'backend_${m['id'] ?? DateTime.now().microsecondsSinceEpoch}',
                sender: '${m['sender'] ?? 'ai'}',
                text: '${m['text'] ?? ''}',
                timestamp: m['created_at'] != null
                    ? DateTime.tryParse('${m['created_at']}') ?? DateTime.now()
                    : DateTime.now(),
                type: CaseMessageType.text,
              ))
          .toList();

      // Merge: deduplicate by text similarity, prefer backend timestamps.
      final active = _activeCase;
      if (active == null) return;
      final merged = <CaseMessage>[];
      final seenTexts = <String>{};
      final allMessages = [...backendMessages, ...active.messages];
      // Sort by timestamp so order is preserved.
      allMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      for (final m in allMessages) {
        final key = '${m.sender}|${m.text}';
        if (!seenTexts.contains(key)) {
          seenTexts.add(key);
          merged.add(m);
        }
      }
      setState(() {
        _mergedMessages = List.unmodifiable(merged);
        _lastLoadedVisitId = visitId.toString();
      });
      _scrollToBottom();
    } catch (_) {
      // Backend unavailable — keep local messages only.
    } finally {
      if (mounted) setState(() => _loadingBackend = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeCase;

    // No case selected — show case list.
    if (active == null) {
      if (widget.cases.isEmpty) {
        return _buildEmptyState();
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: widget.cases.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return _CaseCard(triageCase: widget.cases[index]);
        },
      );
    }

    // Chat view for the selected case.
    final messages =
        _mergedMessages.isNotEmpty ? _mergedMessages : active.messages;
    final isAnalyzing = active.status == TriageCaseStatus.analyzing;

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    if (messages.isEmpty && !isAnalyzing) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // AI analysis status banner
        if (isAnalyzing) _buildAnalyzingBanner(),
        // Chat messages
        Expanded(
          child: RepaintBoundary(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isPatient = msg.sender == 'patient';
                return _ChatBubble(message: msg, isPatient: isPatient);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzingBanner() {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.08),
        border: Border(
          bottom: BorderSide(color: AppTheme.warning.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(AppTheme.warning),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.aiAnalyzingYourCase,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 48, color: AppTheme.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(l10n.submitSymptomsForFirstCase,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(l10n.chatWithCareAssistantHint,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat bubble
// ---------------------------------------------------------------------------

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.isPatient});

  final CaseMessage message;
  final bool isPatient;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bubbleColor = isPatient ? AppTheme.primary : AppTheme.surfaceTinted;
    final textColor =
        isPatient ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final timeStr =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isPatient ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isPatient ? 18 : 6),
            bottomRight: Radius.circular(isPatient ? 6 : 18),
          ),
          border: isPatient
              ? null
              : Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isPatient ? l10n.chatSenderYou : l10n.chatSenderCareAssistant,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isPatient
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: isPatient
                        ? Colors.white.withValues(alpha: 0.6)
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              message.text,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Case card (list view fallback)
// ---------------------------------------------------------------------------

class _CaseCard extends StatelessWidget {
  const _CaseCard({required this.triageCase});

  final TriageCase triageCase;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final statusColor = _statusColor(triageCase.status);
    final statusLabel = _statusLabel(triageCase.status, l10n);
    final timeStr =
        '${triageCase.createdAt.hour.toString().padLeft(2, '0')}:${triageCase.createdAt.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        triageCase.formattedCaseNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _subtitleText(l10n),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
            const SizedBox(width: 8),
            // Risk badge (if resolved)
            if (triageCase.riskLevel != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      _riskColor(triageCase.riskLevel!).withValues(alpha: 0.12),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
                child: Text(
                  _riskLabel(triageCase.riskLevel!, l10n),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _riskColor(triageCase.riskLevel!),
                  ),
                ),
              ),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.only(
                  topRight: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                  topLeft: triageCase.riskLevel != null
                      ? Radius.zero
                      : const Radius.circular(20),
                  bottomLeft: triageCase.riskLevel != null
                      ? Radius.zero
                      : const Radius.circular(20),
                ),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitleText(AppLocalizations l10n) {
    if (triageCase.status == TriageCaseStatus.analyzing) {
      return l10n.aiAnalyzingYourCase;
    }
    return triageCase.latestMessage?.text ??
        triageCase.symptoms.take(2).join(', ');
  }

  Color _riskColor(String level) {
    return switch (level) {
      'high' => AppTheme.error,
      'moderate' => AppTheme.warning,
      _ => AppTheme.success,
    };
  }

  String _riskLabel(String level, AppLocalizations l10n) {
    return switch (level) {
      'high' => l10n.caseRiskHigh,
      'moderate' => l10n.caseRiskModerate,
      _ => l10n.caseRiskLow,
    };
  }

  Color _statusColor(TriageCaseStatus status) {
    return switch (status) {
      TriageCaseStatus.active => AppTheme.primary,
      TriageCaseStatus.analyzing => AppTheme.warning,
      TriageCaseStatus.completed => AppTheme.success,
      TriageCaseStatus.referred => AppTheme.accent,
    };
  }

  String _statusLabel(TriageCaseStatus status, AppLocalizations l10n) {
    return switch (status) {
      TriageCaseStatus.active => l10n.caseStatusActive,
      TriageCaseStatus.analyzing => l10n.caseStatusAnalyzing,
      TriageCaseStatus.completed => l10n.completed,
      TriageCaseStatus.referred => l10n.caseStatusReferred,
    };
  }
}
