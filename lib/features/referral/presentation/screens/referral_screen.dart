import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/network/api_client.dart';
import 'package:repair_ai/core/network/backend_services.dart';
import 'package:repair_ai/core/utils/launch_helpers.dart';
import 'package:repair_ai/core/utils/responsive.dart';
import 'package:repair_ai/features/anc/presentation/controllers/anc_profile_controller.dart';
import 'package:repair_ai/features/care_journey/presentation/widgets/care_support_block.dart';
import 'package:repair_ai/features/care_journey/presentation/widgets/follow_up_prompt.dart';
import 'package:repair_ai/features/referral/presentation/controllers/referral_facilities_provider.dart';
import 'package:repair_ai/features/referral/presentation/controllers/referral_state_provider.dart';
import 'package:repair_ai/features/triage/application/triage_controller.dart';
import 'package:repair_ai/features/triage/domain/triage_result.dart';
import 'package:repair_ai/localization/app_localizations.dart';
import 'package:repair_ai/shared/widgets/bottom_nav.dart';
import 'package:repair_ai/shared/widgets/repair_app_bar.dart';
import 'package:repair_ai/shared/widgets/repair_buttons.dart';
import 'package:repair_ai/shared/widgets/responsive_page.dart';
import 'package:repair_ai/shared/widgets/ussd_access_card.dart';

class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final result = ref.watch(triageResultProvider);
    final referral = ref.watch(referralStateProvider);
    final facilitiesAsync = ref.watch(referralFacilitiesProvider);
    final isUrgent = result?.riskLevel == RiskLevel.high;
    final compact = RepairBreakpoints.isCompactPhone(context);

    return Scaffold(
      appBar: RepairAppBar(title: l10n.findCareTitle),
      body: SingleChildScrollView(
        padding: RepairInsets.scroll(context),
        child: ResponsivePageShell(
          maxWidth: RepairSizing.formMaxWidth(context),
          child: facilitiesAsync.when(
            loading: () => _ReferralBody(
              compact: compact,
              isUrgent: isUrgent,
              referral: referral,
              selectedFacility: null,
              facilitiesState: null,
            ),
            error: (error, _) => _ReferralBody(
              compact: compact,
              isUrgent: isUrgent,
              referral: referral,
              selectedFacility: null,
              facilitiesState: ReferralFacilitiesState(
                source: ReferralFacilitySource.unavailable,
                facilities: const [],
                error: l10n.facilitiesLoadError,
              ),
            ),
            data: (facilitiesState) {
              final selectedFacility = _selectedFacility(
                facilitiesState.facilities,
                referral.selectedFacility,
              );
              return _ReferralBody(
                compact: compact,
                isUrgent: isUrgent,
                referral: referral,
                selectedFacility: selectedFacility,
                facilitiesState: facilitiesState,
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
    );
  }

  ReferralFacility? _selectedFacility(
    List<ReferralFacility> facilities,
    int facilityId,
  ) {
    if (facilities.isEmpty) return null;
    return facilities.cast<ReferralFacility?>().firstWhere(
          (f) => f?.id == facilityId,
          orElse: () => facilities.first,
        );
  }
}

class _ReferralBody extends ConsumerStatefulWidget {
  const _ReferralBody({
    required this.compact,
    required this.isUrgent,
    required this.referral,
    required this.selectedFacility,
    required this.facilitiesState,
  });

  final bool compact;
  final bool isUrgent;
  final ReferralState referral;
  final ReferralFacility? selectedFacility;
  final ReferralFacilitiesState? facilitiesState;

  @override
  ConsumerState<_ReferralBody> createState() => _ReferralBodyState();
}

class _ReferralBodyState extends ConsumerState<_ReferralBody> {
  bool _showAllMapResults = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final facilities =
        widget.facilitiesState?.facilities ?? const <ReferralFacility>[];
    final mapFacilities =
        widget.facilitiesState?.mapFacilities ?? const <ReferralFacility>[];
    final visibleMapFacilities =
        _showAllMapResults ? mapFacilities : mapFacilities.take(3).toList();
    final isLoading = widget.facilitiesState == null;
    // Use authenticated patient's ANC profile with null safety
    final ancProfileAsync = ref.watch(ancProfileProvider);
    final ancProfile = ancProfileAsync.maybeWhen(
      data: (profile) => profile,
      orElse: () => null,
    );
    final ancFlags = ancProfile?.contextFlags ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (widget.isUrgent)
          _UrgentReferralBanner(
            text: l10n.goNowUrgency,
            onCall: launchEmergencyCall,
          ),
        _ReferralStatusCard(
          status: widget.referral.status,
          facilityName:
              widget.selectedFacility?.name ?? l10n.recommendedFacility,
          l10n: l10n,
        ),
        if (ancFlags.isNotEmpty) ...[
          const SizedBox(height: 10),
          _AncReferralNotice(
            title: l10n.ancContextForReferral,
            flags: ancFlags,
          ),
        ],
        if (widget.facilitiesState?.error != null) ...[
          const SizedBox(height: 10),
          _NoticeCard(
            icon: Icons.cloud_off_outlined,
            text: widget.facilitiesState!.error!,
            color: AppTheme.error,
          ),
        ],
        if (widget.facilitiesState?.message != null) ...[
          const SizedBox(height: 10),
          _NoticeCard(
            icon: widget.facilitiesState!.hasGps
                ? Icons.my_location
                : Icons.location_off_outlined,
            text: widget.facilitiesState!.message!,
            color: widget.facilitiesState!.hasGps
                ? AppTheme.success
                : AppTheme.warning,
          ),
        ],
        const SizedBox(height: 14),
        _MapHeader(
          title: l10n.verifiedCareNearYou,
          verifiedCount: facilities.length,
          mapCount: mapFacilities.length,
        ),
        const SizedBox(height: 10),
        if (isLoading)
          const _MapLoadingCard()
        else
          _FacilityListCard(
            facilities: [...facilities, ...mapFacilities],
            selectedFacility: widget.selectedFacility,
            patientLocation: widget.facilitiesState?.patientLocation,
          ),
        const SizedBox(height: 18),
        Text(
          l10n.nearbyVerifiedFacilities,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (isLoading)
          const _FacilityLoadingList()
        else if (facilities.isEmpty)
          _EmptyFacilitiesCard(message: l10n.noVerifiedNearbyFacilities)
        else
          ...facilities.asMap().entries.map(
                (entry) => _FacilityCard(
                  facility: entry.value,
                  selected: entry.value.id == widget.selectedFacility?.id,
                  recommended: entry.key == 0,
                  onTap: () => ref
                      .read(referralStateProvider.notifier)
                      .selectFacility(entry.value.id),
                  onDirections: () => _openDirections(
                    entry.value,
                    widget.facilitiesState?.patientLocation,
                  ),
                ),
              ),
        if (!isLoading && mapFacilities.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text(
            l10n.nearbyMapResults,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _NoticeCard(
            icon: Icons.info_outline,
            text: l10n.mapResultsNotClinical,
            color: AppTheme.warning,
          ),
          const SizedBox(height: 10),
          ...visibleMapFacilities.map(
            (facility) => _MapFacilityCard(facility: facility),
          ),
          if (mapFacilities.length > 3)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () =>
                    setState(() => _showAllMapResults = !_showAllMapResults),
                icon: Icon(
                  _showAllMapResults ? Icons.expand_less : Icons.expand_more,
                ),
                label: Text(
                  _showAllMapResults
                      ? l10n.showFewerMapResults
                      : l10n.viewMoreMapResults,
                ),
              ),
            ),
        ],
        const SizedBox(height: 18),
        _ActionGrid(
          selectedFacility: widget.selectedFacility,
          patientLocation: widget.facilitiesState?.patientLocation,
          onCallFacility: () => _callFacility(widget.selectedFacility),
          onWhatsApp: () => launchWhatsAppHelp(context),
          onTransport: () => ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.transportRequestQueued))),
        ),
        const SizedBox(height: 12),
        const UssdAccessCard(compact: true),
        const SizedBox(height: 12),
        const FollowUpPrompt(compact: true),
        const SizedBox(height: 12),
        const CareSupportBlock(compact: true),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final stackActions = widget.compact || constraints.maxWidth < 380;
            final backButton = RepairOutlinedButton(
              label: l10n.triageBack,
              onPressed: () => context.pop(),
            );
            final primaryButton = RepairPrimaryButton(
              label: _primaryLabel(l10n, widget.referral.status),
              icon: Icons.send,
              onPressed: widget.selectedFacility == null
                  ? null
                  : () => _advanceReferral(context, ref),
            );

            if (stackActions) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  primaryButton,
                  const SizedBox(height: 10),
                  backButton,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: backButton),
                const SizedBox(width: 12),
                Expanded(child: primaryButton),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        TextButton.icon(
          onPressed: () => context.push('/history'),
          icon: const Icon(Icons.timeline),
          label: Text(l10n.viewReportsTimeline),
        ),
      ],
    );
  }

  String _primaryLabel(AppLocalizations l10n, ReferralUiStatus status) {
    switch (status) {
      case ReferralUiStatus.sent:
        return l10n.markAccepted;
      case ReferralUiStatus.accepted:
        return l10n.markCompleted;
      case ReferralUiStatus.completed:
        return l10n.completed;
      case ReferralUiStatus.cancelled:
        return l10n.restartReferral;
      case ReferralUiStatus.draft:
      case ReferralUiStatus.recommended:
        return l10n.sendReferral;
    }
  }

  Future<void> _advanceReferral(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(referralStateProvider.notifier);
    final status = ref.read(referralStateProvider).status;
    switch (status) {
      case ReferralUiStatus.sent:
        notifier.accept();
        break;
      case ReferralUiStatus.accepted:
        notifier.complete();
        break;
      case ReferralUiStatus.completed:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.referralAlreadyCompleted)));
        return;
      case ReferralUiStatus.cancelled:
      case ReferralUiStatus.draft:
      case ReferralUiStatus.recommended:
        final triageId = ref.read(triageResultProvider)?.backendTriageId;
        if (triageId != null) {
          try {
            await ref.read(referralApiProvider).generate(triageId: triageId);
          } on ApiException catch (error) {
            messenger.showSnackBar(SnackBar(content: Text(error.message)));
            return;
          } catch (_) {
            messenger.showSnackBar(
              SnackBar(content: Text(l10n.facilitiesLoadError)),
            );
            return;
          }
        }
        notifier.send();
        break;
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.referralStatusUpdated)));
  }

  Future<void> _callFacility(ReferralFacility? facility) async {
    final phone = facility?.phone;
    if (phone == null) {
      await launchEmergencyCall();
      return;
    }
    await launchPhoneNumber(phone);
  }

  Future<void> _openDirections(
    ReferralFacility facility,
    LatLng? patientLocation,
  ) async {
    final point = facility.point;
    if (point == null) return;
    await launchFacilityDirections(
      latitude: point.latitude,
      longitude: point.longitude,
      fromLatitude: patientLocation?.latitude,
      fromLongitude: patientLocation?.longitude,
    );
  }
}

/// A compact facility list replacing the map view for stability.
class _FacilityListCard extends StatelessWidget {
  const _FacilityListCard({
    required this.facilities,
    required this.selectedFacility,
    this.patientLocation,
  });

  final List<ReferralFacility> facilities;
  final ReferralFacility? selectedFacility;
  final LatLng? patientLocation;

  @override
  Widget build(BuildContext context) {
    if (facilities.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.08)),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_hospital_outlined,
                  size: 36, color: AppTheme.primary.withValues(alpha: 0.3)),
              const SizedBox(height: 8),
              Text('No nearby facilities found',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.primary.withValues(alpha: 0.5))),
            ],
          ),
        ),
      );
    }

    final sorted = List<ReferralFacility>.from(facilities)
      ..sort((a, b) => (a.distanceKm ?? double.infinity)
          .compareTo(b.distanceKm ?? double.infinity));

    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.primary.withValues(alpha: 0.02),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: AppTheme.primary.withValues(alpha: 0.08))),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_hospital_outlined,
                    size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text('Nearby Facilities (${sorted.length})',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: sorted.length.clamp(0, 5),
              separatorBuilder: (_, __) => Divider(
                  height: 1, color: AppTheme.primary.withValues(alpha: 0.05)),
              itemBuilder: (context, index) {
                final f = sorted[index];
                final isSelected = f.id == selectedFacility?.id;
                return ListTile(
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: isSelected
                        ? AppTheme.primary.withValues(alpha: 0.12)
                        : AppTheme.success.withValues(alpha: 0.1),
                    child: Icon(
                      isSelected
                          ? Icons.local_hospital
                          : Icons.local_hospital_outlined,
                      size: 18,
                      color: isSelected ? AppTheme.primary : AppTheme.success,
                    ),
                  ),
                  title: Text(f.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w600)),
                  subtitle: Row(children: [
                    if (f.distanceKm != null)
                      Text('${f.distanceKm!.toStringAsFixed(1)} km',
                          style: const TextStyle(fontSize: 11)),
                    if (f.distanceKm != null && f.level.isNotEmpty)
                      const Text(' • ', style: TextStyle(fontSize: 11)),
                    if (f.level.isNotEmpty)
                      Text(f.level, style: const TextStyle(fontSize: 11)),
                  ]),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    if (f.hasUltrasound)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.pregnant_woman,
                            size: 14, color: AppTheme.accent),
                      ),
                    if (f.hasBloodBank)
                      const Icon(Icons.bloodtype,
                          size: 14, color: AppTheme.error),
                  ]),
                  dense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({
    required this.title,
    required this.verifiedCount,
    required this.mapCount,
  });

  final String title;
  final int verifiedCount;
  final int mapCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Chip(
              label: l10n.verifiedFacilitiesCount(verifiedCount),
              color: AppTheme.primary,
            ),
            _Chip(
              label: l10n.mapResultsCount(mapCount),
              color: AppTheme.success,
            ),
          ],
        ),
      ],
    );
  }
}

class _AncReferralNotice extends StatelessWidget {
  const _AncReferralNotice({required this.title, required this.flags});

  final String title;
  final List<dynamic> flags;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.warning.withValues(alpha: 0.10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.assignment_turned_in_outlined,
                  color: AppTheme.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final flag in flags.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• ${flag.label}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.icon,
    required this.color,
  }) : compact = false;

  final IconData icon;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: compact ? 22 : 30),
    );
  }
}

class _MapAttribution extends StatelessWidget {
  const _MapAttribution({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(text, style: Theme.of(context).textTheme.labelSmall),
        ),
      ),
    );
  }
}

class _UrgentReferralBanner extends StatelessWidget {
  const _UrgentReferralBanner({required this.text, required this.onCall});

  final String text;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.12),
        border: Border.all(color: AppTheme.error),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.priority_high, color: AppTheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.error,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: onCall,
            icon: const Icon(Icons.phone, color: AppTheme.error),
            tooltip: AppLocalizations.of(context).callEmergency,
          ),
        ],
      ),
    );
  }
}

class _ReferralStatusCard extends StatelessWidget {
  const _ReferralStatusCard({
    required this.status,
    required this.facilityName,
    required this.l10n,
  });

  final ReferralUiStatus status;
  final String facilityName;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ReferralUiStatus.sent => AppTheme.warning,
      ReferralUiStatus.accepted => AppTheme.primary,
      ReferralUiStatus.completed => AppTheme.success,
      ReferralUiStatus.cancelled => AppTheme.error,
      _ => AppTheme.primary,
    };
    final label = switch (status) {
      ReferralUiStatus.draft => l10n.referralDraft,
      ReferralUiStatus.recommended => l10n.facilityRecommended,
      ReferralUiStatus.sent => l10n.referralSentStatus,
      ReferralUiStatus.accepted => l10n.facilityAccepted,
      ReferralUiStatus.completed => l10n.careCompleted,
      ReferralUiStatus.cancelled => l10n.referralCancelled,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.16),
              child: Icon(Icons.route, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    facilityName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FacilityCard extends StatelessWidget {
  const _FacilityCard({
    required this.facility,
    required this.selected,
    required this.recommended,
    required this.onTap,
    required this.onDirections,
  });

  final ReferralFacility facility;
  final bool selected;
  final bool recommended;
  final VoidCallback onTap;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final borderColor = selected ? AppTheme.primary : Colors.transparent;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: selected ? AppTheme.primary.withValues(alpha: 0.06) : null,
      elevation: selected ? 3 : 1,
      shadowColor: selected ? AppTheme.primary.withValues(alpha: 0.18) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected
              ? AppTheme.primary
              : AppTheme.primary.withValues(alpha: 0.1),
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    recommended
                        ? Icons.local_hospital
                        : Icons.local_hospital_outlined,
                    color: selected ? AppTheme.primary : AppTheme.warning,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      facility.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (selected)
                    const Icon(Icons.check_circle, color: AppTheme.primary),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                [
                  if (facility.level.isNotEmpty) facility.level,
                  if (facility.subCounty.isNotEmpty) facility.subCounty,
                  if (facility.county.isNotEmpty) facility.county,
                  if (facility.distanceKm != null)
                    '${facility.distanceKm!.toStringAsFixed(1)} km',
                ].join(' • '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(label: l10n.verifiedFacility, color: AppTheme.success),
                  if (facility.hasUltrasound)
                    _Chip(label: l10n.facilityChipUltrasound),
                  if (facility.hasBloodBank)
                    _Chip(label: l10n.facilityChipBloodBank),
                  if (facility.bedsAvailable != null)
                    _Chip(label: '${facility.bedsAvailable} beds'),
                  if (facility.staffOnDuty != null)
                    _Chip(label: '${facility.staffOnDuty} staff'),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: facility.point == null ? null : onDirections,
                  icon: const Icon(Icons.directions),
                  label: Text(l10n.openFacilityDirections),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapFacilityCard extends StatelessWidget {
  const _MapFacilityCard({required this.facility});

  final ReferralFacility facility;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.add_location_alt_outlined,
                  color: AppTheme.success,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    facility.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              [
                if (facility.level.isNotEmpty) facility.level,
                if (facility.distanceKm != null)
                  '${facility.distanceKm!.toStringAsFixed(1)} km',
              ].join(' • '),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Chip(label: l10n.unverifiedMapResult, color: AppTheme.warning),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: facility.point == null
                    ? null
                    : () => launchFacilityDirections(
                          latitude: facility.point!.latitude,
                          longitude: facility.point!.longitude,
                        ),
                icon: const Icon(Icons.directions),
                label: Text(l10n.openFacilityDirections),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.color = AppTheme.primary});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({
    required this.selectedFacility,
    required this.patientLocation,
    required this.onCallFacility,
    required this.onWhatsApp,
    required this.onTransport,
  });

  final ReferralFacility? selectedFacility;
  final LatLng? patientLocation;
  final VoidCallback onCallFacility;
  final VoidCallback onWhatsApp;
  final VoidCallback onTransport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
        return GridView.count(
          crossAxisCount: compact ? 1 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: compact ? 4.3 : 2.25,
          children: [
            _ActionTile(Icons.phone, l10n.callEmergency, onCallFacility),
            _ActionTile(
              Icons.directions,
              l10n.openInMaps,
              selectedFacility?.point == null
                  ? null
                  : () => launchFacilityDirections(
                        latitude: selectedFacility!.point!.latitude,
                        longitude: selectedFacility!.point!.longitude,
                        fromLatitude: patientLocation?.latitude,
                        fromLongitude: patientLocation?.longitude,
                      ),
            ),
            _ActionTile(Icons.chat, l10n.whatsApp, onWhatsApp),
            _ActionTile(Icons.local_taxi, l10n.transport, onTransport),
          ],
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapLoadingCard extends StatelessWidget {
  const _MapLoadingCard();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mapSize = constraints.maxWidth.clamp(280.0, 520.0);
        return Container(
          height: mapSize,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class _FacilityLoadingList extends StatelessWidget {
  const _FacilityLoadingList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          height: 86,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _EmptyFacilitiesCard extends StatelessWidget {
  const _EmptyFacilitiesCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.local_hospital_outlined, color: AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
