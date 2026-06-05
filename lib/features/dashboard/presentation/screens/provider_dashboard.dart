import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/launch_helpers.dart';
import 'package:repair_ai/core/utils/responsive.dart';
import 'package:repair_ai/features/auth/presentation/controllers/auth_session_provider.dart';
import 'package:repair_ai/features/dashboard/presentation/controllers/provider_case_queue_provider.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/shared/widgets/responsive_page.dart';

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

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.chpDashboard),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(58),
            child: _ChpSectionTabs(
              tabs: const [
                Tab(
                  child: _ChpTabLabel(
                    icon: Icons.assignment_ind_outlined,
                    label: 'Cases',
                  ),
                ),
                Tab(
                  child: _ChpTabLabel(
                    icon: Icons.flag_outlined,
                    label: 'Tasks',
                  ),
                ),
                Tab(
                  child: _ChpTabLabel(
                    icon: Icons.people_alt_outlined,
                    label: 'Patients',
                  ),
                ),
                Tab(
                  child: _ChpTabLabel(
                    icon: Icons.bar_chart_outlined,
                    label: 'Performance',
                  ),
                ),
              ],
            ),
          ),
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
          child: TabBarView(
            children: [
              _ProviderCasesTab(
                cases: cases,
                filtered: filtered,
                highCount: highCount,
                pendingCount: pendingCount,
                filter: _filter,
                contactedCases: _contactedCases,
                onFilterChanged: (value) => setState(() => _filter = value),
                onContacted: (id) => setState(() => _contactedCases.add(id)),
              ),
              _ProviderTasksTab(
                cases: cases,
                contactedCases: _contactedCases,
                onContacted: (id) => setState(() => _contactedCases.add(id)),
              ),
              _ProviderPatientsTab(cases: cases),
              _ProviderPerformanceTab(
                cases: cases,
                contactedCount: _contactedCases.length,
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

class _ProviderCasesTab extends StatelessWidget {
  const _ProviderCasesTab({
    required this.cases,
    required this.filtered,
    required this.highCount,
    required this.pendingCount,
    required this.filter,
    required this.contactedCases,
    required this.onFilterChanged,
    required this.onContacted,
  });

  final List<ProviderQueueCase> cases;
  final List<ProviderQueueCase> filtered;
  final int highCount;
  final int pendingCount;
  final String filter;
  final Set<String> contactedCases;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onContacted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: RepairInsets.scroll(context),
      child: ResponsivePageShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProviderHeader(
              totalCount: cases.length,
              highCount: highCount,
              pendingCount: pendingCount,
            ),
            const SizedBox(height: 18),
            _CaseFilter(selected: filter, onChanged: onFilterChanged),
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
                  contacted: contactedCases.contains(item.id),
                  onReferral: () =>
                      _showStatusSnack(context, l10n.referralStatusUpdated),
                  onTriage: () =>
                      _showStatusSnack(context, l10n.supportChannelsReady),
                  onWhatsApp: () => launchWhatsAppHelp(context),
                  onCall: launchEmergencyCall,
                  onContacted: () => onContacted(item.id),
                  onMedicationRegistry: () => context.push(
                    '/medication-tracking?patientId=${Uri.encodeComponent(item.id)}'
                    '&patientName=${Uri.encodeComponent(item.name)}'
                    '&mode=provider',
                  ),
                  onAncProfile: () => context.push(
                    '/dashboard/provider/anc-profile?patientId=${Uri.encodeComponent(item.id)}'
                    '&patientName=${Uri.encodeComponent(item.name)}',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProviderTasksTab extends StatelessWidget {
  const _ProviderTasksTab({
    required this.cases,
    required this.contactedCases,
    required this.onContacted,
  });

  final List<ProviderQueueCase> cases;
  final Set<String> contactedCases;
  final ValueChanged<String> onContacted;

  @override
  Widget build(BuildContext context) {
    final visibleTasks = cases
        .where(
          (item) => item.followUpStatus != ProviderFollowUpStatus.completed,
        )
        .toList();

    return SingleChildScrollView(
      padding: RepairInsets.scroll(context),
      child: ResponsivePageShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Maternal follow-up tasks',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (visibleTasks.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No follow-ups are due right now.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            else
              ...visibleTasks.map(
                (item) => _TaskCard(
                  item: item,
                  contacted: contactedCases.contains(item.id),
                  onOpenRegistry: () => context.push(
                    '/medication-tracking?patientId=${Uri.encodeComponent(item.id)}'
                    '&patientName=${Uri.encodeComponent(item.name)}'
                    '&mode=provider',
                  ),
                  onOpenAncProfile: () => context.push(
                    '/dashboard/provider/anc-profile?patientId=${Uri.encodeComponent(item.id)}'
                    '&patientName=${Uri.encodeComponent(item.name)}',
                  ),
                  onContacted: () => onContacted(item.id),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProviderPatientsTab extends StatelessWidget {
  const _ProviderPatientsTab({required this.cases});

  final List<ProviderQueueCase> cases;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: RepairInsets.scroll(context),
      children: [
        ResponsivePageShell(
          child: Column(
            children: [
              for (final item in cases)
                _PatientSummaryCard(
                  item: item,
                  onMedicationRegistry: () => context.push(
                    '/medication-tracking?patientId=${Uri.encodeComponent(item.id)}'
                    '&patientName=${Uri.encodeComponent(item.name)}'
                    '&mode=provider',
                  ),
                  onAncProfile: () => context.push(
                    '/dashboard/provider/anc-profile?patientId=${Uri.encodeComponent(item.id)}'
                    '&patientName=${Uri.encodeComponent(item.name)}',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProviderPerformanceTab extends StatelessWidget {
  const _ProviderPerformanceTab({
    required this.cases,
    required this.contactedCount,
  });

  final List<ProviderQueueCase> cases;
  final int contactedCount;

  @override
  Widget build(BuildContext context) {
    final highRisk = cases.where((item) => item.risk == ProviderCaseRisk.high);
    final followedUp = cases
        .where(
            (item) => item.followUpStatus == ProviderFollowUpStatus.completed)
        .length;
    final prescriptions = cases
        .where((item) => !item.medicationStatus.toLowerCase().contains('no '))
        .length;
    final pending = cases
        .where(
            (item) => item.followUpStatus != ProviderFollowUpStatus.completed)
        .length;

    return SingleChildScrollView(
      padding: RepairInsets.scroll(context),
      child: ResponsivePageShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'REPAIR-AI field indicators',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _PerformanceGrid(
              items: [
                _PerformanceItem(
                  'High-risk contacted',
                  '$contactedCount / ${highRisk.length}',
                  Icons.call_outlined,
                  AppTheme.error,
                ),
                _PerformanceItem(
                  'Referrals followed up',
                  '$followedUp / ${cases.length}',
                  Icons.route_outlined,
                  AppTheme.primary,
                ),
                _PerformanceItem(
                  'Prescriptions registered',
                  '$prescriptions',
                  Icons.medication_outlined,
                  AppTheme.success,
                ),
                _PerformanceItem(
                  'Pending follow-ups',
                  '$pending',
                  Icons.pending_actions,
                  AppTheme.warning,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChpSectionTabs extends StatelessWidget {
  const _ChpSectionTabs({required this.tabs});

  final List<Widget> tabs;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
      ),
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        labelColor: AppTheme.primary,
        unselectedLabelColor: Colors.white,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        tabs: tabs,
      ),
    );
  }
}

class _ChpTabLabel extends StatelessWidget {
  const _ChpTabLabel({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 76, maxWidth: 124),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.item,
    required this.contacted,
    required this.onOpenRegistry,
    required this.onOpenAncProfile,
    required this.onContacted,
  });

  final ProviderQueueCase item;
  final bool contacted;
  final VoidCallback onOpenRegistry;
  final VoidCallback onOpenAncProfile;
  final VoidCallback onContacted;

  @override
  Widget build(BuildContext context) {
    final color = _followUpColor(item.followUpStatus);
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
                  child: Icon(_taskIcon(item.taskType), color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _taskLabel(item.taskType),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${item.name} • ${item.area}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _StatusPill(
                  icon: Icons.schedule,
                  label: item.dueLabel,
                  color: color,
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
                  icon: Icons.call_outlined,
                  label: item.lastContact,
                  color: AppTheme.primary,
                ),
                _StatusPill(
                  icon: Icons.medication_outlined,
                  label: item.medicationStatus,
                  color: AppTheme.success,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: launchEmergencyCall,
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenRegistry,
                  icon: const Icon(Icons.medication_outlined),
                  label: const Text('Drug registry'),
                ),
                OutlinedButton.icon(
                  onPressed: onOpenAncProfile,
                  icon: const Icon(Icons.assignment_turned_in_outlined),
                  label: const Text('ANC profile'),
                ),
                OutlinedButton.icon(
                  onPressed: contacted ? null : onContacted,
                  icon: const Icon(Icons.done_all),
                  label: Text(contacted ? 'Contacted' : 'Mark contacted'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientSummaryCard extends StatelessWidget {
  const _PatientSummaryCard({
    required this.item,
    required this.onMedicationRegistry,
    required this.onAncProfile,
  });

  final ProviderQueueCase item;
  final VoidCallback onMedicationRegistry;
  final VoidCallback onAncProfile;

  @override
  Widget build(BuildContext context) {
    final riskColor = switch (item.risk) {
      ProviderCaseRisk.high => AppTheme.error,
      ProviderCaseRisk.moderate => AppTheme.warning,
      ProviderCaseRisk.low => AppTheme.success,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: riskColor.withValues(alpha: 0.14),
          child: Text(
            item.name.characters.first,
            style: TextStyle(color: riskColor, fontWeight: FontWeight.w900),
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${item.area} • ${item.clinicalContextLabel}\n${item.medicationStatus}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          tooltip: 'Patient actions',
          onSelected: (value) {
            if (value == 'medication') onMedicationRegistry();
            if (value == 'anc') onAncProfile();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'medication', child: Text('Drug registry')),
            PopupMenuItem(value: 'anc', child: Text('ANC profile')),
          ],
          icon: const Icon(Icons.more_vert),
        ),
      ),
    );
  }
}

class _PerformanceItem {
  const _PerformanceItem(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _PerformanceGrid extends StatelessWidget {
  const _PerformanceGrid({required this.items});

  final List<_PerformanceItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 4 : 2;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - ((columns - 1) * spacing)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: Card(
                  color: item.color.withValues(alpha: 0.10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(item.icon, color: item.color),
                        const SizedBox(height: 10),
                        Text(
                          item.value,
                          style: TextStyle(
                            color: item.color,
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                        Text(
                          item.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 340;
          const avatar = CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(Icons.health_and_safety, color: Colors.white),
          );
          final content = Column(
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
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                avatar,
                const SizedBox(height: 12),
                content,
              ],
            );
          }

          return Row(
            children: [
              avatar,
              const SizedBox(width: 12),
              Expanded(child: content),
            ],
          );
        },
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

class _CaseCard extends StatefulWidget {
  const _CaseCard({
    required this.item,
    required this.contacted,
    required this.onReferral,
    required this.onTriage,
    required this.onWhatsApp,
    required this.onCall,
    required this.onContacted,
    required this.onMedicationRegistry,
    required this.onAncProfile,
  });

  final ProviderQueueCase item;
  final bool contacted;
  final VoidCallback onReferral;
  final VoidCallback onTriage;
  final VoidCallback onWhatsApp;
  final VoidCallback onCall;
  final VoidCallback onContacted;
  final VoidCallback onMedicationRegistry;
  final VoidCallback onAncProfile;

  @override
  State<_CaseCard> createState() => _CaseCardState();
}

class _CaseCardState extends State<_CaseCard> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = switch (widget.item.risk) {
      ProviderCaseRisk.high => AppTheme.error,
      ProviderCaseRisk.moderate => AppTheme.warning,
      _ => AppTheme.success,
    };
    final riskLabel = _riskLabel(widget.item.risk);
    final statusLabel = _statusLabel(widget.item.referralStatus, l10n);
    final lastUpdate = switch (widget.item.lastUpdate) {
      'Today' => l10n.today,
      'Yesterday' => l10n.yesterday,
      _ => widget.item.lastUpdate,
    };
    final textColor = Theme.of(context).colorScheme.onSurface;
    final metaColor = textColor.withValues(alpha: 0.78);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.14),
                  child: Text(
                    widget.item.name.characters.first,
                    style: TextStyle(color: color, fontWeight: FontWeight.w900),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${l10n.assignedArea}: ${widget.item.area}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: metaColor),
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
            Text(
              widget.item.symptoms,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusPill(
                  icon: Icons.event_available_outlined,
                  label: widget.item.dueLabel,
                  color: _followUpColor(widget.item.followUpStatus),
                ),
                _StatusPill(
                  icon: Icons.call_outlined,
                  label: widget.item.lastContact,
                  color: AppTheme.primary,
                ),
                if (widget.contacted)
                  _StatusPill(
                    icon: Icons.check_circle_outline,
                    label: l10n.contacted,
                    color: AppTheme.success,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final compactActions = constraints.maxWidth < 390;
                final primaryActions = [
                  FilledButton.tonalIcon(
                    onPressed: widget.onCall,
                    icon: const Icon(Icons.call),
                    label: Text(l10n.callMother),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: widget.onWhatsApp,
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: Text(l10n.message),
                  ),
                ];

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (compactActions) ...[
                      _CompactCaseActionButton(
                        onPressed: widget.onCall,
                        icon: Icons.call,
                        label: l10n.callMother,
                      ),
                      _CompactCaseActionButton(
                        onPressed: widget.onWhatsApp,
                        icon: Icons.chat_bubble_outline,
                        label: l10n.message,
                      ),
                    ] else
                      ...primaryActions,
                    if (!compactActions)
                      OutlinedButton.icon(
                        onPressed: widget.onMedicationRegistry,
                        icon: const Icon(Icons.medication_outlined),
                        label: Text(l10n.drugRegistry),
                      ),
                    if (!compactActions)
                      OutlinedButton.icon(
                        onPressed: widget.onAncProfile,
                        icon: const Icon(Icons.assignment_turned_in_outlined),
                        label: const Text('ANC profile'),
                      ),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _showDetails = !_showDetails),
                      icon: Icon(
                        _showDetails ? Icons.expand_less : Icons.expand_more,
                      ),
                      label: Text(_showDetails ? 'Hide details' : 'Details'),
                    ),
                    _CaseActionMenu(
                      contacted: widget.contacted,
                      onReferral: widget.onReferral,
                      onContacted: widget.onContacted,
                      onMedicationRegistry: widget.onMedicationRegistry,
                      onAncProfile: widget.onAncProfile,
                      onTriage: widget.onTriage,
                    ),
                  ],
                );
              },
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(
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
                    _StatusPill(
                      icon: Icons.pregnant_woman,
                      label: widget.item.pregnancyWeeks == null
                          ? 'Pregnancy weeks pending'
                          : '${widget.item.pregnancyWeeks} weeks',
                      color: AppTheme.primary,
                    ),
                    _StatusPill(
                      icon: Icons.cake_outlined,
                      label: widget.item.effectiveAgeYears == null
                          ? 'Age pending'
                          : '${widget.item.effectiveAgeYears} years',
                      color: AppTheme.primary,
                    ),
                    _StatusPill(
                      icon: Icons.medication_outlined,
                      label: widget.item.medicationStatus,
                      color: AppTheme.success,
                    ),
                  ],
                ),
              ),
              crossFadeState: _showDetails
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaseActionMenu extends StatelessWidget {
  const _CaseActionMenu({
    required this.contacted,
    required this.onReferral,
    required this.onContacted,
    required this.onMedicationRegistry,
    required this.onAncProfile,
    required this.onTriage,
  });

  final bool contacted;
  final VoidCallback onReferral;
  final VoidCallback onContacted;
  final VoidCallback onMedicationRegistry;
  final VoidCallback onAncProfile;
  final VoidCallback onTriage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopupMenuButton<String>(
      tooltip: l10n.quickActions,
      onSelected: (value) {
        switch (value) {
          case 'referral':
            onReferral();
          case 'contacted':
            if (!contacted) onContacted();
          case 'medication':
            onMedicationRegistry();
          case 'anc':
            onAncProfile();
          case 'triage':
            onTriage();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'referral',
          child: Text(l10n.followReferral),
        ),
        PopupMenuItem(
          value: 'contacted',
          enabled: !contacted,
          child: Text(l10n.markContacted),
        ),
        PopupMenuItem(
          value: 'medication',
          child: Text(l10n.drugRegistry),
        ),
        const PopupMenuItem(
          value: 'anc',
          child: Text('ANC profile'),
        ),
        PopupMenuItem(
          value: 'triage',
          child: Text(l10n.startWithSymptomCheck),
        ),
      ],
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 132),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.more_horiz, size: 18, color: AppTheme.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l10n.quickActions,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactCaseActionButton extends StatelessWidget {
  const _CompactCaseActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

Color _followUpColor(ProviderFollowUpStatus status) {
  return switch (status) {
    ProviderFollowUpStatus.overdue => AppTheme.error,
    ProviderFollowUpStatus.dueToday => AppTheme.warning,
    ProviderFollowUpStatus.completed => AppTheme.success,
  };
}

IconData _taskIcon(ProviderTaskType type) {
  return switch (type) {
    ProviderTaskType.referralFollowUp => Icons.route_outlined,
    ProviderTaskType.dangerSignFollowUp => Icons.warning_amber_outlined,
    ProviderTaskType.medicationCheckIn => Icons.medication_outlined,
  };
}

String _taskLabel(ProviderTaskType type) {
  return switch (type) {
    ProviderTaskType.referralFollowUp => 'Referral follow-up',
    ProviderTaskType.dangerSignFollowUp => 'Danger-sign follow-up',
    ProviderTaskType.medicationCheckIn => 'Medication check-in',
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth.clamp(92.0, 220.0)
            : 220.0;

        return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: DecoratedBox(
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
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
