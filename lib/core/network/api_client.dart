import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:repair_ai/core/config/backend_config.dart';
import 'package:repair_ai/core/network/secure_token_store.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient({
    http.Client? client,
    SecureTokenStore? tokenStore,
    String? baseUrl,
  })  : _client = client ?? http.Client(),
        _tokenStore = tokenStore ?? SecureTokenStore(),
        _baseUrl = (baseUrl ?? BackendConfig.defaultBaseUrl).replaceAll(
          RegExp(r'/$'),
          '',
        );

  final http.Client _client;
  final SecureTokenStore _tokenStore;
  final String _baseUrl;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$normalPath').replace(
      queryParameters: query?.map((key, value) => MapEntry(key, '$value')),
    );
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    bool authenticated = true,
  }) async {
    return _sendWithRefresh(
      authenticated: authenticated,
      request: (headers) => _client.get(
        _uri(path, query),
        headers: headers,
      ),
    );
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    return _sendWithRefresh(
      authenticated: authenticated,
      request: (headers) => _client.post(
        _uri(path),
        headers: headers,
        body: jsonEncode(body ?? <String, dynamic>{}),
      ),
    );
  }

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    return _sendWithRefresh(
      authenticated: authenticated,
      request: (headers) => _client.patch(
        _uri(path),
        headers: headers,
        body: jsonEncode(body ?? <String, dynamic>{}),
      ),
    );
  }

  Future<dynamic> multipartPost(
    String path, {
    required Map<String, String> fields,
    required String fileField,
    required String fileName,
    required Uint8List fileBytes,
    bool authenticated = true,
  }) async {
    return _sendWithRefresh(
      authenticated: authenticated,
      request: (headers) async {
        final request = http.MultipartRequest('POST', _uri(path))
          ..fields.addAll(fields)
          ..files.add(
            http.MultipartFile.fromBytes(
              fileField,
              fileBytes,
              filename: fileName,
            ),
          );
        request.headers.addAll(headers..remove('Content-Type'));
        final streamed = await _client.send(request);
        return http.Response.fromStream(streamed);
      },
    );
  }

  Map<String, String> _headers({required bool authenticated}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<Map<String, String>> _authorizedHeaders() async {
    final token = await _tokenStore.readAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> _send(
    Future<http.Response> Function() request,
  ) async {
    late final http.Response response;
    try {
      response = await request().timeout(BackendConfig.requestTimeout);
    } on TimeoutException {
      throw const ApiException(
        'The backend took too long to respond. Please try again.',
      );
    } on http.ClientException catch (error) {
      throw ApiException(
        'Could not connect to the backend. ${error.message}',
      );
    } catch (error) {
      throw ApiException('Could not reach the backend. $error');
    }

    final body = response.body.isEmpty ? null : jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = body is Map<String, dynamic>
        ? _errorMessage(body, response.statusCode)
        : _statusMessage(response.statusCode);
    throw ApiException(message, statusCode: response.statusCode);
  }

  Future<dynamic> _sendWithRefresh({
    required bool authenticated,
    required Future<http.Response> Function(Map<String, String> headers)
        request,
  }) async {
    try {
      return await _send(
        () async => request(
          authenticated
              ? await _authorizedHeaders()
              : _headers(authenticated: false),
        ),
      );
    } on ApiException catch (error) {
      if (!authenticated || error.statusCode != 401) rethrow;
      final refreshed = await _refreshAccessToken();
      if (!refreshed) rethrow;
      return _send(
        () async => request(await _authorizedHeaders()),
      );
    }
  }

  Future<bool> _refreshAccessToken() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken == null) return false;
    try {
      final response = await _client
          .post(
            _uri('/api/auth/refresh/'),
            headers: _headers(authenticated: false),
            body: jsonEncode({'refresh': refreshToken}),
          )
          .timeout(BackendConfig.requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final access = body['access'] as String?;
      if (access == null) return false;
      await _tokenStore.saveAccessToken(access);
      return true;
    } catch (_) {
      return false;
    }
  }

  String _errorMessage(Map<String, dynamic> body, int statusCode) {
    final primary = body['detail'] ?? body['message'];
    if (primary != null) return primary.toString();

    final fieldErrors = body.entries
        .map((entry) {
          final value = entry.value;
          if (value is List && value.isNotEmpty) {
            return '${entry.key}: ${value.first}';
          }
          if (value is String && value.isNotEmpty) {
            return '${entry.key}: $value';
          }
          return null;
        })
        .whereType<String>()
        .toList();

    return fieldErrors.isEmpty
        ? _statusMessage(statusCode)
        : fieldErrors.join('\n');
  }

  String _statusMessage(int statusCode) {
    return switch (statusCode) {
      400 => 'The request was not accepted. Check the details and try again.',
      401 => 'Your username or password was not accepted.',
      403 => 'You do not have permission to access this feature.',
      404 => 'The backend endpoint was not found.',
      >= 500 => 'The backend had a server error. Please try again shortly.',
      _ => 'Request failed with status $statusCode.',
    };
  }

  Future<dynamic> authorizedGet(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    return get(
      path,
      query: query,
    );
  }

  Future<dynamic> authorizedPost(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return post(
      path,
      body: body,
    );
  }

  Future<dynamic> authorizedPatch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    return patch(
      path,
      body: body,
    );
  }
}
