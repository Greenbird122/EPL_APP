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
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

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
    if (mounted) context.go('/login');
  }

  List<Map<String, dynamic>> _onboardingData(AppLocalizations l10n) => [
        {
          'title': l10n.onboarding1Title,
          'description': l10n.onboarding1Description,
          'image': 'assets/illustrations/pregnant_mother.jpg',
          'fallbackIcon': Icons.visibility_outlined,
          'color': AppTheme.primary,
        },
        {
          'title': l10n.onboarding2Title,
          'description': l10n.onboarding2Description,
          'image': 'assets/illustrations/hospital.jpg',
          'fallbackIcon': Icons.location_on_outlined,
          'color': AppTheme.accent,
        },
        {
          'title': l10n.onboarding3Title,
          'description': l10n.onboarding3Description,
          'image': 'assets/illustrations/mental_health.jpg',
          'fallbackIcon': Icons.favorite_border,
          'color': const Color(0xFF22C55E),
        },
        {
          'title': l10n.onboarding4Title,
          'description': l10n.onboarding4Description,
          'image': 'assets/illustrations/mother_2.jpg',
          'fallbackIcon': Icons.groups_outlined,
          'color': const Color(0xFFFF9800),
        },
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
    final itemColor = current['color'] as Color;
    final imageAsset = current['image'] as String;
    final compact = RepairBreakpoints.isCompactPhone(context);
    final short = RepairBreakpoints.isShortScreen(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: HeroImageStack(
              key: ValueKey(imageAsset),
              imageAsset: imageAsset,
              accentColor: itemColor,
              showForegroundCard: false,
            ),
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
                              asset: data['image'] as String,
                              accent: data['color'] as Color,
                              fallbackIcon: data['fallbackIcon'] as IconData,
                            ),
                            SizedBox(height: short ? 18 : 28),
                            Text(
                              data['title'] as String,
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
                              data['description'] as String,
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
                      SmoothPageIndicator(
                        controller: _pageController,
                        count: onboardingData.length,
                        effect: WormEffect(
                          dotHeight: 8,
                          dotWidth: 8,
                          activeDotColor: itemColor,
                          dotColor: Colors.white.withValues(alpha: 0.25),
                        ),
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
}

class _SharpForegroundImage extends StatelessWidget {
  const _SharpForegroundImage({
    required this.asset,
    required this.accent,
    required this.fallbackIcon,
  });

  final String asset;
  final Color accent;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final widthCap = size.height < 700 ? size.width * 0.58 : size.width * 0.72;
    final side = widthCap.clamp(190.0, 420.0).toDouble();

    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => ColoredBox(
            color: accent.withValues(alpha: 0.3),
            child: Icon(fallbackIcon, size: 64, color: accent),
          ),
        ),
      ),
    );
  }
}
