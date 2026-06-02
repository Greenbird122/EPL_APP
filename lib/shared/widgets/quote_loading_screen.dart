import 'dart:async';

import 'package:flutter/material.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/shared/widgets/motherly_quote_card.dart';

class QuoteLoadingScreen extends StatefulWidget {
  const QuoteLoadingScreen({
    super.key,
    required this.onFinished,
    this.runTask,
    this.minimumDuration = const Duration(seconds: 5),
    this.subtitle,
  });

  final Future<void> Function()? runTask;
  final VoidCallback onFinished;
  final Duration minimumDuration;
  final String? subtitle;

  @override
  State<QuoteLoadingScreen> createState() => _QuoteLoadingScreenState();
}

class _QuoteLoadingScreenState extends State<QuoteLoadingScreen> {
  int _quoteIndex = 0;
  Timer? _rotateTimer;
  bool _taskDone = false;
  bool _minElapsed = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    final quotes = MotherlyQuoteCard.quotesFor(AppLocalizations.of(context));

    _rotateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {
        _quoteIndex = (_quoteIndex + 1) % quotes.length;
      });
    });

    final minimum = Future<void>.delayed(widget.minimumDuration).then((_) {
      if (mounted) {
        setState(() => _minElapsed = true);
        _tryFinish();
      }
    });

    final task = (widget.runTask?.call() ?? Future<void>.value()).then((_) {
      _taskDone = true;
      _tryFinish();
    });

    await Future.wait([minimum, task]);
  }

  void _tryFinish() {
    if (_taskDone && _minElapsed && mounted) {
      _rotateTimer?.cancel();
      widget.onFinished();
    }
  }

  @override
  void dispose() {
    _rotateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quotes = MotherlyQuoteCard.quotesFor(l10n);
    final quote = quotes[_quoteIndex % quotes.length];

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primary.withValues(alpha: 0.12),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 28),
              MotherlyQuoteCard(
                quote: quote,
                author: l10n.motherQuoteAuthor,
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    widget.subtitle!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
