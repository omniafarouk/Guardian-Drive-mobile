import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:guardian_drive_mobile/models/trip_location.dart';
import 'package:guardian_drive_mobile/services/trip_service.dart';
import 'package:guardian_drive_mobile/utils/location_helper.dart';
import 'package:guardian_drive_mobile/utils/trace_log.dart';
import 'package:http/http.dart' as http;

import 'api_client_service.dart' as api_service;

class LocationService {
  static const baseUrl = api_service.ApiClient.baseUrl;

  Future<TripLocation> createTripLocation(
    double latitude,
    double longitude,
  ) async {
    final int? tripId = TripService().activeTripId;

    if (tripId == null) {
      throw Exception('No Active Trip');
    }

    final uri = Uri.parse('$baseUrl/api/trips/$tripId/gps');

    print(uri);
    print(tripId);

    final response = await http.post(
      uri,
      headers: await api_service.ApiClient.headers(),
      body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
    );

    if (response.statusCode == 201) {
      final jsonBody = json.decode(response.body);
      print(jsonBody);

      return TripLocation.fromJson(jsonBody['data']);
    } else {
      traceLog('Creating Location Failed Fallback on latest Position saved');
      throw Exception('Failed to load location (${response.statusCode})');
    }
  }

  Future<int> getCurrentLocationId() async {
    final Position currentPosition = await getCurrentPosition();
    TripLocation trip = await createTripLocation(
      currentPosition.latitude,
      currentPosition.longitude,
    );
    return trip.locationId;
  }
}
