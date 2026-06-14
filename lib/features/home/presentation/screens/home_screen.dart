import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/responsive.dart';
import 'package:repair_ai/features/auth/presentation/controllers/login_profile_providers.dart';
import 'package:repair_ai/features/auth/presentation/controllers/report_history_providers.dart';
import 'package:repair_ai/features/home/presentation/controllers/dashboard_stats_provider.dart';
import 'package:repair_ai/features/home/presentation/controllers/home_care_summary_provider.dart';
import 'package:repair_ai/features/home/presentation/widgets/home_connection_status_chip.dart';
import 'package:repair_ai/features/home/presentation/widgets/home_support_strip.dart';
import 'package:repair_ai/features/home/presentation/widgets/patient_health_summary.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/shared/widgets/bottom_nav.dart';
import 'package:repair_ai/shared/widgets/language_toggle.dart';
import 'package:repair_ai/shared/widgets/repair_app_bar.dart';
import 'package:repair_ai/shared/widgets/responsive_page.dart';
import 'package:repair_ai/shared/widgets/theme_mode_toggle.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  double _heroOpacity = 1.0;
  double _heroScale = 1.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    const fadeStart = 180.0;
    const fadeEnd = 340.0;
    final progress =
        ((offset - fadeStart) / (fadeEnd - fadeStart)).clamp(0.0, 1.0);
    setState(() {
      _heroOpacity = 1.0 - progress * 0.55;
      _heroScale = 1.0 + progress * 0.08;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reports = ref.watch(reportHistoryProvider);
    final lastReport = reports.isNotEmpty ? reports.last : null;
    final statsAsync = ref.watch(dashboardStatsProvider);
    final stats = statsAsync.maybeWhen(data: (s) => s, orElse: () => null);
    final summaryAsync = ref.watch(homeCareSummaryProvider);
    final summary = summaryAsync.valueOrNull;
    final profileName = ref.watch(profileNameProvider);
    final patientName = _firstName(
      summary?.name ?? profileName ?? l10n.careIdentityUnknown,
    );
    final compact = RepairBreakpoints.isCompactPhone(context);

    return Scaffold(
      appBar: RepairAppBar(
        title: l10n.appTitle,
        actions: const [
          ThemeModeToggle(),
          SizedBox(width: 6),
          Padding(padding: EdgeInsets.only(right: 8), child: LanguageToggle()),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(homeCareSummaryProvider);
              ref.invalidate(dashboardStatsProvider);
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding:
                  EdgeInsets.only(bottom: RepairInsets.scrollBottom(context)),
              child: ResponsivePageShell(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Hero banner ──
                    _ParallaxHero(
                      opacity: _heroOpacity,
                      scale: _heroScale,
                      compact: compact,
                      child: _HeroContent(
                        topChild: const HomeConnectionStatusChip(),
                        title: l10n.yourPregnancyMatters,
                        subtitle:
                            '${l10n.reportSymptomsEarly} ${l10n.homeSupportChannelsSuffix}',
                        compact: compact,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Greeting + identity chips ──
                    _AnimatedSection(
                      index: 0,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: compact ? 14 : 20),
                        child: _PersonalizedHeader(
                          greeting: l10n.homeGreeting(patientName),
                          summary: summary,
                          loading: summaryAsync.isLoading,
                          hasLocalReport: lastReport != null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Health stats ──
                    const _AnimatedSection(
                      index: 1,
                      child: PatientHealthSummary(),
                    ),
                    const SizedBox(height: 14),

                    // ── Dashboard stats from backend ──
                    if (stats != null)
                      _AnimatedSection(
                        index: 2,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: compact ? 14 : 20),
                          child: _DashboardStatsRow(stats: stats),
                        ),
                      ),
                    if (stats != null) const SizedBox(height: 14),

                    // ── Quick actions row ──
                    _AnimatedSection(
                      index: 3,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: compact ? 14 : 20),
                        child: _QuickActionsRow(
                          compact: compact,
                          stats: stats,
                          onTriage: () => context.push('/symptom-check'),
                          onReferral: () => context.push('/referral'),
                          onCare: () => context.push('/history'),
                          onMentalHealth: () => context.push('/mental-health'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Report symptoms CTA ──
                    _AnimatedSection(
                      index: 4,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: compact ? 14 : 20),
                        child: _ReportSymptomsCta(
                          title: l10n.reportSymptoms,
                          subtitle: l10n.reportSymptomsSubtitle,
                          imageAsset:
                              'assets/illustrations/pregnant_mother.jpg',
                          onTap: () => context.push('/symptom-check'),
                        ),
                      ),
                    ),

                    // ── Support strip ──
                    _AnimatedSection(
                      index: 5,
                      child: Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: compact ? 14 : 20),
                        child: const HomeSupportStrip(),
                      ),
                    ),

                    // ── Patient ID card ──
                    if (stats != null)
                      _AnimatedSection(
                        index: 6,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: compact ? 14 : 20),
                          child: _PatientIdCard(
                            stats: stats,
                            compact: compact,
                          ),
                        ),
                      ),
                    if (stats != null) const SizedBox(height: 14),

                    // ── Profile info bar ──
                    if (stats != null &&
                        (stats.communityName != null ||
                            stats.chpName != null ||
                            stats.profilePercent < 100))
                      _AnimatedSection(
                        index: 7,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: compact ? 14 : 20),
                          child: _ProfileInfoBar(
                            stats: stats,
                            compact: compact,
                          ),
                        ),
                      ),
                    if (stats != null) const SizedBox(height: 14),

                    // ── Visit trend chart ──
                    if (stats != null && stats.visitTrend.isNotEmpty)
                      _AnimatedSection(
                        index: 8,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: compact ? 14 : 20),
                          child: _VisitTrendSection(
                            trend: stats.visitTrend,
                            compact: compact,
                          ),
                        ),
                      ),
                    if (stats != null && stats.visitTrend.isNotEmpty)
                      const SizedBox(height: 14),

                    // ── Recent referrals + upcoming follow-ups ──
                    if (stats != null &&
                        (stats.recentReferrals.isNotEmpty ||
                            stats.upcomingFollowups.isNotEmpty))
                      _AnimatedSection(
                        index: 9,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: compact ? 14 : 20),
                          child: _ReferralAndFollowUpSection(
                            referrals: stats.recentReferrals,
                            followups: stats.upcomingFollowups,
                            compact: compact,
                          ),
                        ),
                      ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
          // ── FAB for quick triage ──
          Positioned(
            bottom: compact ? 80 : 24,
            right: compact ? 16 : 24,
            child: _QuickTriageFab(
              onTap: () => context.push('/symptom-check'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  String _firstName(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'Mama';
    return clean.split(RegExp(r'\s+')).first;
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Parallax hero with scroll-driven opacity/scale
// ══════════════════════════════════════════════════════════════════════════════
class _ParallaxHero extends StatelessWidget {
  const _ParallaxHero({
    required this.opacity,
    required this.scale,
    required this.compact,
    required this.child,
  });

  final double opacity;
  final double scale;
  final bool compact;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
          height: compact ? 200 : 280,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/illustrations/mother_2.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  AppTheme.primaryDeep.withValues(alpha: 0.55),
                  AppTheme.primary.withValues(alpha: 0.45),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({
    required this.topChild,
    required this.title,
    required this.subtitle,
    required this.compact,
  });

  final Widget? topChild;
  final String title;
  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 20,
        compact ? 8 : 12,
        compact ? 14 : 20,
        compact ? 14 : 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (topChild != null) topChild!,
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              fontSize: compact ? 24 : 30,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: compact ? 14 : 16,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Animated entrance wrapper
// ══════════════════════════════════════════════════════════════════════════════
class _AnimatedSection extends StatefulWidget {
  const _AnimatedSection({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_AnimatedSection> createState() => _AnimatedSectionState();
}

class _AnimatedSectionState extends State<_AnimatedSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 120 + widget.index * 80), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Quick actions row — 4 tappable chips with icons
// ══════════════════════════════════════════════════════════════════════════════
class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({
    required this.compact,
    required this.onTriage,
    required this.onReferral,
    required this.onCare,
    required this.onMentalHealth,
    this.stats,
  });

  final bool compact;
  final VoidCallback onTriage;
  final VoidCallback onReferral;
  final VoidCallback onCare;
  final VoidCallback onMentalHealth;
  // Stats passed for potential context (e.g. badge counts on quick action tiles)
  final DashboardStats? stats;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: compact ? 15 : 17,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _QuickActionTile(
                icon: Icons.auto_awesome_rounded,
                label: 'Check\nSymptoms',
                gradient: const [AppTheme.primary, AppTheme.primaryLight],
                onTap: onTriage,
                compact: compact,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.local_hospital_rounded,
                label: 'Find\nFacility',
                gradient: const [AppTheme.accent, AppTheme.primary],
                onTap: onReferral,
                compact: compact,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.assignment_rounded,
                label: 'My\nReports',
                gradient: const [AppTheme.primaryDeep, AppTheme.primary],
                onTap: onCare,
                compact: compact,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionTile(
                icon: Icons.psychology_rounded,
                label: 'Mental\nHealth',
                gradient: const [AppTheme.warning, AppTheme.accent],
                onTap: onMentalHealth,
                compact: compact,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatefulWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;
  final bool compact;

  @override
  State<_QuickActionTile> createState() => _QuickActionTileState();
}

class _QuickActionTileState extends State<_QuickActionTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.96 : 1.0;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: widget.compact ? 14 : 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.first.withValues(alpha: 0.3),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon,
                  color: Colors.white, size: widget.compact ? 26 : 30),
              const SizedBox(height: 6),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: widget.compact ? 11 : 12,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Report symptoms CTA — larger image, taller button
// ══════════════════════════════════════════════════════════════════════════════
class _ReportSymptomsCta extends StatefulWidget {
  const _ReportSymptomsCta({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String imageAsset;
  final VoidCallback onTap;

  @override
  State<_ReportSymptomsCta> createState() => _ReportSymptomsCtaState();
}

class _ReportSymptomsCtaState extends State<_ReportSymptomsCta> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final compact = RepairBreakpoints.isCompactPhone(context);
    final scale = _pressed ? 0.985 : 1.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 150),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: compact ? 140 : 170,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/illustrations/pregnant_mother.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppTheme.primaryDeep.withValues(alpha: 0.85),
                      AppTheme.primary.withValues(alpha: 0.55),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(compact ? 18 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.auto_awesome,
                                color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.title,
                                  style: TextStyle(
                                    fontSize: compact ? 19 : 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.subtitle,
                                  style: TextStyle(
                                    fontSize: compact ? 13 : 14,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 28),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Glass nav cards (Care, Mental Health)
// ══════════════════════════════════════════════════════════════════════════════
class _GlassNavCard extends StatefulWidget {
  const _GlassNavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  @override
  State<_GlassNavCard> createState() => _GlassNavCardState();
}

class _GlassNavCardState extends State<_GlassNavCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.975 : 1.0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                widget.gradientColors.first.withValues(alpha: 0.08),
                widget.gradientColors.last.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: widget.gradientColors.first.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: widget.gradientColors),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradientColors.first.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: widget.gradientColors.first.withValues(alpha: 0.5),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Quick triage FAB
// ══════════════════════════════════════════════════════════════════════════════
class _QuickTriageFab extends StatefulWidget {
  const _QuickTriageFab({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_QuickTriageFab> createState() => _QuickTriageFabState();
}

class _QuickTriageFabState extends State<_QuickTriageFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + _pulseController.value * 0.06,
          child: FloatingActionButton.extended(
            onPressed: widget.onTap,
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.auto_awesome),
            label: const Text(
              'Check Symptoms',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Existing widgets (kept from original)
// ══════════════════════════════════════════════════════════════════════════════

class _PersonalizedHeader extends StatelessWidget {
  const _PersonalizedHeader({
    required this.greeting,
    required this.summary,
    required this.loading,
    required this.hasLocalReport,
  });

  final String greeting;
  final HomeCareSummary? summary;
  final bool loading;
  final bool hasLocalReport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final county = summary?.county ?? (loading ? '...' : l10n.locationNotSet);
    final weeks = summary?.pregnancyWeeks;
    final checked = hasLocalReport || summary?.hasRisk == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: scheme.onSurface,
              ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.location_on_outlined,
                size: 16, color: AppTheme.primary),
            const SizedBox(width: 6),
            Text(county,
                style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant)),
            const SizedBox(width: 16),
            const Icon(Icons.pregnant_woman, size: 16, color: AppTheme.accent),
            const SizedBox(width: 6),
            Text(
              weeks != null ? '${weeks.toStringAsFixed(0)} weeks' : 'Pregnancy',
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: 16),
            Icon(
              checked ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16,
              color: checked ? AppTheme.success : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              checked ? 'Checked today' : 'Not checked',
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashboardStatsRow extends StatelessWidget {
  const _DashboardStatsRow({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final riskColor = switch ((stats.latestRiskLevel ?? '').toLowerCase()) {
      'high' => AppTheme.error,
      'moderate' => AppTheme.warning,
      _ => AppTheme.success,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniStatCard(
                icon: Icons.medical_services_outlined,
                value: '${stats.totalVisits}',
                label: 'EPL Cases',
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniStatCard(
                icon: Icons.local_hospital_outlined,
                value: '${stats.totalReferrals}',
                label: 'Referrals',
                color: AppTheme.warning,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MiniStatCard(
                icon: Icons.notifications_outlined,
                value: '${stats.activeAlerts}',
                label: 'Alerts',
                color:
                    stats.activeAlerts > 0 ? AppTheme.error : AppTheme.success,
              ),
            ),
          ],
        ),
        if (stats.latestRiskLevel != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: riskColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, color: riskColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Last risk: ${stats.latestRiskLevel!.toUpperCase()}',
                  style: TextStyle(
                      color: riskColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
                const Spacer(),
                if (stats.chpName != null)
                  Text(
                    'CHP: ${stats.chpName}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
        ],
        if (stats.profilePercent < 100) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: stats.profilePercent / 100,
                    backgroundColor: Colors.grey.shade200,
                    color: AppTheme.primary,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Profile ${stats.profilePercent}%',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 18, color: color)),
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Patient ID card — mirrors web PatientDashboardHome.tsx Patient ID card
// ══════════════════════════════════════════════════════════════════════════════
class _PatientIdCard extends StatelessWidget {
  const _PatientIdCard({required this.stats, required this.compact});

  final DashboardStats stats;
  final bool compact;

  bool get _hasPid => stats.patientIdentifier?['is_active'] == true;
  bool get _isPending =>
      stats.patientIdentifier?['has_pid'] == true &&
      stats.patientIdentifier?['is_active'] != true;

  void _openModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _PatientIdDialog(
        hasPid: _hasPid,
        isPending: _isPending,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 18,
        vertical: compact ? 12 : 14,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryDeep, AppTheme.primary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.badge_outlined,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'REPAIR-AI Patient ID',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _hasPid
                      ? 'Your ID is active'
                      : _isPending
                          ? 'Awaiting CHP approval'
                          : '4-digit digital identity badge',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _openModal(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _hasPid
                    ? 'View ID'
                    : _isPending
                        ? 'Pending'
                        : 'Get ID',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for viewing / requesting a Patient ID (mirrors web Patient ID modal).
class _PatientIdDialog extends StatelessWidget {
  const _PatientIdDialog({
    required this.hasPid,
    required this.isPending,
  });

  final bool hasPid;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasPid) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryDeep, AppTheme.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.badge, color: Colors.white, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'Patient ID',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          letterSpacing: 1.5),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '****',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 10,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Colors.greenAccent, size: 8),
                        SizedBox(width: 4),
                        Text('Active',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Your digital Patient ID is active.\nPresent it at any REPAIR-AI facility.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ] else if (isPending) ...[
              const Icon(Icons.hourglass_top_rounded,
                  color: AppTheme.warning, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Awaiting CHP Approval',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your Patient ID request is under review.\nYour CHP will be notified to approve it.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ] else ...[
              const Icon(Icons.badge_outlined,
                  color: AppTheme.primary, size: 48),
              const SizedBox(height: 12),
              const Text(
                'REPAIR-AI Patient ID',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'A 4-digit digital identity badge enables:\n'
                '• Integration between healthcare systems\n'
                '• Access to maternal health services\n'
                '• Fund top-ups for health savings\n'
                '• Track your health progress across facilities',
                style:
                    TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Request Patient ID',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Profile info bar — shows CHP name, community, profile completion progress
// ══════════════════════════════════════════════════════════════════════════════
class _ProfileInfoBar extends StatelessWidget {
  const _ProfileInfoBar({required this.stats, required this.compact});

  final DashboardStats stats;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (stats.communityName != null) ...[
                const Icon(Icons.people_outline,
                    size: 16, color: AppTheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    stats.communityName!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                const Spacer(),
              if (stats.chpName != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.person_outline,
                    size: 16, color: AppTheme.accent),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'CHP: ${stats.chpName}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          if (stats.profilePercent > 0 && stats.profilePercent < 100) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: stats.profilePercent / 100,
                      backgroundColor:
                          AppTheme.primary.withValues(alpha: 0.12),
                      color: AppTheme.primary,
                      minHeight: 7,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Profile ${stats.profilePercent}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Visit trend chart — mirrors web PatientDashboardHome Visit History chart
// ══════════════════════════════════════════════════════════════════════════════
class _VisitTrendSection extends StatelessWidget {
  const _VisitTrendSection({required this.trend, required this.compact});

  final List<Map<String, dynamic>> trend;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxVisits = trend
        .map((e) => (e['visits'] as num?)?.toInt() ?? 0)
        .fold<int>(1, (a, b) => a > b ? a : b);

    return Container(
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visit History',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: compact ? 14 : 15,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...trend.take(5).map((entry) {
            final date = entry['date']?.toString() ?? '';
            final visits = (entry['visits'] as num?)?.toInt() ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      date,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: maxVisits > 0 ? visits / maxVisits : 0,
                        backgroundColor:
                            AppTheme.primary.withValues(alpha: 0.1),
                        color: AppTheme.primary,
                        minHeight: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$visits',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Referrals + Follow-ups lists — mirrors web dashboard lists
// ══════════════════════════════════════════════════════════════════════════════
class _ReferralAndFollowUpSection extends StatelessWidget {
  const _ReferralAndFollowUpSection({
    required this.referrals,
    required this.followups,
    required this.compact,
  });

  final List<Map<String, dynamic>> referrals;
  final List<Map<String, dynamic>> followups;
  final bool compact;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppTheme.success;
      case 'pending':
        return AppTheme.warning;
      case 'cancelled':
        return AppTheme.error;
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (referrals.isNotEmpty)
          Expanded(
            child: _ListCard(
              title: 'Recent Referrals',
              icon: Icons.swap_horiz_rounded,
              children: referrals.take(3).map((r) {
                final status = (r['status'] as String?) ?? '';
                final created = r['created_at'] as String?;
                final id = r['id'];
                return _ListRow(
                  primary: 'Referral #$id',
                  secondary: created != null
                      ? DateTime.tryParse(created)
                              ?.toLocal()
                              .toString()
                              .split(' ')
                              .first ??
                          created
                      : '',
                  badgeLabel: status.replaceAll('_', ' ').toUpperCase(),
                  badgeColor: _statusColor(status),
                  compact: compact,
                );
              }).toList(),
            ),
          ),
        if (referrals.isNotEmpty && followups.isNotEmpty)
          const SizedBox(width: 10),
        if (followups.isNotEmpty)
          Expanded(
            child: _ListCard(
              title: 'Upcoming Follow-ups',
              icon: Icons.event_outlined,
              children: followups.take(3).map((f) {
                final channel = (f['channel'] as String?) ?? '';
                final dueDate = f['due_date'] as String?;
                final id = f['id'];
                return _ListRow(
                  primary: 'Follow-up #$id',
                  secondary: dueDate != null
                      ? 'Due: ${DateTime.tryParse(dueDate)?.toLocal().toString().split(' ').first ?? dueDate}'
                      : '',
                  badgeLabel: channel.toUpperCase(),
                  badgeColor: AppTheme.primary,
                  compact: compact,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.primary,
    required this.secondary,
    required this.badgeLabel,
    required this.badgeColor,
    required this.compact,
  });

  final String primary;
  final String secondary;
  final String badgeLabel;
  final Color badgeColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primary,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                if (secondary.isNotEmpty)
                  Text(
                    secondary,
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
