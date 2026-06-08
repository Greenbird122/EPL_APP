import 'package:flutter/material.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/features/home/presentation/controllers/home_care_summary_provider.dart';
import 'package:repair_ai/localization/app_localizations.dart';

class CareSignalRow extends StatelessWidget {
  const CareSignalRow({
    super.key,
    required this.summary,
    required this.hasLocalReport,
    required this.onTriage,
    required this.onReferral,
    required this.onCare,
  });

  final HomeCareSummary? summary;
  final bool hasLocalReport;
  final VoidCallback onTriage;
  final VoidCallback onReferral;
  final VoidCallback onCare;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final backendOffline = summary != null && !summary!.backendAvailable;
    final aiStatus = backendOffline
        ? CareSignalStatus.offline
        : (summary?.hasRisk == true || hasLocalReport
            ? CareSignalStatus.ready
            : CareSignalStatus.empty);
    final referralStatus = backendOffline
        ? CareSignalStatus.offline
        : (summary?.hasReferral == true
            ? CareSignalStatus.warning
            : CareSignalStatus.empty);
    final followUpStatus = backendOffline
        ? CareSignalStatus.offline
        : (summary?.hasFollowUp == true
            ? CareSignalStatus.warning
            : CareSignalStatus.empty);

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 390;
        final tiles = [
          _SignalTile(
            label: l10n.aiSignalLabel,
            value: _statusText(l10n, aiStatus),
            icon: Icons.auto_awesome,
            status: aiStatus,
            onTap: onTriage,
          ),
          _SignalTile(
            label: l10n.referralSignalLabel,
            value: _statusText(l10n, referralStatus),
            icon: Icons.route,
            status: referralStatus,
            onTap: onReferral,
          ),
          _SignalTile(
            label: l10n.followUpSignalLabel,
            value: _statusText(l10n, followUpStatus),
            icon: Icons.event_available,
            status: followUpStatus,
            onTap: onCare,
          ),
        ];

        if (narrow) {
          return Column(
            children: [
              for (final tile in tiles) ...[
                tile,
                if (tile != tiles.last) const SizedBox(height: 8),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (final tile in tiles) ...[
              Expanded(child: tile),
              if (tile != tiles.last) const SizedBox(width: 8),
            ],
          ],
        );
      },
    );
  }

  String _statusText(AppLocalizations l10n, CareSignalStatus status) {
    return switch (status) {
      CareSignalStatus.ready => l10n.signalReady,
      CareSignalStatus.warning => l10n.signalNeedsAttention,
      CareSignalStatus.urgent => l10n.signalUrgent,
      CareSignalStatus.complete => l10n.signalComplete,
      CareSignalStatus.offline => l10n.signalSaved,
      CareSignalStatus.empty => l10n.signalNotYet,
    };
  }
}

class _SignalTile extends StatelessWidget {
  const _SignalTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.status,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final CareSignalStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _color(status);
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 86),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
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
            ],
          ),
        ),
      ),
    );
  }

  Color _color(CareSignalStatus status) {
    return switch (status) {
      CareSignalStatus.ready => AppTheme.success,
      CareSignalStatus.warning => AppTheme.warning,
      CareSignalStatus.urgent => AppTheme.error,
      CareSignalStatus.complete => AppTheme.success,
      CareSignalStatus.offline => AppTheme.primary,
      CareSignalStatus.empty => AppTheme.primary,
    };
  }
}
