import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:repair_ai/core/config/backend_config.dart';
import 'package:repair_ai/core/config/app_version.dart';

enum UpdateStatus { unknown, upToDate, updateAvailable, checking }

class UpdateState {
  final UpdateStatus status;
  final String? latestVersion;
  final String? releaseUrl;

  const UpdateState({
    required this.status,
    this.latestVersion,
    this.releaseUrl,
  });
}

class UpdateCheckNotifier extends StateNotifier<UpdateState> {
  UpdateCheckNotifier()
      : super(const UpdateState(status: UpdateStatus.unknown));

  static const _prefsKey = 'last_update_check';
  static const _laterKey = 'update_later_until';
  static const _checkInterval = Duration(hours: 48);

  /// Returns true if we should show the update dialog.
  bool get shouldShowDialog => state.status == UpdateStatus.updateAvailable;

  /// Checks for updates. Call on app launch and when coming online.
  Future<void> checkForUpdate() async {
    // Don't re-check if already checking or we know there's an update.
    if (state.status == UpdateStatus.checking ||
        state.status == UpdateStatus.updateAvailable) {
      return;
    }

    // Check 48-hour cooldown for "Later" dismissal.
    final prefs = await SharedPreferences.getInstance();
    final laterUntil = prefs.getString(_laterKey);
    if (laterUntil != null) {
      final until = DateTime.tryParse(laterUntil);
      if (until != null && DateTime.now().isBefore(until)) return;
    }

    state = const UpdateState(status: UpdateStatus.checking);

    try {
      // Try GitHub directly first (no auth needed for public repos).
      String? version;
      String? url;

      try {
        final response = await http.get(
          Uri.parse(
              'https://api.github.com/repos/Greenbird122/EPL_APP/releases/latest'),
          headers: {'Accept': 'application/vnd.github.v3+json'},
        ).timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          version = data['tag_name']?.toString().replaceAll('v', '');
          url = data['html_url']?.toString();
        }
      } catch (_) {
        // GitHub direct failed — try backend proxy if configured.
        const baseUrl = BackendConfig.defaultBaseUrl;
        if (!baseUrl.contains('localhost') && !baseUrl.contains('127.0.0.1')) {
          try {
            final response = await http
                .get(Uri.parse('$baseUrl/api/app-version/'))
                .timeout(const Duration(seconds: 5));
            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              version = data['latest_version']?.toString();
              url = data['release_url']?.toString();
            }
          } catch (_) {}
        }
      }

      await prefs.setString(_prefsKey, DateTime.now().toIso8601String());

      if (version != null && AppVersion.isNewer(version, AppVersion.current)) {
        state = UpdateState(
          status: UpdateStatus.updateAvailable,
          latestVersion: version,
          releaseUrl: url,
        );
      } else {
        state = const UpdateState(status: UpdateStatus.upToDate);
      }
    } catch (_) {
      state = const UpdateState(status: UpdateStatus.unknown);
    }
  }

  /// User tapped "Later" — don't prompt for 48 hours.
  Future<void> dismissLater() async {
    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now().add(_checkInterval);
    await prefs.setString(_laterKey, until.toIso8601String());
    state = const UpdateState(status: UpdateStatus.upToDate);
  }

  /// User tapped "Update" — dismiss and open URL.
  void dismissUpdate() {
    state = const UpdateState(status: UpdateStatus.upToDate);
  }
}

final updateCheckProvider =
    StateNotifierProvider<UpdateCheckNotifier, UpdateState>((ref) {
  return UpdateCheckNotifier();
});
