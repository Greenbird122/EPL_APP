import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/utils/responsive.dart';
import 'package:repair_ai/features/auth/presentation/controllers/report_history_providers.dart';
import 'package:repair_ai/features/triage/domain/symptom_catalog.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/localization/triage_l10n.dart';
import 'package:repair_ai/shared/widgets/bottom_nav.dart';
import 'package:repair_ai/shared/widgets/empty_state.dart';
import 'package:repair_ai/shared/widgets/repair_app_bar.dart';
import 'package:repair_ai/shared/widgets/repair_buttons.dart';
import 'package:repair_ai/shared/widgets/responsive_page.dart';

class MyReportsScreen extends ConsumerWidget {
  const MyReportsScreen({super.key});

  Color _riskColor(String level) {
    switch (level.toLowerCase()) {
      case 'high':
        return AppTheme.error;
      case 'moderate':
        return AppTheme.warning;
      case 'low':
        return AppTheme.success;
      default:
        return AppTheme.success;
    }
  }

  String _riskLabel(AppLocalizations l10n, String stored) {
    final parsed = l10n.riskFromStored(stored);
    return parsed != null ? l10n.riskLabel(parsed) : stored;
  }

  void _showDetail(BuildContext context, WidgetRef ref, SymptomReport report) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${report.date.day}/${report.date.month}/${report.date.year}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _riskColor(report.riskLevel),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${l10n.riskLevel}: ${_riskLabel(l10n, report.riskLevel)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Text(
                    '${(report.confidence * 100).round()}%',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l10n.basedOnSymptoms,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...report.symptoms.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• ${SymptomCatalog.label(l10n, s)}'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${report.gestationalAge.toStringAsFixed(1)} ${l10n.weeksPregnantLabel}',
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 6),
              Text(
                '${_labelFor(report.severity)} • ${_labelFor(report.duration)}',
                style: TextStyle(color: Colors.grey[700]),
              ),
              if (report.notes.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(report.notes, style: const TextStyle(height: 1.4)),
              ],
              const SizedBox(height: 16),
              Text(
                l10n.recommendation,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(report.recommendation),
              const SizedBox(height: 20),
              RepairPrimaryButton(
                label: l10n.startReferral,
                icon: Icons.local_hospital,
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.push('/referral');
                },
              ),
              const SizedBox(height: 8),
              RepairOutlinedButton(
                label: 'Export / share report',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report export queued.')),
                  );
                },
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  await ref
                      .read(reportHistoryProvider.notifier)
                      .deleteReport(report.id);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report deleted.')),
                    );
                  }
                },
                icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                label: const Text(
                  'Delete report',
                  style: TextStyle(color: AppTheme.error),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.close),
              ),
            ],
          ),
        );
      },
    );
  }

  String _labelFor(String value) {
    switch (value) {
      case 'mild':
        return 'Mild';
      case 'moderate':
        return 'Moderate';
      case 'severe':
        return 'Severe';
      case 'today':
        return 'Started today';
      case 'two_days':
        return '1-2 days';
      case 'three_plus':
        return '3+ days';
      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final reports = ref.watch(reportHistoryProvider);

    String symptomLine(SymptomReport report) {
      return report.symptoms
          .map((s) => SymptomCatalog.label(l10n, s))
          .join(', ');
    }

    return Scaffold(
      appBar: RepairAppBar(title: l10n.myReports),
      body: reports.isEmpty
          ? EmptyState(
              icon: Icons.description_outlined,
              title: l10n.noReportsYet,
              message: l10n.reportSymptomsSubtitle,
              imageAsset: 'assets/illustrations/mother_2.jpg',
              actionLabel: l10n.reportSymptoms,
              onAction: () => context.push('/triage/symptom-report'),
            )
          : ListView.builder(
              padding: RepairInsets.scroll(context),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final report = reports[reports.length - 1 - index];
                return ResponsivePageShell(
                  maxWidth: RepairSizing.formMaxWidth(context),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _riskColor(
                          report.riskLevel,
                        ).withValues(alpha: 0.15),
                        child: Icon(
                          Icons.medical_services,
                          color: _riskColor(report.riskLevel),
                        ),
                      ),
                      title: Text(
                        symptomLine(report),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${report.date.day}/${report.date.month}/${report.date.year} • '
                        '${report.gestationalAge.toStringAsFixed(1)} ${l10n.weeksPregnantLabel} • '
                        '${_riskLabel(l10n, report.riskLevel)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showDetail(context, ref, report),
                    ),
                  ),
                );
              },
            ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
    );
  }
}
