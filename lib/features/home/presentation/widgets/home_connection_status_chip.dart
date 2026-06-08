import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repair_ai/core/config/themes.dart';
import 'package:repair_ai/core/network/backend_heartbeat_provider.dart';
import 'package:repair_ai/localization/app_localizations.dart';

class HomeConnectionStatusChip extends ConsumerStatefulWidget {
  const HomeConnectionStatusChip({super.key});

  @override
  ConsumerState<HomeConnectionStatusChip> createState() =>
      _HomeConnectionStatusChipState();
}

class _HomeConnectionStatusChipState
    extends ConsumerState<HomeConnectionStatusChip> {
  BackendHeartbeatState? _visibleState;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _showTemporarily(BackendHeartbeatState state) {
    _hideTimer?.cancel();
    setState(() => _visibleState = state);
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _visibleState = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<BackendHeartbeatState>(backendHeartbeatProvider, (
      previous,
      next,
    ) {
      if (next == BackendHeartbeatState.checking) return;
      if (previous == next && _visibleState != null) return;
      _showTemporarily(next);
    });

    final state = _visibleState;
    if (state == null || state == BackendHeartbeatState.checking) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final online = state == BackendHeartbeatState.online;
    final color = online ? AppTheme.success : AppTheme.error;
    final label = online ? l10n.onlineStatus : l10n.noInternetConnection;
    final icon = online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Align(
        key: ValueKey(state),
        alignment: Alignment.centerLeft,
        child: Chip(
          avatar: Icon(icon, size: 16, color: color),
          label: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.90),
          side: BorderSide(color: color.withValues(alpha: 0.32)),
        ),
      ),
    );
  }
}
