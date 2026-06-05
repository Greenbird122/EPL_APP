import 'package:hive_flutter/hive_flutter.dart';
import 'package:repair_ai/features/anc/domain/anc_profile.dart';

class AncProfileRepository {
  static const _boxName = 'anc_profiles';

  Future<Box<dynamic>> _box() => Hive.openBox<dynamic>(_boxName);

  Future<AncProfile?> fetchProfile(String patientId) async {
    final box = await _box();
    final raw = box.get(patientId);
    if (raw is Map) return AncProfile.fromMap(raw);
    return null;
  }

  Future<void> saveProfile(AncProfile profile) async {
    final box = await _box();
    await box.put(profile.patientId, profile.toMap());
  }
}
