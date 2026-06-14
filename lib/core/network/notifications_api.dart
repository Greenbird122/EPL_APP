import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Minimal notifications API abstraction used by [NotificationsScreen].
///
/// The app has a centralized backend layer (see `backend_services.dart` and
/// `api_client.dart`). During recent refactors the provider wiring for
/// notifications was missing, so we keep this small wrapper here.
abstract class NotificationsApi {
  Future<List<Map<String, dynamic>>> list();
}

/// Provider used by the notifications UI.
///
/// Replace the implementation with the real backend call when available.
/// For now this returns an empty list to keep the UI compiling.
final notificationApiProvider = Provider<NotificationsApi>((ref) {
  return _FakeNotificationsApi();
});

class _FakeNotificationsApi implements NotificationsApi {
  @override
  Future<List<Map<String, dynamic>>> list() async {
    return const [];
  }
}

