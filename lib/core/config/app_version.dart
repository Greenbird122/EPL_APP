class AppVersion {
  const AppVersion._();

  /// Current app version. Bump this on every release.
  static const String current = '1.0.0';

  /// Compares two semver strings. Returns true if [latest] > [current].
  static bool isNewer(String latest, String current) {
    final latestParts =
        latest.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final currentParts =
        current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (var i = 0; i < 3; i++) {
      final l = i < latestParts.length ? latestParts[i] : 0;
      final c = i < currentParts.length ? currentParts[i] : 0;
      if (l > c) return true;
      if (l < c) return false;
    }
    return false;
  }
}
