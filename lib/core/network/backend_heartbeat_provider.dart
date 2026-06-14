import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_ai/core/network/api_client.dart';
import 'package:repair_ai/core/network/backend_services.dart';

enum BackendHeartbeatState { checking, online, offline }

class BackendHeartbeatNotifier extends StateNotifier<BackendHeartbeatState> {
  BackendHeartbeatNotifier(this._ref) : super(BackendHeartbeatState.checking) {
    _check();
    _timer = Timer.periodic(const Duration(seconds: 12), (_) => _check());
  }

  final Ref _ref;
  Timer? _timer;

  Future<void> _check() async {
    try {
      await _ref.read(backendStatusApiProvider).heartbeat();
      if (mounted) state = BackendHeartbeatState.online;
    } on ApiException catch (e) {
      // A 4xx/5xx response means the server IS reachable — just the
      // health endpoint doesn't exist. Treat as online.
      if (mounted) {
        state = (e.statusCode != null && e.statusCode! >= 400)
            ? BackendHeartbeatState.online
            : BackendHeartbeatState.offline;
      }
    } catch (_) {
      if (mounted) state = BackendHeartbeatState.offline;
    }
  }

  Future<void> refreshNow() => _check();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final backendHeartbeatProvider =
    StateNotifierProvider<BackendHeartbeatNotifier, BackendHeartbeatState>(
      BackendHeartbeatNotifier.new,
    );
