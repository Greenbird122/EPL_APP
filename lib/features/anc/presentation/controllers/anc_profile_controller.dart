import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_ai/features/anc/data/anc_profile_repository.dart';
import 'package:repair_ai/features/anc/domain/anc_profile.dart';

final ancProfileRepositoryProvider = Provider<AncProfileRepository>((ref) {
  return AncProfileRepository();
});

final ancProfileProvider = FutureProvider.family<AncProfile?, String>((
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
