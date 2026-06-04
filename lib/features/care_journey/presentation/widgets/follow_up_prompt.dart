import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/features/care_journey/presentation/controllers/care_journey_provider.dart';
import 'package:repair_ai/features/care_journey/presentation/widgets/care_support_block.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/shared/widgets/repair_card.dart';

class FollowUpPrompt extends ConsumerWidget {
  const FollowUpPrompt({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(careJourneyProvider);
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return RepairCard(
      elevation: compact ? 1 : 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_border, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.didYouReachCare,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              if (status != FollowUpStatus.unknown) _StatusPill(status: status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _messageFor(l10n, status),
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.35),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FollowUpChip(
                label: l10n.yesReachedCare,
                selected: status == FollowUpStatus.reachedCare,
                onTap: () => ref
                    .read(careJourneyProvider.notifier)
                    .setFollowUpStatus(FollowUpStatus.reachedCare),
              ),
              _FollowUpChip(
                label: l10n.notYet,
                selected: status == FollowUpStatus.notYet,
                onTap: () => ref
                    .read(careJourneyProvider.notifier)
                    .setFollowUpStatus(FollowUpStatus.notYet),
              ),
              _FollowUpChip(
                label: l10n.needHelp,
                selected: status == FollowUpStatus.needsHelp,
                isUrgent: true,
                onTap: () => ref
                    .read(careJourneyProvider.notifier)
                    .setFollowUpStatus(FollowUpStatus.needsHelp),
              ),
            ],
          ),
          if (status == FollowUpStatus.needsHelp) ...[
            const SizedBox(height: 12),
            const CareSupportBlock(compact: true),
          ],
        ],
      ),
    );
  }

  String _messageFor(AppLocalizations l10n, FollowUpStatus status) {
    return switch (status) {
      FollowUpStatus.reachedCare => l10n.followUpReachedMessage,
      FollowUpStatus.notYet => l10n.followUpNotYetMessage,
      FollowUpStatus.needsHelp => l10n.followUpNeedsHelpMessage,
      FollowUpStatus.unknown => l10n.followUpUnknownMessage,
    };
  }
}

class _FollowUpChip extends StatelessWidget {
  const _FollowUpChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isUrgent = false,
  });

  final String label;
  final bool selected;
  final bool isUrgent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isUrgent ? AppTheme.error : AppTheme.primary;
    return ActionChip(
      onPressed: onTap,
      avatar: selected ? const Icon(Icons.check, size: 16) : null,
      label: Text(label),
      backgroundColor: selected ? color.withValues(alpha: 0.15) : null,
      labelStyle: TextStyle(
        color: selected ? color : null,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(color: selected ? color : Colors.transparent),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final FollowUpStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = switch (status) {
      FollowUpStatus.reachedCare => l10n.reached,
      FollowUpStatus.notYet => l10n.pending,
      FollowUpStatus.needsHelp => l10n.needsHelp,
      FollowUpStatus.unknown => '',
    };
    final color = switch (status) {
      FollowUpStatus.reachedCare => AppTheme.success,
      FollowUpStatus.notYet => AppTheme.warning,
      FollowUpStatus.needsHelp => AppTheme.error,
      FollowUpStatus.unknown => AppTheme.primary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
