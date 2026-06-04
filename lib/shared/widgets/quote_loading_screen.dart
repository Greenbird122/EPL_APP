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
  Timer? _rotateTimer;
  bool _taskDone = false;
  bool _minElapsed = false;
  late final AnimationController _ambientController;
  late final AnimationController _progressController;

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
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 420;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_ambientController, _progressController]),
        builder: (context, _) {
          final t = _ambientController.value;
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
                    painter: _RepairSplashPainter(progress: t),
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
                        vertical: 28,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _GlowLogo(
                            progress: t,
                            size: compact ? 118 : 148,
                          ),
                          const SizedBox(height: 26),
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
                          const SizedBox(height: 28),
                          _LoadingBar(value: _progressController.value),
                          const SizedBox(height: 26),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 420),
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
  const _GlowLogo({required this.progress, required this.size});

  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final pulse = 0.5 + 0.5 * math.sin(progress * math.pi * 2);

    return SizedBox(
      width: size * 1.9,
      height: size * 1.9,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: 1 + pulse * 0.08,
            child: Container(
              width: size * 1.72,
              height: size * 1.72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22),
                  width: 1.4,
                ),
              ),
            ),
          ),
          Transform.rotate(
            angle: progress * math.pi * 2,
            child: Container(
              width: size * 1.55,
              height: size * 1.55,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border(
                  top: BorderSide(
                    color: AppTheme.accent.withValues(alpha: 0.86),
                    width: 2.5,
                  ),
                  right: BorderSide(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: 1,
                  ),
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.04),
                    width: 1,
                  ),
                  left: BorderSide(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.32 + pulse * 0.12),
                  blurRadius: 34,
                  spreadRadius: 5,
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.12),
                  blurRadius: 18,
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
        ],
      ),
    );
  }
}

class _LoadingBar extends StatelessWidget {
  const _LoadingBar({required this.value});

  final double value;

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
              child: Align(
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
  const _RepairSplashPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 34);
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.08),
          AppTheme.accent.withValues(alpha: 0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.44, 0.50, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(progress * math.pi * 2);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawRect(
      Rect.fromCenter(
        center: center,
        width: size.shortestSide * 1.65,
        height: 64,
      ),
      scanPaint,
    );
    canvas.restore();

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.08);
    for (var i = 0; i < 4; i++) {
      final radius = size.shortestSide * (0.18 + i * 0.12);
      canvas.drawCircle(center, radius, ringPaint);
    }

    final dotPaint = Paint()..color = Colors.white.withValues(alpha: 0.18);
    for (var i = 0; i < 16; i++) {
      final angle = (i / 16) * math.pi * 2 + progress * math.pi * 0.45;
      final radius = size.shortestSide * 0.38;
      canvas.drawCircle(
        Offset(center.dx + math.cos(angle) * radius,
            center.dy + math.sin(angle) * radius),
        i.isEven ? 2.2 : 1.4,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RepairSplashPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
