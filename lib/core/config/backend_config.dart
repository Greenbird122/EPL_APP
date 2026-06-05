class BackendConfig {
  const BackendConfig._();

  static const String defaultBaseUrl = String.fromEnvironment(
    'REPAIR_AI_API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const Duration requestTimeout = Duration(seconds: 4);

  static const String mapTileUrl = String.fromEnvironment(
    'REPAIR_AI_MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  static bool get usesLocalBackend {
    final value = defaultBaseUrl.toLowerCase();
    return value.contains('localhost') ||
        value.contains('127.0.0.1') ||
        value.contains('10.0.2.2');
  }

  static String get apkBuildCommandHint =>
      'flutter build apk --release --dart-define=REPAIR_AI_API_BASE_URL=https://<confirmed-backend-domain>';
}
