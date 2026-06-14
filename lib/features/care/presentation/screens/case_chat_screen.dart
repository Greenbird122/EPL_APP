import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/network/backend_services.dart';
import 'package:repair_ai/shared/widgets/repair_app_bar.dart';

class CaseChatScreen extends ConsumerStatefulWidget {
  const CaseChatScreen({
    super.key,
    required this.visitId,
    required this.visitTitle,
  });

  final int visitId;
  final String visitTitle;

  @override
  ConsumerState<CaseChatScreen> createState() => _CaseChatScreenState();
}

class _CaseChatScreenState extends ConsumerState<CaseChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final visits = await ref.read(visitApiProvider).visits();
      final visit = visits.cast<Map<String, dynamic>?>().firstWhere(
            (v) => v?['id'] == widget.visitId,
            orElse: () => null,
          );
      if (visit == null) return;
      final msgs = visit['case_messages'] as List<dynamic>? ?? [];
      setState(() {
        _messages.clear();
        _messages.addAll(
            msgs.map((m) => _ChatMessage.fromMap(m as Map<String, dynamic>)));
      });
      _scrollToBottom();
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;
    _messageController.clear();
    setState(() => _isSending = true);

    // Optimistically add patient message
    setState(() {
      _messages.add(_ChatMessage(
        sender: 'patient',
        text: text,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();

    try {
      await ref.read(visitApiProvider).addMessage(widget.visitId, text);
      // Reload to get AI reply
      await _loadMessages();
    } catch (_) {
      setState(() {
        _messages.last = _ChatMessage(
          sender: 'patient',
          text: '$text (not sent)',
          timestamp: DateTime.now(),
        );
      });
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RepairAppBar(title: widget.visitTitle),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('No messages yet'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isPatient = msg.sender == 'patient';
                      return _ChatBubble(
                        message: msg,
                        isPatient: isPatient,
                      );
                    },
                  ),
          ),
          _ChatInput(
            controller: _messageController,
            isSending: _isSending,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String sender;
  final String text;
  final DateTime timestamp;

  const _ChatMessage({
    required this.sender,
    required this.text,
    required this.timestamp,
  });

  factory _ChatMessage.fromMap(Map<String, dynamic> map) {
    final createdAt = map['created_at']?.toString() ?? '';
    return _ChatMessage(
      sender: '${map['sender'] ?? 'patient'}',
      text: '${map['text'] ?? ''}',
      timestamp: DateTime.tryParse(createdAt) ?? DateTime.now(),
    );
  }

  String get formattedTime =>
      '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.isPatient});

  final _ChatMessage message;
  final bool isPatient;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isPatient ? AppTheme.primary : AppTheme.surfaceTinted;
    final textColor =
        isPatient ? Colors.white : Theme.of(context).colorScheme.onSurface;

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
                  isPatient ? 'You' : 'Care Assistant',
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
                  message.formattedTime,
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

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: AppTheme.primary.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'Ask about your symptoms...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                        color: AppTheme.primary.withValues(alpha: 0.15)),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: IconButton(
                onPressed: isSending ? null : onSend,
                icon: isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
