import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/features/home/presentation/controllers/dashboard_stats_provider.dart';

const _casesLabel = 'EPL Cases';
const _alertsLabel = 'Alerts';
const _referralsLabel = 'Referrals';
const _followUpsLabel = 'Follow-ups';
const _viewFullLabel = 'View full summary';

/// Compact health summary strip for the patient home screen.
/// Shows 4 stats + risk banner. Uses dashboardStatsProvider (single API call)
/// to avoid the previous redundant 4-parallel-request pattern.
class PatientHealthSummary extends ConsumerWidget {
  const PatientHealthSummary({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return statsAsync.when(
      loading: () => const _SummarySkeleton(),
      error: (_, __) => _SummaryPlaceholder(
          onRetry: () => ref.refresh(dashboardStatsProvider.future)),
      data: (stats) {
        return _SummaryContent(stats: stats);
      },
    );
  }
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({required this.stats});

  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Risk banner
          if (stats.latestRiskLevel != null)
            _RiskBanner(risk: stats.latestRiskLevel!),

          // Stat chips row
          const SizedBox(height: 10),
          Row(
            children: [
              _StatChip(
                icon: Icons.assignment_outlined,
                label: _casesLabel,
                count: stats.totalVisits,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.notifications_active_rounded,
                label: _alertsLabel,
                count: stats.activeAlerts,
                color:
                    stats.activeAlerts > 0 ? AppTheme.error : scheme.outline,
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.swap_horiz_rounded,
                label: _referralsLabel,
                count: stats.totalReferrals,
                color: scheme.secondary,
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.schedule_rounded,
                label: _followUpsLabel,
                count: stats.pendingFollowups,
                color: AppTheme.success,
              ),
            ],
          ),

          // View all link
          if (stats.totalVisits > 0 || stats.totalReferrals > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => context.push('/care'),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text(_viewFullLabel),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: isDark ? 0.18 : 0.1),
              color.withValues(alpha: isDark ? 0.08 : 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.25 : 0.18),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color.withValues(alpha: 0.8),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskBanner extends StatelessWidget {
  const _RiskBanner({required this.risk});

  final String risk;

  Color get _color {
    switch (risk) {
      case 'high':
        return AppTheme.error;
      case 'moderate':
        return AppTheme.warning;
      default:
        return AppTheme.success;
    }
  }

  IconData get _icon {
    switch (risk) {
      case 'high':
        return Icons.warning_rounded;
      case 'moderate':
        return Icons.info_outline_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  String get _riskLabel {
    switch (risk) {
      case 'high':
        return 'High Risk — Seek care promptly';
      case 'moderate':
        return 'Moderate Risk — Monitor & follow up';
      default:
        return 'Low Risk — Keep up with check-ups';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(_icon, color: _color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _riskLabel,
              style: TextStyle(
                color: _color,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(
          4,
          (_) => Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 78,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryPlaceholder extends StatelessWidget {
  const _SummaryPlaceholder({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.warning.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.warning.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 20, color: AppTheme.warning),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Health summary unavailable',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
