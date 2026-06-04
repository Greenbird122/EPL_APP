import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/launch_helpers.dart';
import 'package:repair_ai/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:repair_ai/features/dashboard/presentation/controllers/provider_case_queue_provider.dart';
import 'package:repair_ai/localization/app_localizations.dart';

class ProviderDashboard extends ConsumerStatefulWidget {
  const ProviderDashboard({super.key});

  @override
  ConsumerState<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends ConsumerState<ProviderDashboard> {
  String _filter = 'all';
  final Set<String> _contactedCases = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cases = ref.watch(providerCaseQueueProvider);
    final filtered = _filter == 'all'
        ? cases
        : cases.where((item) => item.risk.name == _filter).toList();
    final highCount =
        cases.where((item) => item.risk == ProviderCaseRisk.high).length;
    final pendingCount = cases
        .where((item) =>
            item.referralStatus == ProviderReferralStatus.pending ||
            item.referralStatus == ProviderReferralStatus.sent)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chpDashboard),
        actions: [
          IconButton(
            tooltip: l10n.logout,
            onPressed: () async {
              await ref.read(authSessionProvider.notifier).signOut();
              if (context.mounted) context.go('/auth');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProviderHeader(
                totalCount: cases.length,
                highCount: highCount,
                pendingCount: pendingCount,
              ),
              const SizedBox(height: 14),
              _StatsRow(
                totalCount: cases.length,
                highCount: highCount,
                pendingCount: pendingCount,
              ),
              const SizedBox(height: 18),
              _CaseFilter(
                selected: _filter,
                onChanged: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.caseQueue,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),
              if (filtered.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(l10n.noCasesMatchFilter),
                  ),
                )
              else
                ...filtered.map(
                  (item) => _CaseCard(
                    item: item,
                    contacted: _contactedCases.contains(item.id),
                    onReferral: () => _showStatusSnack(
                      context,
                      l10n.referralStatusUpdated,
                    ),
                    onTriage: () => _showStatusSnack(
                      context,
                      l10n.supportChannelsReady,
                    ),
                    onWhatsApp: () => launchWhatsAppHelp(context),
                    onCall: launchEmergencyCall,
                    onContacted: () =>
                        setState(() => _contactedCases.add(item.id)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showStatusSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

class _ProviderHeader extends StatelessWidget {
  const _ProviderHeader({
    required this.highCount,
    required this.totalCount,
    required this.pendingCount,
  });

  final int highCount;
  final int totalCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF8C6BFF)],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(Icons.health_and_safety, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.chpWorkspaceTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.chpWorkspaceSubtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeaderChip('${l10n.activeCases}: $totalCount'),
                    _HeaderChip('${l10n.highPriority}: $highCount'),
                    _HeaderChip('${l10n.pendingFollowUps}: $pendingCount'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.totalCount,
    required this.highCount,
    required this.pendingCount,
  });

  final int totalCount;
  final int highCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Expanded(
          child: _StatTile(l10n.activeCases, totalCount, AppTheme.primary),
        ),
        const SizedBox(width: 8),
        Expanded(
            child: _StatTile(l10n.highPriority, highCount, AppTheme.error)),
        const SizedBox(width: 8),
        Expanded(
          child:
              _StatTile(l10n.pendingFollowUps, pendingCount, AppTheme.warning),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaseFilter extends StatelessWidget {
  const _CaseFilter({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<String>(
        segments: [
          ButtonSegment(value: 'all', label: Text(l10n.allCases)),
          const ButtonSegment(value: 'high', label: Text('High')),
          const ButtonSegment(value: 'moderate', label: Text('Moderate')),
          const ButtonSegment(value: 'low', label: Text('Low')),
        ],
        selected: {selected},
        onSelectionChanged: (value) => onChanged(value.first),
      ),
    );
  }
}

class _CaseCard extends StatelessWidget {
  const _CaseCard({
    required this.item,
    required this.contacted,
    required this.onReferral,
    required this.onTriage,
    required this.onWhatsApp,
    required this.onCall,
    required this.onContacted,
  });

  final ProviderQueueCase item;
  final bool contacted;
  final VoidCallback onReferral;
  final VoidCallback onTriage;
  final VoidCallback onWhatsApp;
  final VoidCallback onCall;
  final VoidCallback onContacted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = switch (item.risk) {
      ProviderCaseRisk.high => AppTheme.error,
      ProviderCaseRisk.moderate => AppTheme.warning,
      _ => AppTheme.success,
    };
    final riskLabel = _riskLabel(item.risk);
    final statusLabel = _statusLabel(item.referralStatus, l10n);
    final lastUpdate = switch (item.lastUpdate) {
      'Today' => l10n.today,
      'Yesterday' => l10n.yesterday,
      _ => item.lastUpdate,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.14),
                  child: Text(
                    item.name.characters.first,
                    style: TextStyle(color: color, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${l10n.assignedArea}: ${item.area} • ${item.meta}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(riskLabel),
                  backgroundColor: color.withValues(alpha: 0.12),
                  labelStyle: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(item.symptoms),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusPill(
                  icon: Icons.route,
                  label: statusLabel,
                  color: AppTheme.primary,
                ),
                _StatusPill(
                  icon: Icons.schedule,
                  label: '${l10n.lastUpdate}: $lastUpdate',
                  color: AppTheme.warning,
                ),
                if (contacted)
                  _StatusPill(
                    icon: Icons.check_circle_outline,
                    label: l10n.contacted,
                    color: AppTheme.success,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call),
                  label: Text(l10n.callMother),
                ),
                FilledButton.tonalIcon(
                  onPressed: onWhatsApp,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text(l10n.message),
                ),
                OutlinedButton.icon(
                  onPressed: onReferral,
                  icon: const Icon(Icons.route),
                  label: Text(l10n.followReferral),
                ),
                OutlinedButton.icon(
                  onPressed: contacted ? null : onContacted,
                  icon: const Icon(Icons.done_all),
                  label: Text(l10n.markContacted),
                ),
                TextButton.icon(
                  onPressed: onTriage,
                  icon: const Icon(Icons.assignment_outlined),
                  label: Text(l10n.startWithSymptomCheck),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _riskLabel(ProviderCaseRisk risk) {
  return switch (risk) {
    ProviderCaseRisk.high => 'High',
    ProviderCaseRisk.moderate => 'Moderate',
    ProviderCaseRisk.low => 'Low',
  };
}

String _statusLabel(ProviderReferralStatus status, AppLocalizations l10n) {
  return switch (status) {
    ProviderReferralStatus.sent => l10n.referralSentStatus,
    ProviderReferralStatus.pending => l10n.pending,
    ProviderReferralStatus.reached => l10n.reached,
  };
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
