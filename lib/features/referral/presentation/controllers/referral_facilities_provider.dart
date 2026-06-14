import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:repair_ai/core/network/api_client.dart';
import 'package:repair_ai/core/network/backend_services.dart';
import 'package:repair_ai/features/triage/application/triage_controller.dart';

enum ReferralFacilitySource { gps, countyFallback, unavailable }

class ReferralFacility {
  const ReferralFacility({
    required this.id,
    required this.name,
    required this.level,
    required this.county,
    required this.subCounty,
    required this.hasUltrasound,
    required this.hasBloodBank,
    required this.isActive,
    this.verified = true,
    this.latitude,
    this.longitude,
    this.phone,
    this.staffOnDuty,
    this.bedsAvailable,
    this.distanceKm,
  });

  final int id;
  final String name;
  final String level;
  final String county;
  final String subCounty;
  final bool hasUltrasound;
  final bool hasBloodBank;
  final bool isActive;
  final bool verified;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final int? staffOnDuty;
  final int? bedsAvailable;
  final double? distanceKm;

  LatLng? get point {
    if (latitude == null || longitude == null) return null;
    return LatLng(latitude!, longitude!);
  }

  static ReferralFacility fromMap(Map<String, dynamic> data) {
    final capacity = data['latest_capacity'];
    final lat = _doubleValue(data['latitude']);
    final lon = _doubleValue(data['longitude']);

    // Validate coordinates to prevent crashes
    if (lat != null && (lat < -90 || lat > 90)) {
      throw ArgumentError(
          'Invalid latitude: $lat for facility ${data['name']}');
    }
    if (lon != null && (lon < -180 || lon > 180)) {
      throw ArgumentError(
          'Invalid longitude: $lon for facility ${data['name']}');
    }

    return ReferralFacility(
      id: _intValue(data['id']) ?? 0,
      name: '${data['name'] ?? 'Health facility'}',
      level: '${data['level'] ?? ''}',
      county: '${data['county'] ?? ''}',
      subCounty: '${data['sub_county'] ?? ''}',
      hasUltrasound: data['has_ultrasound'] == true,
      hasBloodBank: data['has_blood_bank'] == true,
      isActive: data['is_active'] != false,
      verified: true,
      latitude: lat,
      longitude: lon,
      phone: _stringOrNull(data['phone']),
      staffOnDuty: _intValue(data['staff_on_duty']),
      bedsAvailable: capacity is Map<String, dynamic>
          ? _intValue(capacity['beds_available'])
          : null,
      distanceKm: _doubleValue(data['distance_km']),
    );
  }

  static ReferralFacility fromOsm({
    required int id,
    required String name,
    required double latitude,
    required double longitude,
    required double patientLatitude,
    required double patientLongitude,
    String? kind,
  }) {
    final distance = const Distance().as(
      LengthUnit.Kilometer,
      LatLng(patientLatitude, patientLongitude),
      LatLng(latitude, longitude),
    );
    return ReferralFacility(
      id: -id.abs(),
      name: name,
      level: kind ?? 'Map result',
      county: '',
      subCounty: '',
      hasUltrasound: false,
      hasBloodBank: false,
      isActive: true,
      verified: false,
      latitude: latitude,
      longitude: longitude,
      distanceKm: distance,
    );
  }
}

class ReferralFacilitiesState {
  const ReferralFacilitiesState({
    required this.source,
    required this.facilities,
    this.mapFacilities = const [],
    this.patientLocation,
    this.message,
    this.error,
  });

  final ReferralFacilitySource source;
  final List<ReferralFacility> facilities;
  final List<ReferralFacility> mapFacilities;
  final LatLng? patientLocation;
  final String? message;
  final String? error;

  bool get hasGps => source == ReferralFacilitySource.gps;
}

final referralFacilitiesProvider =
    FutureProvider.autoDispose<ReferralFacilitiesState>((ref) async {
  final facilityApi = ref.watch(facilityApiProvider);
  final referralApi = ref.watch(referralApiProvider);
  final patientApi = ref.watch(patientApiProvider);

  // Get the current triage result (visit ID + risk level) for smart recommendations
  final triageResult = ref.read(triageResultProvider);
  final riskLevel = triageResult?.riskLevel.name ?? 'low';

  // Start GPS resolution immediately
  final locationFuture = _tryResolveLocation();

  // Pre-fetch patient profile for patient ID + county fallback (in parallel with GPS)
  Map<String, dynamic>? profile;
  try {
    profile = await patientApi.myProfile();
  } catch (_) {
    profile = null;
  }

  final patientId = profile?['id'] as int?;
  final visitId = triageResult?.backendTriageId;

  // If we have a patient ID + triage, use the smart GIS recommendation engine
  if (patientId != null) {
    try {
      final recommended = await referralApi.recommendFacilities(
        patientId: patientId,
        visitId: visitId ?? 0,
        riskLevel: riskLevel,
      );
      final facilitiesList = recommended['facilities'];
      if (facilitiesList is List && facilitiesList.isNotEmpty) {
        final items = facilitiesList
            .whereType<Map<String, dynamic>>()
            .map(_facilityFromRecommendation)
            .toList();
        final location = await locationFuture;
        final patientLat =
            (recommended['patient_coords']?['lat'] as num?)?.toDouble();
        final patientLng =
            (recommended['patient_coords']?['lng'] as num?)?.toDouble();
        final patientLatLng = (patientLat != null && patientLng != null)
            ? LatLng(patientLat, patientLng)
            : (location != null
                ? LatLng(location.latitude, location.longitude)
                : null);

        // Also fetch OSM map markers in parallel if we have GPS
        List<ReferralFacility> mapItems = const [];
        if (location != null) {
          mapItems = await _nearbyOsmFacilities(
            latitude: location.latitude,
            longitude: location.longitude,
          );
        }

        return ReferralFacilitiesState(
          source: ReferralFacilitySource.gps,
          facilities: items,
          mapFacilities: mapItems,
          patientLocation: patientLatLng,
          message:
              'Showing AI-recommended facilities based on your symptoms and location.',
        );
      }
    } catch (_) {
      // Fall through to GPS / county fallback
    }
  }

  final location = await locationFuture;
  if (location != null) {
    // Run backend facilities + OSM map markers in parallel
    final results = await Future.wait([
      _safeFacilities(() => facilityApi.nearby(
            latitude: location.latitude,
            longitude: location.longitude,
            limit: 10,
          )),
      _nearbyOsmFacilities(
        latitude: location.latitude,
        longitude: location.longitude,
      ),
    ]);

    final backendItems = results[0];
    final mapItems = results[1];

    if (backendItems.isNotEmpty) {
      return ReferralFacilitiesState(
        source: ReferralFacilitySource.gps,
        facilities: backendItems,
        mapFacilities: mapItems,
        patientLocation: LatLng(location.latitude, location.longitude),
        message: 'Showing verified facilities near your current location.',
      );
    }
    return _countyFallbackFromProfile(
      profile: profile,
      facilityApi: facilityApi,
      sourceMessage:
          'No nearby facilities found. Showing county results where available.',
    );
  }

  return _countyFallbackFromProfile(
    profile: profile,
    facilityApi: facilityApi,
    sourceMessage:
        'Location is off. We can still show verified facilities from your county.',
  );
});

/// Convert a recommendation engine result to [ReferralFacility].
ReferralFacility _facilityFromRecommendation(Map<String, dynamic> data) {
  final lat = (data['lat'] as num?)?.toDouble();
  final lng = (data['lng'] as num?)?.toDouble();
  final distance = (data['distance_km'] as num?)?.toDouble();
  return ReferralFacility(
    id: (data['id'] as num?)?.toInt() ?? 0,
    name: '${data['name'] ?? 'Health facility'}',
    level: '${data['level'] ?? ''}',
    county: '${data['county'] ?? ''}',
    subCounty: '${data['sub_county'] ?? ''}',
    hasUltrasound: data['has_ultrasound'] == true,
    hasBloodBank: data['has_blood_bank'] == true,
    isActive: true,
    verified: true,
    latitude: lat,
    longitude: lng,
    phone: data['phone'] as String?,
    distanceKm: distance,
  );
}

Future<Position?> _tryResolveLocation() async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    // Use last known position first (instant), then request current
    Position? position;
    try {
      position = await Geolocator.getLastKnownPosition();
    } catch (_) {}

    // If last known is recent enough, use it; otherwise request fresh
    if (position != null) return position;

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 5),
      ),
    );
  } catch (_) {
    return null;
  }
}

/// Wraps a facility fetch so individual failures don't crash the provider.
Future<List<ReferralFacility>> _safeFacilities(
  Future<List<Map<String, dynamic>>> Function() fetch,
) async {
  try {
    final items = await fetch();
    return items.map(ReferralFacility.fromMap).toList();
  } catch (_) {
    return const [];
  }
}

/// County fallback using a pre-fetched profile (avoids second API call).
Future<ReferralFacilitiesState> _countyFallbackFromProfile({
  required Map<String, dynamic>? profile,
  required FacilityApi facilityApi,
  required String sourceMessage,
  String? error,
}) async {
  try {
    final county = _stringOrNull(profile?['county']);
    final subCounty = _stringOrNull(profile?['sub_county']);
    final facilities = await facilityApi.facilities(
      county: county,
      subCounty: subCounty,
    );
    return ReferralFacilitiesState(
      source: ReferralFacilitySource.countyFallback,
      facilities: facilities.map(ReferralFacility.fromMap).toList(),
      message: sourceMessage,
      error: error,
    );
  } on ApiException catch (fallbackError) {
    return ReferralFacilitiesState(
      source: ReferralFacilitySource.unavailable,
      facilities: const [],
      mapFacilities: const [],
      message: sourceMessage,
      error: error ?? fallbackError.message,
    );
  } catch (_) {
    // REMOVED: _demoFacilities() fallback
    // Instead, show empty state with helpful message
    final county = _stringOrNull(profile?['county']) ?? 'your area';
    return ReferralFacilitiesState(
      source: ReferralFacilitySource.unavailable,
      facilities: const [],
      mapFacilities: const [],
      patientLocation: null,
      message:
          'Unable to load facilities. Please enable location or check your internet connection.',
      error:
          'No facilities available for $county. Contact support if this persists.',
    );
  }
}

Future<List<ReferralFacility>> _nearbyOsmFacilities({
  required double latitude,
  required double longitude,
}) async {
  final query = '''
[out:json][timeout:12];
(
  node(around:20000,$latitude,$longitude)["amenity"~"hospital|clinic|doctors"];
  way(around:20000,$latitude,$longitude)["amenity"~"hospital|clinic|doctors"];
  relation(around:20000,$latitude,$longitude)["amenity"~"hospital|clinic|doctors"];
  node(around:20000,$latitude,$longitude)["healthcare"~"hospital|clinic|doctor|centre"];
  way(around:20000,$latitude,$longitude)["healthcare"~"hospital|clinic|doctor|centre"];
  relation(around:20000,$latitude,$longitude)["healthcare"~"hospital|clinic|doctor|centre"];
);
out center tags 30;
''';

  try {
    final response = await http.post(
      Uri.parse('https://overpass-api.de/api/interpreter'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: {'data': query},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const [];
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) return const [];
    final elements = decoded['elements'];
    if (elements is! List) return const [];

    final seen = <String>{};
    final results = <ReferralFacility>[];
    for (final element in elements.whereType<Map<String, dynamic>>()) {
      final tags = element['tags'];
      if (tags is! Map) continue;
      final name = _stringOrNull(tags['name']);
      if (name == null) continue;

      final lat = _doubleValue(element['lat']) ??
          (element['center'] is Map
              ? _doubleValue((element['center'] as Map)['lat'])
              : null);
      final lon = _doubleValue(element['lon']) ??
          (element['center'] is Map
              ? _doubleValue((element['center'] as Map)['lon'])
              : null);
      if (lat == null || lon == null) continue;

      final key = name.toLowerCase().trim();
      if (!seen.add(key)) continue;

      results.add(
        ReferralFacility.fromOsm(
          id: _intValue(element['id']) ?? results.length + 1,
          name: name,
          latitude: lat,
          longitude: lon,
          patientLatitude: latitude,
          patientLongitude: longitude,
          kind: _stringOrNull(tags['healthcare']) ??
              _stringOrNull(tags['amenity']),
        ),
      );
    }

    results.sort(
      (a, b) => (a.distanceKm ?? double.infinity).compareTo(
        b.distanceKm ?? double.infinity,
      ),
    );
    return results.take(20).toList();
  } catch (_) {
    return const [];
  }
}

String? _stringOrNull(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') return null;
  return text;
}

double? _doubleValue(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

int? _intValue(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
