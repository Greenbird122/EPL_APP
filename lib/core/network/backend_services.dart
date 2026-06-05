import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';

import 'package:repair_ai/core/network/api_client.dart';
import 'package:repair_ai/core/network/secure_token_store.dart';

final secureTokenStoreProvider = Provider<SecureTokenStore>((ref) {
  return SecureTokenStore();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenStore: ref.watch(secureTokenStoreProvider));
});

final authApiProvider = Provider<AuthApi>((ref) =>
    AuthApi(ref.watch(apiClientProvider), ref.watch(secureTokenStoreProvider)));
final patientApiProvider =
    Provider<PatientApi>((ref) => PatientApi(ref.watch(apiClientProvider)));
final visitApiProvider =
    Provider<VisitApi>((ref) => VisitApi(ref.watch(apiClientProvider)));
final triageApiProvider =
    Provider<TriageApi>((ref) => TriageApi(ref.watch(apiClientProvider)));
final referralApiProvider =
    Provider<ReferralApi>((ref) => ReferralApi(ref.watch(apiClientProvider)));
final facilityApiProvider =
    Provider<FacilityApi>((ref) => FacilityApi(ref.watch(apiClientProvider)));
final followUpApiProvider =
    Provider<FollowUpApi>((ref) => FollowUpApi(ref.watch(apiClientProvider)));
final clinicalApiProvider =
    Provider<ClinicalApi>((ref) => ClinicalApi(ref.watch(apiClientProvider)));
final transcriptionApiProvider = Provider<TranscriptionApi>(
    (ref) => TranscriptionApi(ref.watch(apiClientProvider)));
final backendStatusApiProvider = Provider<BackendStatusApi>(
    (ref) => BackendStatusApi(ref.watch(apiClientProvider)));
final ancProfileApiProvider = Provider<AncProfileApi>(
    (ref) => AncProfileApi(ref.watch(apiClientProvider)));

enum BackendConnectionState {
  unknown,
  online,
  offline,
}

class AuthApi {
  const AuthApi(this._client, this._tokenStore);

  final ApiClient _client;
  final SecureTokenStore _tokenStore;

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    bool rememberMe = true,
  }) async {
    final data = await _client.post(
      '/api/auth/login/',
      authenticated: false,
      body: {'username': username, 'password': password},
    ) as Map<String, dynamic>;
    final access = data['access'] as String?;
    final refresh = data['refresh'] as String?;
    if (access != null && refresh != null) {
      await _tokenStore.save(
        accessToken: access,
        refreshToken: refresh,
        remember: rememberMe,
      );
    }
    return data;
  }

  Future<Map<String, dynamic>> refresh({
    required String refreshToken,
  }) async {
    final data = await _client.post(
      '/api/auth/refresh/',
      authenticated: false,
      body: {'refresh': refreshToken},
    ) as Map<String, dynamic>;
    final access = data['access'] as String?;
    if (access != null) {
      await _tokenStore.saveAccessToken(access);
    }
    return data;
  }

  Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    return await _client.post(
      '/api/auth/change-password/',
      body: {
        'old_password': oldPassword,
        'new_password': newPassword,
        'new_password_confirm': confirmPassword,
      },
    ) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> registerPatient(
      Map<String, dynamic> body) async {
    return await _client.post(
      '/api/auth/register/',
      authenticated: false,
      body: {...body, 'role': 'patient'},
    ) as Map<String, dynamic>;
  }

  Future<void> logout() => _tokenStore.clear();

  Future<Map<String, dynamic>> profile() async {
    return await _client.get('/api/auth/profile/') as Map<String, dynamic>;
  }
}

class PatientApi {
  const PatientApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> myProfile() async {
    return await _client.get('/api/patients/my-profile/')
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updatePatient(
    int patientId,
    Map<String, dynamic> body,
  ) async {
    return await _client.patch('/api/patients/$patientId/', body: body)
        as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> patients({
    Map<String, dynamic>? query,
  }) async {
    return _asList(await _client.get('/api/patients/', query: query));
  }
}

class AncProfileApi {
  const AncProfileApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> fetch(int patientId) async {
    return await _client.get('/api/patients/$patientId/anc-profile/')
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> update(
    int patientId,
    Map<String, dynamic> body,
  ) async {
    return await _client.patch(
      '/api/patients/$patientId/anc-profile/',
      body: body,
    ) as Map<String, dynamic>;
  }
}

class VisitApi {
  const VisitApi(this._client);

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> visits({int? patientId}) async {
    return _asList(
      await _client.get(
        '/api/patients/visits/',
        query: patientId == null ? null : {'patient': patientId},
      ),
    );
  }

  Future<Map<String, dynamic>> createVisit(Map<String, dynamic> body) async {
    return await _client.post('/api/patients/visits/', body: body)
        as Map<String, dynamic>;
  }
}

class TriageApi {
  const TriageApi(this._client);

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> results({int? patientId}) async {
    return _asList(
      await _client.get(
        '/api/triage/',
        query: patientId == null ? null : {'visit__patient': patientId},
      ),
    );
  }

  Future<Map<String, dynamic>> runTriage(int visitId) async {
    return await _client.post('/api/triage/run/', body: {'visit_id': visitId})
        as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deepseekAnalyze(
    Map<String, dynamic> payload,
  ) async {
    return await _client.post(
      '/api/triage/deepseek-analyze/',
      body: payload,
    ) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> transcribeAudio({
    required Uint8List fileBytes,
    required String fileName,
    String language = 'en-KE',
  }) async {
    return await _client.multipartPost(
      '/api/triage/transcribe/',
      fields: {'language': language},
      fileField: 'audio',
      fileName: fileName,
      fileBytes: fileBytes,
    ) as Map<String, dynamic>;
  }
}

class ReferralApi {
  const ReferralApi(this._client);

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> referrals({int? patientId}) async {
    return _asList(
      await _client.get(
        '/api/referrals/',
        query: patientId == null ? null : {'triage__visit__patient': patientId},
      ),
    );
  }

  Future<Map<String, dynamic>> updateStatus(
    int referralId,
    String status,
  ) async {
    return await _client.patch(
      '/api/referrals/$referralId/update-status/',
      body: {'status': status},
    ) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> generate({required int triageId}) async {
    return await _client.post(
      '/api/referrals/generate/',
      body: {'triage_id': triageId},
    ) as Map<String, dynamic>;
  }
}

class FacilityApi {
  const FacilityApi(this._client);

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> facilities({
    String? county,
    String? subCounty,
  }) async {
    return _asList(
      await _client.get(
        '/api/facilities/',
        query: {
          if (county != null) 'county': county,
          if (subCounty != null) 'sub_county': subCounty,
          'is_active': true,
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> nearby({
    required double latitude,
    required double longitude,
    int limit = 10,
  }) async {
    return _asList(
      await _client.get(
        '/api/facilities/nearby/',
        query: {'lat': latitude, 'lng': longitude, 'limit': limit},
      ),
    );
  }
}

class FollowUpApi {
  const FollowUpApi(this._client);

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> schedules({int? patientId}) async {
    return _asList(
      await _client.get(
        '/api/followup/schedules/',
        query: patientId == null ? null : {'patient': patientId},
      ),
    );
  }

  Future<List<Map<String, dynamic>>> alerts({int? patientId}) async {
    return _asList(
      await _client.get(
        '/api/followup/alerts/',
        query: patientId == null ? null : {'patient': patientId},
      ),
    );
  }
}

class ClinicalApi {
  const ClinicalApi(this._client);

  final ApiClient _client;

  Future<List<Map<String, dynamic>>> decisions({int? patientId}) async {
    return _asList(
      await _client.get(
        '/api/clinical/',
        query: patientId == null ? null : {'visit__patient': patientId},
      ),
    );
  }
}

class TranscriptionApi {
  const TranscriptionApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> translateText(String text) async {
    return await _client.post(
      '/api/transcription/translate/',
      body: {'text': text},
    ) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> textToSpeech({
    required String text,
    String languageCode = 'en-US',
  }) async {
    return await _client.post(
      '/api/transcription/text-to-speech/',
      body: {'text': text, 'language_code': languageCode},
    ) as Map<String, dynamic>;
  }
}

class BackendStatusApi {
  const BackendStatusApi(this._client);

  final ApiClient _client;

  Future<void> heartbeat() async {
    await _client.get('/api/health/', authenticated: false);
  }
}

List<Map<String, dynamic>> _asList(dynamic data) {
  final raw = data is Map<String, dynamic> && data['results'] is List
      ? data['results'] as List
      : data is List
          ? data
          : const [];
  return raw
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}
