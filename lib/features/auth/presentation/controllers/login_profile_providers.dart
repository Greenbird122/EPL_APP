import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileFormData {
  final String name;
  final String email;

  const ProfileFormData({required this.name, required this.email});
}

/// Holds the latest login/profile form values (mocked in this app).
/// This allows ProfileScreen to display the same data entered on LoginScreen.
final profileFormDataProvider = StateProvider<ProfileFormData?>((ref) => null);

final profileNameProvider = Provider<String?>((ref) {
  final data = ref.watch(profileFormDataProvider);
  return data?.name;
});

final profileEmailProvider = Provider<String?>((ref) {
  final data = ref.watch(profileFormDataProvider);
  return data?.email;
});

class CurrentPatientContext {
  const CurrentPatientContext({required this.id, required this.name});

  final int id;
  final String name;

  String get storageKey => '$id';
}

final currentPatientContextProvider = StateProvider<CurrentPatientContext?>(
  (ref) => null,
);
