import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/features/home/presentation/controllers/home_care_summary_provider.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/shared/widgets/image_accent_card.dart';

class CareCompassCard extends StatefulWidget {
  const CareCompassCard({
    super.key,
    required this.summary,
    required this.hasLocalReport,
    required this.localRiskLabel,
    required this.onPrimaryAction,
    required this.onSecondaryAction,
  });

  final HomeCareSummary? summary;
  final bool hasLocalReport;
  final String? localRiskLabel;
  final VoidCallback onPrimaryAction;
  final VoidCallback onSecondaryAction;

  @override
  State<CareCompassCard> createState() => _CareCompassCardState();
}

class _CareCompassCardState extends State<CareCompassCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final state = _state;
    final color = _colorForState(state);
    final icon = _iconForState(state);
    final title = _title(l10n, state);
    final message = _message(l10n, state);
    final action = _primaryLabel(l10n, state);

    if (reduceMotion && _pulseController.isAnimating) {
      _pulseController.stop();
    } else if (!reduceMotion && !_pulseController.isAnimating) {
      _pulseController.repeat();
    }

    return ImageAccentCard(
      imageAsset: state == CareCompassState.referralNeeded
          ? 'assets/illustrations/hospital.webp'
          : 'assets/illustrations/mama.jpeg',
      accentColor: color,
      imageFit: ImageAccentFit.visibleTop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CarePulse(
                controller: _pulseController,
                color: color,
                icon: icon,
                active: !reduceMotion,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.careCompassTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CompassChip(
                icon: Icons.location_on_outlined,
                label: widget.summary?.county ?? l10n.locationNotSet,
                color: AppTheme.primary,
              ),
              _CompassChip(
                icon: Icons.pregnant_woman,
                label: _pregnancyLabel(l10n),
                color: AppTheme.accent,
              ),
              _CompassChip(
                icon: Icons.health_and_safety,
                label: _riskLabel(l10n),
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.35,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: widget.onPrimaryAction,
                  icon: Icon(_actionIcon(state)),
                  label: Text(action),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: widget.onSecondaryAction,
                child: Text(
                  state == CareCompassState.offline
                      ? l10n.useUssd
                      : l10n.careTab,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  CareCompassState get _state {
    final summary = widget.summary;
    if (summary != null && summary.backendAvailable) return summary.state;
    if (widget.hasLocalReport) return CareCompassState.checked;
    return CareCompassState.offline;
  }

  String _pregnancyLabel(AppLocalizations l10n) {
    final weeks = widget.summary?.pregnancyWeeks;
    if (weeks != null && weeks > 0) {
      return '${weeks.toStringAsFixed(0)} ${l10n.weeksPregnantLabel}';
    }
    return l10n.pregnancyWeek;
  }

  String _riskLabel(AppLocalizations l10n) {
    final risk = widget.summary?.latestRisk ?? widget.localRiskLabel;
    if (risk == null || risk.trim().isEmpty) return l10n.noCheckYet;
    return '${risk.trim()} ${l10n.riskLevel.toLowerCase()}';
  }

  String _title(AppLocalizations l10n, CareCompassState state) {
    return switch (state) {
      CareCompassState.noCheck => l10n.compassNoCheckTitle,
      CareCompassState.checked => l10n.compassCheckedTitle,
      CareCompassState.referralNeeded => l10n.compassReferralTitle,
      CareCompassState.followUpPending => l10n.compassFollowUpTitle,
      CareCompassState.stable => l10n.compassStableTitle,
      CareCompassState.profileNeeded => l10n.compassProfileTitle,
      CareCompassState.offline => l10n.compassOfflineTitle,
    };
  }

  String _message(AppLocalizations l10n, CareCompassState state) {
    return switch (state) {
      CareCompassState.noCheck => l10n.compassNoCheckMessage,
      CareCompassState.checked => l10n.compassCheckedMessage,
      CareCompassState.referralNeeded => l10n.compassReferralMessage,
      CareCompassState.followUpPending => l10n.compassFollowUpMessage,
      CareCompassState.stable => l10n.compassStableMessage,
      CareCompassState.profileNeeded => l10n.compassProfileMessage,
      CareCompassState.offline => l10n.compassOfflineMessage,
    };
  }

  String _primaryLabel(AppLocalizations l10n, CareCompassState state) {
    return switch (state) {
      CareCompassState.noCheck => l10n.runAiRiskScreening,
      CareCompassState.checked => l10n.viewReportsTimeline,
      CareCompassState.referralNeeded => l10n.followReferral,
      CareCompassState.followUpPending => l10n.checkCare,
      CareCompassState.stable => l10n.viewReportsTimeline,
      CareCompassState.profileNeeded => l10n.completeCareProfile,
      CareCompassState.offline => l10n.reportSymptoms,
    };
  }

  IconData _actionIcon(CareCompassState state) {
    return switch (state) {
      CareCompassState.noCheck => Icons.auto_awesome,
      CareCompassState.checked => Icons.history,
      CareCompassState.referralNeeded => Icons.local_hospital,
      CareCompassState.followUpPending => Icons.event_available,
      CareCompassState.stable => Icons.favorite,
      CareCompassState.profileNeeded => Icons.person_add_alt_1,
      CareCompassState.offline => Icons.edit,
    };
  }

  Color _colorForState(CareCompassState state) {
    return switch (state) {
      CareCompassState.referralNeeded => AppTheme.error,
      CareCompassState.followUpPending => AppTheme.warning,
      CareCompassState.stable => AppTheme.success,
      CareCompassState.checked => AppTheme.primary,
      CareCompassState.profileNeeded => AppTheme.accent,
      CareCompassState.noCheck => AppTheme.primary,
      CareCompassState.offline => AppTheme.primary,
    };
  }

  IconData _iconForState(CareCompassState state) {
    return switch (state) {
      CareCompassState.referralNeeded => Icons.local_hospital,
      CareCompassState.followUpPending => Icons.notifications_active,
      CareCompassState.stable => Icons.check,
      CareCompassState.checked => Icons.health_and_safety,
      CareCompassState.profileNeeded => Icons.person_pin_circle,
      CareCompassState.noCheck => Icons.auto_awesome,
      CareCompassState.offline => Icons.cloud_off,
    };
  }
}

class _CarePulse extends StatelessWidget {
  const _CarePulse({
    required this.controller,
    required this.color,
    required this.icon,
    required this.active,
  });

  final AnimationController controller;
  final Color color;
  final IconData icon;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final progress = active ? controller.value : 0.0;
        return SizedBox(
          width: 72,
          height: 72,
          child: CustomPaint(
            painter: _PulsePainter(color: color, progress: progress),
            child: Center(
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.28),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 25),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PulsePainter extends CustomPainter {
  const _PulsePainter({required this.color, required this.progress});

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 2; i++) {
      final phase = (progress + i * 0.46) % 1.0;
      final radius = 25 + math.sin(phase * math.pi) * 11;
      final alpha = (1 - phase).clamp(0.0, 1.0) * 0.20;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: alpha);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _CompassChip extends StatelessWidget {
  const _CompassChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
