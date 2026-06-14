import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_ai/features/triage/domain/case_model.dart';

/// Holds the list of triage cases for the current user.
final triageCaseProvider =
    StateNotifierProvider.autoDispose<TriageCaseNotifier, List<TriageCase>>(
        (ref) {
  return TriageCaseNotifier();
});

/// Derives live analytics from the current case list.
final triageAnalyticsProvider = Provider<TriageAnalytics>((ref) {
  final cases = ref.watch(triageCaseProvider);
  return TriageAnalytics.fromCases(cases);
});

/// Count of non-completed cases (active + analyzing + referred) for the
/// notification badge.
final triageActiveCaseCountProvider = Provider<int>((ref) {
  final cases = ref.watch(triageCaseProvider);
  return cases
      .where((c) => c.isOpen || c.status == TriageCaseStatus.referred)
      .length;
});

class TriageCaseNotifier extends StateNotifier<List<TriageCase>> {
  TriageCaseNotifier() : super([]);

  /// Replaces the entire case list.
  void setCases(List<TriageCase> cases) {
    state = List.unmodifiable(cases);
  }

  /// Adds a single case.
  void addCase(TriageCase triageCase) {
    state = List.unmodifiable([...state, triageCase]);
  }

  /// Updates an existing case by id (no-op if not found).
  void updateCase(TriageCase updated) {
    state = List.unmodifiable(
      state.map((c) => c.id == updated.id ? updated : c).toList(),
    );
  }

  /// Removes a case by id.
  void removeCase(String id) {
    state = List.unmodifiable(state.where((c) => c.id != id).toList());
  }
}
