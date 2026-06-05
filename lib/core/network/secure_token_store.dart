import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenPair {
  const SecureTokenPair({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;
}

class SecureTokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessKey = 'repair_ai_access_token';
  static const _refreshKey = 'repair_ai_refresh_token';
  static SecureTokenPair? _memoryTokenPair;

  Future<SecureTokenPair?> read() async {
    if (_memoryTokenPair != null) return _memoryTokenPair;
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    if (access == null || refresh == null) return null;
    return SecureTokenPair(accessToken: access, refreshToken: refresh);
  }

  Future<String?> readAccessToken() async =>
      _memoryTokenPair?.accessToken ?? await _storage.read(key: _accessKey);

  Future<String?> readRefreshToken() async =>
      _memoryTokenPair?.refreshToken ?? await _storage.read(key: _refreshKey);

  Future<void> save({
    required String accessToken,
    required String refreshToken,
    bool remember = true,
  }) async {
    _memoryTokenPair = SecureTokenPair(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    if (!remember) {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
      return;
    }
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  Future<void> saveAccessToken(String accessToken) async {
    final current = await read();
    if (current == null) return;
    _memoryTokenPair = SecureTokenPair(
      accessToken: accessToken,
      refreshToken: current.refreshToken,
    );
    final persistedRefresh = await _storage.read(key: _refreshKey);
    if (persistedRefresh != null) {
      await _storage.write(key: _accessKey, value: accessToken);
    }
  }

  Future<void> clear() async {
    _memoryTokenPair = null;
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
