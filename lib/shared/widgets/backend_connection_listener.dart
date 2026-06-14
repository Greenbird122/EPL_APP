import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/network/backend_heartbeat_provider.dart';

class BackendConnectionListener extends ConsumerStatefulWidget {
  const BackendConnectionListener({super.key});

  @override
  ConsumerState<BackendConnectionListener> createState() =>
      _BackendConnectionListenerState();
}

class _BackendConnectionListenerState
    extends ConsumerState<BackendConnectionListener> {
  bool _hasShownOffline = false;
  bool _initialCheckDone = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<BackendHeartbeatState>(backendHeartbeatProvider, (
      previous,
      next,
    ) {
      // Skip the initial "checking" state — don't show anything until first result
      if (!_initialCheckDone && next == BackendHeartbeatState.checking) return;
      _initialCheckDone = true;

      // Only show offline message when genuinely offline, not during checking
      if (next == BackendHeartbeatState.offline &&
          previous != BackendHeartbeatState.checking &&
          !_hasShownOffline) {
        _hasShownOffline = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Having trouble connecting. Your saved health info is still available.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
      if (previous == BackendHeartbeatState.offline &&
          next == BackendHeartbeatState.online) {
        ref.read(backendRestoredBannerProvider.notifier).show();
      }
    });

    return const SizedBox.shrink();
  }
}

class BackendRestoredBannerNotifier extends StateNotifier<bool> {
  BackendRestoredBannerNotifier() : super(false);

  Timer? _timer;

  void show() {
    state = true;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 4), () {
      if (mounted) state = false;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final backendRestoredBannerProvider =
    StateNotifierProvider<BackendRestoredBannerNotifier, bool>(
  (_) => BackendRestoredBannerNotifier(),
);

class BackendConnectionBar extends ConsumerWidget {
  const BackendConnectionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(backendRestoredBannerProvider);
    final top = MediaQuery.paddingOf(context).top + kToolbarHeight;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      left: 0,
      right: 0,
      top: visible ? top : top - 36,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: visible ? 1 : 0,
          child: const Material(
            color: AppTheme.success,
            elevation: 4,
            child: SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 7,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_done_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Connected. Your health info is up to date.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
