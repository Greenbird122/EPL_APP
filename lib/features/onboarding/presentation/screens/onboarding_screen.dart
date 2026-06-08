import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/onboarding_provider.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/responsive.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/shared/widgets/hero_image_stack.dart';
import 'package:repair_ai/shared/widgets/language_toggle.dart';
import 'package:repair_ai/shared/widgets/theme_mode_toggle.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int currentPage = 0;

  Future<void> _completeOnboardingAndLogin() async {
    await ref.read(onboardingCompleteProvider.notifier).markComplete();
    if (mounted) context.go('/auth');
  }

  List<_OnboardingSlide> _onboardingData(AppLocalizations l10n) => [
        _OnboardingSlide(
          title: l10n.onboarding1Title,
          description: l10n.onboarding1Description,
          promise: l10n.onboardingPromiseAi,
          image: 'assets/illustrations/pregnant_mother.jpg',
          fallbackIcon: Icons.visibility_outlined,
          color: AppTheme.primary,
        ),
        _OnboardingSlide(
          title: l10n.onboarding2Title,
          description: l10n.onboarding2Description,
          promise: l10n.onboardingPromiseReferral,
          image: 'assets/illustrations/hospital.jpg',
          fallbackIcon: Icons.location_on_outlined,
          color: AppTheme.accent,
        ),
        _OnboardingSlide(
          title: l10n.onboarding3Title,
          description: l10n.onboarding3Description,
          promise: l10n.onboardingPromiseFollowUp,
          image: 'assets/illustrations/mental_health.jpg',
          fallbackIcon: Icons.favorite_border,
          color: const Color(0xFF22C55E),
        ),
        _OnboardingSlide(
          title: l10n.onboarding4Title,
          description: l10n.onboarding4Description,
          promise: l10n.onboardingPromiseKenya,
          image: 'assets/illustrations/mother_2.jpg',
          fallbackIcon: Icons.groups_outlined,
          color: const Color(0xFFFF9800),
        ),
      ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onboardingData = _onboardingData(l10n);
    final current = onboardingData[currentPage];
    final itemColor = current.color;
    final compact = RepairBreakpoints.isCompactPhone(context);
    final short = RepairBreakpoints.isShortScreen(context);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _pageController,
            builder: (context, _) {
              final progress = _pageProgress(onboardingData.length);
              final activeColor = _lerpSlideColor(onboardingData, progress);
              return _OnboardingBackground(
                slides: onboardingData,
                progress: progress,
                activeColor: activeColor,
                reduceMotion: reduceMotion,
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: LanguageToggle(),
                      ),
                      const SizedBox(width: 8),
                      const ThemeModeToggle(),
                      const Spacer(),
                      TextButton(
                        onPressed: _completeOnboardingAndLogin,
                        child: Text(
                          l10n.skip,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => currentPage = i),
                    itemCount: onboardingData.length,
                    itemBuilder: (context, index) {
                      final data = onboardingData[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 18 : 24,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SharpForegroundImage(
                              asset: data.image,
                              accent: data.color,
                              fallbackIcon: data.fallbackIcon,
                              pageOffset: _slideOffset(index),
                              reduceMotion: reduceMotion,
                            ),
                            SizedBox(height: short ? 18 : 28),
                            _PromiseChip(slide: data),
                            SizedBox(height: short ? 10 : 14),
                            Text(
                              data.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: compact ? 24 : 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.15,
                              ),
                            ),
                            SizedBox(height: short ? 8 : 12),
                            Text(
                              data.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: compact ? 14 : 16,
                                height: 1.42,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                            if (index == 0) ...[
                              const SizedBox(height: 12),
                              Text(
                                l10n.builtForKenyaTrust,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    compact ? 18 : 24,
                    8,
                    compact ? 18 : 24,
                    short ? 20 : 32,
                  ),
                  child: Column(
                    children: [
                      _OnboardingJourneyRail(
                        slides: onboardingData,
                        currentIndex: currentPage,
                        activeColor: itemColor,
                      ),
                      const SizedBox(height: 20),
                      if (currentPage == onboardingData.length - 1) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () => context.push('/how-it-works'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(l10n.seeHowItWorks),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            if (currentPage == onboardingData.length - 1) {
                              HapticFeedback.lightImpact();
                              _completeOnboardingAndLogin();
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 450),
                                curve: Curves.easeInOutCubic,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: itemColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            currentPage == onboardingData.length - 1
                                ? l10n.getStartedButton
                                : l10n.continueButton,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _pageProgress(int pageCount) {
    if (!_pageController.hasClients) return currentPage.toDouble();
    final page = _pageController.page ?? currentPage.toDouble();
    return page.clamp(0.0, (pageCount - 1).toDouble());
  }

  double _slideOffset(int index) {
    if (!_pageController.hasClients) return (index - currentPage).toDouble();
    final page = _pageController.page ?? currentPage.toDouble();
    return index - page;
  }

  Color _lerpSlideColor(List<_OnboardingSlide> slides, double progress) {
    final from = progress.floor().clamp(0, slides.length - 1);
    final to = (from + 1).clamp(0, slides.length - 1);
    final t = progress - from;
    return Color.lerp(slides[from].color, slides[to].color, t) ??
        slides[from].color;
  }
}

class _SharpForegroundImage extends StatelessWidget {
  const _SharpForegroundImage({
    required this.asset,
    required this.accent,
    required this.fallbackIcon,
    required this.pageOffset,
    required this.reduceMotion,
  });

  final String asset;
  final Color accent;
  final IconData fallbackIcon;
  final double pageOffset;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final widthCap = size.height < 700 ? size.width * 0.58 : size.width * 0.72;
    final side = widthCap.clamp(190.0, 420.0).toDouble();
    final motion = reduceMotion ? 0.0 : pageOffset.clamp(-1.0, 1.0);
    final opacity =
        reduceMotion ? 1.0 : (1 - motion.abs() * 0.34).clamp(0.0, 1.0);
    final scale = reduceMotion ? 1.0 : (1 - motion.abs() * 0.045);

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(motion * 26, motion.abs() * 10),
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: side,
            height: side,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.45),
                  blurRadius: 28,
                  spreadRadius: 1,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.26),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.48),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    asset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => ColoredBox(
                      color: accent.withValues(alpha: 0.3),
                      child: Icon(fallbackIcon, size: 64, color: accent),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.08),
                          accent.withValues(alpha: 0.2),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.promise,
    required this.image,
    required this.fallbackIcon,
    required this.color,
  });

  final String title;
  final String description;
  final String promise;
  final String image;
  final IconData fallbackIcon;
  final Color color;
}

class _OnboardingBackground extends StatelessWidget {
  const _OnboardingBackground({
    required this.slides,
    required this.progress,
    required this.activeColor,
    required this.reduceMotion,
  });

  final List<_OnboardingSlide> slides;
  final double progress;
  final Color activeColor;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final current = progress.floor().clamp(0, slides.length - 1);
    final next = (current + 1).clamp(0, slides.length - 1);
    final handoff = progress - current;

    return Stack(
      fit: StackFit.expand,
      children: [
        _BackgroundLayer(
          slide: slides[current],
          opacity: 1 - handoff,
          offset: reduceMotion ? 0 : -handoff,
        ),
        if (next != current)
          _BackgroundLayer(
            slide: slides[next],
            opacity: handoff,
            offset: reduceMotion ? 0 : 1 - handoff,
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.1, -0.24),
              radius: 1.08,
              colors: [
                activeColor.withValues(alpha: 0.1),
                activeColor.withValues(alpha: 0.5),
                const Color(0xFF1A0B33).withValues(alpha: 0.86),
              ],
              stops: const [0.0, 0.48, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer({
    required this.slide,
    required this.opacity,
    required this.offset,
  });

  final _OnboardingSlide slide;
  final double opacity;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(offset * 22, 0),
        child: Transform.scale(
          scale: 1.08,
          child: HeroImageStack(
            imageAsset: slide.image,
            accentColor: slide.color,
            showForegroundCard: false,
          ),
        ),
      ),
    );
  }
}

class _PromiseChip extends StatelessWidget {
  const _PromiseChip({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: (width * 0.86).clamp(180.0, 360.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(slide.fallbackIcon, size: 16, color: Colors.white),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      slide.promise,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingJourneyRail extends StatelessWidget {
  const _OnboardingJourneyRail({
    required this.slides,
    required this.currentIndex,
    required this.activeColor,
  });

  final List<_OnboardingSlide> slides;
  final int currentIndex;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < slides.length; i++) ...[
          _JourneyNode(
            slide: slides[i],
            active: i == currentIndex,
            complete: i < currentIndex,
            activeColor: activeColor,
          ),
          if (i != slides.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: (i < currentIndex ? activeColor : Colors.white)
                      .withValues(alpha: i < currentIndex ? 0.75 : 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _JourneyNode extends StatelessWidget {
  const _JourneyNode({
    required this.slide,
    required this.active,
    required this.complete,
    required this.activeColor,
  });

  final _OnboardingSlide slide;
  final bool active;
  final bool complete;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    final fill =
        active || complete ? activeColor : Colors.white.withValues(alpha: 0.16);
    final iconColor = active || complete
        ? Colors.white
        : Colors.white.withValues(alpha: 0.58);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      width: active ? 42 : 34,
      height: 34,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        boxShadow: active
            ? [
                BoxShadow(
                  color: activeColor.withValues(alpha: 0.34),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Icon(slide.fallbackIcon, size: 17, color: iconColor),
    );
  }
}
