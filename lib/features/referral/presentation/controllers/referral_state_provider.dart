import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ReferralUiStatus {
  draft,
  recommended,
  sent,
  accepted,
  completed,
  cancelled,
}

class FacilityOption {
  const FacilityOption({
    required this.name,
    required this.distance,
    required this.eta,
    required this.capabilities,
    this.isRecommended = false,
  });

  final String name;
  final String distance;
  final String eta;
  final List<String> capabilities;
  final bool isRecommended;
}

class ReferralState {
  const ReferralState({
    this.status = ReferralUiStatus.recommended,
    this.selectedFacility = 0,
  });

  final ReferralUiStatus status;
  final int selectedFacility;

  ReferralState copyWith({
    ReferralUiStatus? status,
    int? selectedFacility,
  }) {
    return ReferralState(
      status: status ?? this.status,
      selectedFacility: selectedFacility ?? this.selectedFacility,
    );
  }
}

class ReferralStateNotifier extends StateNotifier<ReferralState> {
  ReferralStateNotifier() : super(const ReferralState());

  void selectFacility(int index) {
    state = state.copyWith(
      selectedFacility: index,
      status: ReferralUiStatus.recommended,
    );
  }

  void send() {
    state = state.copyWith(status: ReferralUiStatus.sent);
  }

  void accept() {
    state = state.copyWith(status: ReferralUiStatus.accepted);
  }

  void complete() {
    state = state.copyWith(status: ReferralUiStatus.completed);
  }

  void cancel() {
    state = state.copyWith(status: ReferralUiStatus.cancelled);
  }
}

final referralStateProvider =
    StateNotifierProvider<ReferralStateNotifier, ReferralState>((ref) {
  return ReferralStateNotifier();
});

const facilityOptions = [
  FacilityOption(
    name: 'Bungoma County Referral Hospital',
    distance: '12.4 km',
    eta: '28 min',
    capabilities: ['24/7', 'Ultrasound', 'Blood bank'],
    isRecommended: true,
  ),
  FacilityOption(
    name: 'Webuye County Hospital',
    distance: '18.7 km',
    eta: '45 min',
    capabilities: ['Maternity', 'Lab', 'Ambulance'],
  ),
  FacilityOption(
    name: 'Kimilili Sub-County Hospital',
    distance: '23.1 km',
    eta: '52 min',
    capabilities: ['Maternity', 'Pharmacy', 'CHP desk'],
  ),
];
