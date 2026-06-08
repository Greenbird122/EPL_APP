import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
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
  late final AnimationController _entryController;
  late final AnimationController _logoController;

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
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _start();
  }

  Future<void> _start() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;

    final quotes = MotherlyQuoteCard.quotesFor(AppLocalizations.of(context));

    _rotateTimer = Timer.periodic(const Duration(milliseconds: 2400), (_) {
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
    _entryController.dispose();
    _logoController.dispose();
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

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _ambientController,
          _progressController,
          _entryController,
          _logoController,
        ]),
        builder: (context, _) {
          final t = disableAnimations ? 0.0 : _ambientController.value;
          final logoT = disableAnimations ? 0.875 : _logoController.value;
          final phase = _SplashPhase.from(logoT);
          final palette = phase.activePalette;
          final entrance = disableAnimations
              ? 1.0
              : Curves.easeOutCubic.transform(_entryController.value);
          final pulse = 0.5 + 0.5 * math.sin(t * math.pi * 2);

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.12, -0.22),
                radius: 1.12,
                colors: [
                  palette.center,
                  palette.mid,
                  palette.deep,
                  palette.base,
                ],
                stops: const [0, 0.34, 0.72, 1],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RepairSplashPainter(
                      progress: t,
                      animate: !disableAnimations,
                      palette: palette,
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
                          palette.accent.withValues(alpha: 0.10),
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final availableHeight = constraints.maxHeight;
                      final availableWidth = constraints.maxWidth;
                      final tightHeight = availableHeight < 610;
                      final horizontalPadding = compact ? 22.0 : 32.0;
                      final verticalPadding =
                          tightHeight ? 10.0 : (short ? 16.0 : 28.0);
                      final contentWidth =
                          availableWidth - horizontalPadding * 2;
                      final logoBase =
                          math.min(contentWidth, availableHeight) * 0.40;
                      final maxLogo =
                          tightHeight ? 154.0 : (compact ? 190.0 : 260.0);
                      final minLogo =
                          tightHeight ? 124.0 : (compact ? 148.0 : 180.0);
                      final logoSize =
                          logoBase.clamp(minLogo, maxLogo).toDouble();
                      final gap = tightHeight ? 8.0 : (short ? 12.0 : 26.0);
                      final body = Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: verticalPadding,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FadeTransition(
                              opacity: AlwaysStoppedAnimation(entrance),
                              child: Transform.scale(
                                scale: 0.88 + entrance * 0.12,
                                child: _GlowLogo(
                                  pulseProgress: t,
                                  phase: phase,
                                  size: logoSize,
                                  animate: !disableAnimations,
                                ),
                              ),
                            ),
                            SizedBox(height: gap),
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
                                    color: palette.accent.withValues(
                                      alpha: 0.48,
                                    ),
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: tightHeight ? 4 : 8),
                            Text(
                              'Pregnancy care, close by',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(height: tightHeight ? 8 : 12),
                            _LoadingPhrase(
                              phrase: phrase,
                              animate: !disableAnimations,
                              palette: palette,
                            ),
                            SizedBox(
                                height: tightHeight ? 10 : (short ? 16 : 28)),
                            _LoadingBar(
                              value: _progressController.value,
                              shimmerProgress: t,
                              animate: !disableAnimations,
                              palette: palette,
                            ),
                            SizedBox(
                                height: tightHeight ? 10 : (short ? 16 : 26)),
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
                                palette: palette,
                                compact: tightHeight,
                              ),
                            ),
                          ],
                        ),
                      );

                      if (tightHeight) {
                        return SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: availableHeight,
                            ),
                            child: Center(child: body),
                          ),
                        );
                      }

                      return Center(child: body);
                    },
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

class _SplashPalette {
  const _SplashPalette({
    required this.center,
    required this.mid,
    required this.deep,
    required this.base,
    required this.accent,
    required this.glass,
  });

  final Color center;
  final Color mid;
  final Color deep;
  final Color base;
  final Color accent;
  final Color glass;

  static const _palettes = [
    _SplashPalette(
      center: Color(0xFF8FEAFF),
      mid: Color(0xFF5FA8FF),
      deep: Color(0xFF3350C7),
      base: Color(0xFF101A44),
      accent: Color(0xFFA7FFF4),
      glass: Color(0xFFE8FBFF),
    ),
    _SplashPalette(
      center: Color(0xFFB9A7FF),
      mid: Color(0xFF765BFF),
      deep: Color(0xFF3D1FA6),
      base: Color(0xFF160D38),
      accent: Color(0xFFFFC3F0),
      glass: Color(0xFFF2E9FF),
    ),
    _SplashPalette(
      center: Color(0xFFE870FF),
      mid: Color(0xFF7D44F2),
      deep: Color(0xFF42135F),
      base: Color(0xFF18051F),
      accent: Color(0xFFFF9BCB),
      glass: Color(0xFFFFE8F4),
    ),
    _SplashPalette(
      center: Color(0xFFFF3F94),
      mid: Color(0xFF6B2DFF),
      deep: Color(0xFF3A0B69),
      base: Color(0xFF160318),
      accent: Color(0xFFFFB1D2),
      glass: Color(0xFFFFE5F0),
    ),
  ];

  static _SplashPalette lerp(
    _SplashPalette a,
    _SplashPalette b,
    double t,
  ) {
    return _SplashPalette(
      center: Color.lerp(a.center, b.center, t)!,
      mid: Color.lerp(a.mid, b.mid, t)!,
      deep: Color.lerp(a.deep, b.deep, t)!,
      base: Color.lerp(a.base, b.base, t)!,
      accent: Color.lerp(a.accent, b.accent, t)!,
      glass: Color.lerp(a.glass, b.glass, t)!,
    );
  }
}

class _SplashPhase {
  const _SplashPhase({
    required this.currentIndex,
    required this.nextIndex,
    required this.localProgress,
    required this.handoff,
    required this.handoffEase,
    required this.currentPalette,
    required this.nextPalette,
    required this.activePalette,
  });

  final int currentIndex;
  final int nextIndex;
  final double localProgress;
  final double handoff;
  final double handoffEase;
  final _SplashPalette currentPalette;
  final _SplashPalette nextPalette;
  final _SplashPalette activePalette;

  static _SplashPhase from(double progress) {
    final count = _SplashPalette._palettes.length;
    final scaled = progress.clamp(0.0, 1.0).toDouble() * count;
    final currentIndex = scaled.floor() % count;
    final nextIndex = (currentIndex + 1) % count;
    final localProgress = scaled - scaled.floor();
    final handoff = ((localProgress - 0.58) / 0.42).clamp(0.0, 1.0).toDouble();
    final handoffEase = Curves.easeInOutCubic.transform(handoff);
    final currentPalette = _SplashPalette._palettes[currentIndex];
    final nextPalette = _SplashPalette._palettes[nextIndex];
    return _SplashPhase(
      currentIndex: currentIndex,
      nextIndex: nextIndex,
      localProgress: localProgress,
      handoff: handoff,
      handoffEase: handoffEase,
      currentPalette: currentPalette,
      nextPalette: nextPalette,
      activePalette: _SplashPalette.lerp(
        currentPalette,
        nextPalette,
        handoffEase,
      ),
    );
  }
}

class _GlowLogo extends StatelessWidget {
  const _GlowLogo({
    required this.pulseProgress,
    required this.phase,
    required this.size,
    required this.animate,
  });

  final double pulseProgress;
  final _SplashPhase phase;
  final double size;
  final bool animate;

  static const _logoAssets = [
    'assets/icons/repair_ai_splash_logo_0.png',
    'assets/icons/repair_ai_splash_logo_1.png',
    'assets/icons/repair_ai_splash_logo_2.png',
    'assets/icons/repair_ai_splash_logo_3.png',
  ];

  @override
  Widget build(BuildContext context) {
    final pulse =
        animate ? 0.5 + 0.5 * math.sin(pulseProgress * math.pi * 2) : 0.5;
    final warmPulse =
        animate ? 0.5 + 0.5 * math.sin(pulseProgress * math.pi * 2 + 1.4) : 0.5;
    final palette = phase.activePalette;

    return SizedBox(
      width: size * 1.78,
      height: size * 1.78,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 3; i++)
            _ExpandingCareWave(
              progress: pulseProgress,
              size: size,
              index: i,
              animate: animate,
              palette: palette,
            ),
          Transform.scale(
            scale: 1 + pulse * 0.10,
            child: Container(
              width: size * 1.60,
              height: size * 1.60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: palette.glass.withValues(alpha: 0.25),
                  width: 1.4,
                ),
              ),
            ),
          ),
          Transform.scale(
            scale: 1 + pulse * 0.06,
            child: Container(
              width: size * 1.42,
              height: size * 1.42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color.lerp(
                    palette.accent,
                    palette.glass,
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
                boxShadow: [
                  BoxShadow(
                    color: Color.lerp(
                      palette.accent,
                      palette.center,
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
              child: animate
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        _SlidingSplashLogo(
                          asset: _logoAssets[phase.currentIndex],
                          opacity: 1 - phase.handoffEase,
                          offset: Offset(
                            -12 * phase.handoffEase,
                            -10 * phase.handoffEase,
                          ),
                          scale: 1.02 - 0.03 * phase.handoffEase,
                        ),
                        _SlidingSplashLogo(
                          asset: _logoAssets[phase.nextIndex],
                          opacity: phase.handoffEase,
                          offset: Offset(
                            24 * (1 - phase.handoffEase),
                            24 * (1 - phase.handoffEase),
                          ),
                          scale: 0.96 + 0.06 * phase.handoffEase,
                        ),
                      ],
                    )
                  : Image.asset(_logoAssets.last, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlidingSplashLogo extends StatelessWidget {
  const _SlidingSplashLogo({
    required this.asset,
    required this.opacity,
    required this.offset,
    required this.scale,
  });

  final String asset;
  final double opacity;
  final Offset offset;
  final double scale;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0.01) return const SizedBox.shrink();

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: offset,
        child: Transform.scale(
          scale: scale,
          child: Image.asset(asset, fit: BoxFit.contain),
        ),
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
    required this.palette,
  });

  final double progress;
  final double size;
  final int index;
  final bool animate;
  final _SplashPalette palette;

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
          color: palette.glass.withValues(alpha: 0.24 * opacity),
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
    required this.palette,
  });

  final String phrase;
  final bool animate;
  final _SplashPalette palette;

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
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: child,
          ),
        );
      },
      child: _GlassSurface(
        key: ValueKey(phrase),
        palette: palette,
        borderRadius: 999,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Text(
          phrase,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
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
    required this.palette,
  });

  final double value;
  final double shimmerProgress;
  final bool animate;
  final _SplashPalette palette;

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
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
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
                              palette.accent,
                              palette.center.withValues(alpha: 0.92),
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
  const _SplashQuote({
    super.key,
    required this.quote,
    required this.author,
    required this.palette,
    required this.compact,
  });

  final String quote;
  final String author;
  final _SplashPalette palette;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _GlassSurface(
      constraints: const BoxConstraints(maxWidth: 430),
      palette: palette,
      borderRadius: 20,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 18,
        vertical: compact ? 11 : 16,
      ),
      child: Column(
        children: [
          Text(
            quote,
            textAlign: TextAlign.center,
            maxLines: compact ? 2 : 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.90),
              height: compact ? 1.28 : 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: compact ? 5 : 8),
          Text(
            author,
            style: TextStyle(
              color: palette.accent.withValues(alpha: 0.90),
              fontWeight: FontWeight.w800,
              fontSize: compact ? 11 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassSurface extends StatelessWidget {
  const _GlassSurface({
    super.key,
    required this.child,
    required this.palette,
    required this.borderRadius,
    required this.padding,
    this.constraints,
  });

  final Widget child;
  final _SplashPalette palette;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final BoxConstraints? constraints;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          constraints: constraints,
          padding: padding,
          decoration: BoxDecoration(
            color: Color.lerp(
              Colors.white,
              palette.glass,
              0.34,
            )!
                .withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: palette.glass.withValues(alpha: 0.24),
            ),
            boxShadow: [
              BoxShadow(
                color: palette.accent.withValues(alpha: 0.10),
                blurRadius: 28,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _RepairSplashPainter extends CustomPainter {
  const _RepairSplashPainter({
    required this.progress,
    required this.animate,
    required this.palette,
  });

  final double progress;
  final bool animate;
  final _SplashPalette palette;

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
      ringPaint.color = palette.glass.withValues(
        alpha: (0.14 - i * 0.018) * (1 - phase * 0.3),
      );
      canvas.drawCircle(center, radius, ringPaint);
    }

    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = palette.accent.withValues(alpha: 0.08 + pulse * 0.08);
    canvas.drawCircle(
      center,
      size.shortestSide * (0.30 + pulse * 0.035),
      wavePaint,
    );
    canvas.drawCircle(
      center,
      size.shortestSide * (0.43 + pulse * 0.024),
      wavePaint..color = palette.glass.withValues(alpha: 0.07),
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
        ..color = palette.glass.withValues(alpha: 0.10 + dotPulse * 0.13);
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
    return oldDelegate.progress != progress ||
        oldDelegate.animate != animate ||
        oldDelegate.palette != palette;
  }
}
