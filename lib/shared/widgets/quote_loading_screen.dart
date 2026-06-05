import 'dart:async';
import 'dart:math' as math;

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

class _QuoteLoadingScreenState extends State<QuoteLoadingScreen>
    with TickerProviderStateMixin {
  int _quoteIndex = 0;
  int _phraseIndex = 0;
  Timer? _rotateTimer;
  bool _taskDone = false;
  bool _minElapsed = false;
  late final AnimationController _ambientController;
  late final AnimationController _progressController;

  static const _loadingPhrases = [
    'Preparing your care space',
    'Checking support channels',
    'Keeping guidance close',
  ];

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.minimumDuration,
    )..forward();
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
        _phraseIndex = (_phraseIndex + 1) % _loadingPhrases.length;
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
    _ambientController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final quotes = MotherlyQuoteCard.quotesFor(l10n);
    final quote = quotes[_quoteIndex % quotes.length];
    final phrase = _loadingPhrases[_phraseIndex % _loadingPhrases.length];
    final size = MediaQuery.sizeOf(context);
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    final compact = size.width < 420;
    final short = size.height < 720;
    final logoSize = (math.min(size.width, size.height) * 0.18)
        .clamp(compact ? 98.0 : 118.0, compact ? 124.0 : 148.0)
        .toDouble();
    final verticalGap = short ? 18.0 : 26.0;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_ambientController, _progressController]),
        builder: (context, _) {
          final t = disableAnimations ? 0.0 : _ambientController.value;
          final pulse = 0.5 + 0.5 * math.sin(t * math.pi * 2);

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.12, -0.22),
                radius: 1.12,
                colors: [
                  Color(0xFF8C6BFF),
                  Color(0xFF6B4EFF),
                  Color(0xFF241B45),
                  Color(0xFF120D24),
                ],
                stops: [0, 0.34, 0.72, 1],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RepairSplashPainter(
                      progress: t,
                      animate: !disableAnimations,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.06 * pulse),
                          Colors.transparent,
                          AppTheme.accent.withValues(alpha: 0.08),
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 22 : 32,
                        vertical: short ? 18 : 28,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _GlowLogo(
                            progress: t,
                            size: logoSize,
                            animate: !disableAnimations,
                          ),
                          SizedBox(height: verticalGap),
                          Text(
                            widget.subtitle ?? l10n.appTitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3.2,
                              shadows: [
                                Shadow(
                                  color:
                                      AppTheme.accent.withValues(alpha: 0.48),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pregnancy care, close by',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.72),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _LoadingPhrase(
                            phrase: phrase,
                            animate: !disableAnimations,
                          ),
                          SizedBox(height: short ? 18 : 28),
                          _LoadingBar(
                            value: _progressController.value,
                            shimmerProgress: t,
                            animate: !disableAnimations,
                          ),
                          SizedBox(height: short ? 18 : 26),
                          AnimatedSwitcher(
                            duration: disableAnimations
                                ? Duration.zero
                                : const Duration(milliseconds: 520),
                            transitionBuilder: (child, animation) {
                              final offset = Tween<Offset>(
                                begin: const Offset(0, 0.08),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ),
                              );
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: offset,
                                  child: child,
                                ),
                              );
                            },
                            child: _SplashQuote(
                              key: ValueKey(quote),
                              quote: quote,
                              author: l10n.motherQuoteAuthor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _GlowLogo extends StatelessWidget {
  const _GlowLogo({
    required this.progress,
    required this.size,
    required this.animate,
  });

  final double progress;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final pulse = animate ? 0.5 + 0.5 * math.sin(progress * math.pi * 2) : 0.5;
    final warmPulse =
        animate ? 0.5 + 0.5 * math.sin(progress * math.pi * 2 + 1.4) : 0.5;

    return SizedBox(
      width: size * 1.9,
      height: size * 1.9,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 3; i++)
            _ExpandingCareWave(
              progress: progress,
              size: size,
              index: i,
              animate: animate,
            ),
          Transform.scale(
            scale: 1 + pulse * 0.10,
            child: Container(
              width: size * 1.72,
              height: size * 1.72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.26),
                  width: 1.4,
                ),
              ),
            ),
          ),
          Transform.scale(
            scale: 1 + pulse * 0.06,
            child: Container(
              width: size * 1.55,
              height: size * 1.55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color.lerp(
                    AppTheme.accent,
                    const Color(0xFFFFB7D5),
                    warmPulse,
                  )!
                      .withValues(alpha: 0.48 + pulse * 0.22),
                  width: 2,
                ),
              ),
            ),
          ),
          Transform.scale(
            scale: animate ? 1 + pulse * 0.035 : 1,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color.lerp(
                      AppTheme.accent,
                      const Color(0xFFFFB7D5),
                      warmPulse,
                    )!
                        .withValues(alpha: 0.36 + pulse * 0.16),
                    blurRadius: 42,
                    spreadRadius: 7,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.16),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/icons/repair_ai_icon.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandingCareWave extends StatelessWidget {
  const _ExpandingCareWave({
    required this.progress,
    required this.size,
    required this.index,
    required this.animate,
  });

  final double progress;
  final double size;
  final int index;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final phase = animate ? (progress + index / 3) % 1.0 : index / 3;
    final opacity = animate ? (1 - phase).clamp(0.0, 1.0) : 0.22;
    final waveSize = size * (1.08 + phase * 0.78);

    return Container(
      width: waveSize,
      height: waveSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFFFD6E8).withValues(alpha: 0.24 * opacity),
          width: 1.2,
        ),
      ),
    );
  }
}

class _LoadingPhrase extends StatelessWidget {
  const _LoadingPhrase({
    required this.phrase,
    required this.animate,
  });

  final String phrase;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: animate ? const Duration(milliseconds: 420) : Duration.zero,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.18),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
      child: Text(
        phrase,
        key: ValueKey(phrase),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.82),
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _LoadingBar extends StatelessWidget {
  const _LoadingBar({
    required this.value,
    required this.shimmerProgress,
    required this.animate,
  });

  final double value;
  final double shimmerProgress;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: value.clamp(0, 1),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white,
                              AppTheme.accent,
                              AppTheme.primary.withValues(alpha: 0.92),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (animate)
                    FractionallySizedBox(
                      widthFactor: value.clamp(0, 1),
                      child: Align(
                        alignment: Alignment(-1 + shimmerProgress * 2.4, 0),
                        child: Container(
                          width: 54,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.52),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${(value.clamp(0, 1) * 100).round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashQuote extends StatelessWidget {
  const _SplashQuote({super.key, required this.quote, required this.author});

  final String quote;
  final String author;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 430),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            quote,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.90),
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            author,
            style: TextStyle(
              color: AppTheme.accent.withValues(alpha: 0.86),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RepairSplashPainter extends CustomPainter {
  const _RepairSplashPainter({
    required this.progress,
    required this.animate,
  });

  final double progress;
  final bool animate;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 34);
    final pulse = animate ? 0.5 + 0.5 * math.sin(progress * math.pi * 2) : 0.5;

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.11);
    for (var i = 0; i < 4; i++) {
      final phase = animate ? (progress + i * 0.16) % 1.0 : 0.35;
      final radius = size.shortestSide * (0.16 + i * 0.11 + phase * 0.035);
      ringPaint.color = Colors.white
          .withValues(alpha: (0.14 - i * 0.018) * (1 - phase * 0.3));
      canvas.drawCircle(center, radius, ringPaint);
    }

    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFFFB7D5).withValues(alpha: 0.08 + pulse * 0.08);
    canvas.drawCircle(
      center,
      size.shortestSide * (0.30 + pulse * 0.035),
      wavePaint,
    );
    canvas.drawCircle(
      center,
      size.shortestSide * (0.43 + pulse * 0.024),
      wavePaint..color = Colors.white.withValues(alpha: 0.07),
    );

    for (var i = 0; i < 18; i++) {
      final dotPulse = animate
          ? 0.5 + 0.5 * math.sin(progress * math.pi * 2 + i * 0.7)
          : 0.5;
      final angle = (i / 18) * math.pi * 2;
      final floatOffset =
          animate ? math.sin(progress * math.pi * 2 + i) * 3 : 0;
      final radius = size.shortestSide * (0.32 + (i % 3) * 0.055) + floatOffset;
      final dotPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.10 + dotPulse * 0.13);
      canvas.drawCircle(
        Offset(
          center.dx + math.cos(angle) * radius,
          center.dy + math.sin(angle) * radius,
        ),
        i.isEven ? 2.0 : 1.3,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RepairSplashPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.animate != animate;
  }
}
