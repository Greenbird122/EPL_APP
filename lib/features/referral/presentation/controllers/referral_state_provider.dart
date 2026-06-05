import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ReferralUiStatus {
  draft,
  recommended,
  sent,
  accepted,
  completed,
  cancelled,
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
