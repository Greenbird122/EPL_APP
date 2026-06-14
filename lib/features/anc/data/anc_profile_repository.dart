import 'package:hive_flutter/hive_flutter.dart';
import 'package:repair_ai/core/network/backend_services.dart';
import 'package:repair_ai/features/anc/domain/anc_profile.dart';

class AncProfileRepository {
  const AncProfileRepository(this._api);

  final AncProfileApi _api;
  static const _boxName = 'anc_profiles';

  // TODO: Open the Hive box once at app startup and reuse the reference.
  // Currently _box() calls Hive.openBox() on every read/write which is
  // wasteful. Use a singleton pattern or a static Box reference initialized
  // during Hive.initFlutter() to avoid repeated open calls.
  Future<Box<dynamic>> _box() => Hive.openBox<dynamic>(_boxName);

  Future<AncProfile?> fetchProfile(String patientId) async {
    // Try fetching from backend first
    try {
      final data = await _api.fetch(int.parse(patientId));
      final profile = AncProfile.fromMap(data);

      // Cache locally
      final box = await _box();
      await box.put(patientId, profile.toMap());

      return profile;
    } catch (_) {
      // Fallback to local cache if backend fails
      final box = await _box();
      final cached = box.get(patientId);
      return cached == null ? null : AncProfile.fromMap(cached as Map);
    }
  }

  Future<void> saveProfile(AncProfile profile) async {
    // Save locally first (ensures data is not lost)
    final box = await _box();
    await box.put(profile.patientId, profile.toMap());

    // Sync to backend
    try {
      await _api.update(
        int.parse(profile.patientId),
        profile.toMap(),
      );
      // Clear dirty flag on successful sync
      await box.delete('${profile.patientId}_dirty');
    } catch (_) {
      // Mark as dirty for later sync (TODO: implement sync queue)
      await box.put('${profile.patientId}_dirty', true);
      rethrow;
    }
  }

  /// Check if there are any profiles pending sync
  Future<bool> hasDirtyProfiles() async {
    final box = await _box();
    final keys = box.keys.where((key) => key.toString().endsWith('_dirty'));
    return keys.isNotEmpty;
  }

  /// Get list of patient IDs with pending changes
  Future<List<String>> getDirtyPatientIds() async {
    final box = await _box();
    final keys = box.keys
        .where((key) => key.toString().endsWith('_dirty'))
        .map((key) => key.toString().replaceAll('_dirty', ''))
        .toList();
    return List<String>.from(keys);
  }
}
