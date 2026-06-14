import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_ai/core/network/backend_services.dart';
import 'package:repair_ai/features/anc/data/anc_profile_repository.dart';
import 'package:repair_ai/features/anc/domain/anc_profile.dart';
import 'package:repair_ai/features/auth/presentation/controllers/auth_session_provider.dart';

final ancProfileRepositoryProvider = Provider<AncProfileRepository>((ref) {
  return AncProfileRepository(ref.watch(ancProfileApiProvider));
});

/// Primary ANC profile provider - uses authenticated patient ID
final ancProfileProvider = FutureProvider.autoDispose<AncProfile?>((ref) async {
  // Get authenticated patient ID from session
  final authSession = ref.watch(authSessionProvider);

  // Only fetch for authenticated patients with patient ID
  if (authSession.status != AuthSessionStatus.patient ||
      authSession.patientId == null) {
    return null;
  }

  final patientId = authSession.patientId!.toString();
  return ref.watch(ancProfileRepositoryProvider).fetchProfile(patientId);
});

/// Legacy family provider for specific patient IDs (used by CHP/provider views)
final ancProfileByIdProvider =
    FutureProvider.family.autoDispose<AncProfile?, String>((
  ref,
  patientId,
) async {
  return ref.watch(ancProfileRepositoryProvider).fetchProfile(patientId);
});

class AncProfileSaveController extends StateNotifier<AsyncValue<void>> {
  AncProfileSaveController(this._repository)
      : super(const AsyncValue.data(null));

  final AncProfileRepository _repository;

  Future<void> save(AncProfile profile) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.saveProfile(profile));
  }
}

final ancProfileSaveControllerProvider =
    StateNotifierProvider<AncProfileSaveController, AsyncValue<void>>((ref) {
  return AncProfileSaveController(ref.watch(ancProfileRepositoryProvider));
});
