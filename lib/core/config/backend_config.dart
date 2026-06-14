class BackendConfig {
  const BackendConfig._();

  static const String defaultBaseUrl = String.fromEnvironment(
    'REPAIR_AI_API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  static const Duration requestTimeout = Duration(seconds: 8);

  static const String mapTileUrl = String.fromEnvironment(
    'REPAIR_AI_MAP_TILE_URL',
    defaultValue: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  );

  /// Mapbox access token for faster vector tile rendering.
  /// Leave empty to use the default OpenStreetMap raster tiles.
  static const String mapboxAccessToken = String.fromEnvironment(
    'REPAIR_AI_MAPBOX_TOKEN',
  );

  /// Returns the map tile URL with Mapbox token appended if configured.
  static String get effectiveMapTileUrl {
    if (mapboxAccessToken.isNotEmpty) {
      return 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token=$mapboxAccessToken';
    }
    return mapTileUrl;
  }

  static bool get usesLocalBackend {
    final value = defaultBaseUrl.toLowerCase();
    return value.contains('localhost') ||
        value.contains('127.0.0.1') ||
        value.contains('10.0.2.2');
  }

  static String get apkBuildCommandHint =>
      'flutter build apk --release --dart-define=REPAIR_AI_API_BASE_URL=https://<confirmed-backend-domain>';
}
