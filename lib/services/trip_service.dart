import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:guardian_drive_mobile/models/continous_vital_readings.dart';
import 'package:guardian_drive_mobile/services/device_auth_service.dart';
import 'package:guardian_drive_mobile/services/mock_vitals_stream.dart';
import 'package:guardian_drive_mobile/services/user_service.dart';
import 'package:guardian_drive_mobile/services/vitals_aggregation/hive_store.dart';
import 'package:guardian_drive_mobile/services/vitals_aggregation/vitals_aggregator_service.dart';

import '../models/trip.dart';
import '../models/trips_response.dart';
import 'package:http/http.dart' as http;
import 'api_client_service.dart' as api_service;

class TripService {
  //final token =
  //   'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEyLCJyb2xlIjoiRFJJVkVSIiwiaWF0IjoxNzc4NjU1NDIyLCJleHAiOjE3Nzg3NDE4MjJ9.nkvii20cOneNM41A_JoW34oqDA2bx2cBO7_rv41UYXQ';
  //final String baseUrl = "http://10.0.2.2:3000/api";
  //final String baseUrl = "http://localhost:3000/api/trips";
  static const baseUrl = api_service.ApiClient.baseUrl;

  //  ---- readings and bluetooth stream things (currently just a mock stream) ---------
  final vitalAggregator =
      VitalsAggregator(); // can add testMode: true for different speeds
  StreamSubscription<VitalReadings>? _vitalsSubscription;

  // Broadcast stream — multiple pages can listen to this
  final StreamController<VitalReadings> _vitalsController =
      StreamController<VitalReadings>.broadcast();

  // Public stream that any page can subscribe to
  Stream<VitalReadings> get vitalsStream => _vitalsController.stream;

  // for one single instance shared across the entire app
  static final TripService instance = TripService._internal();
  factory TripService() => instance;
  TripService._internal();

  // ------- Api services ------------------
  Future<TripsResponse> getTrips({
    int page = 1,
    int limit = 1,
    String? engineId,
    int? driverId,
    String? status,
    DateTime? fromStartDate,
    DateTime? toStartDate,
    int? fleetManagerId,
    String orderBy = "desc",
  }) async {
    final Map<String, String> queryParams = {
      "page": page.toString(),
      "limit": limit.toString(),
      "orderBy": orderBy,
    };

    if (engineId != null) {
      queryParams["engineId"] = engineId;
    }

    if (driverId != null) {
      queryParams["driverId"] = driverId.toString();
    }

    if (status != null) {
      queryParams["status"] = status;
    }

    if (fleetManagerId != null) {
      queryParams["fleetManagerId"] = fleetManagerId.toString();
    }

    if (fromStartDate != null) {
      queryParams["fromStartDate"] = fromStartDate.toIso8601String();
    }

    if (toStartDate != null) {
      queryParams["toStartDate"] = toStartDate.toIso8601String();
    }
    final uri = Uri.parse(
      '$baseUrl/api/trips',
    ).replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: await api_service.ApiClient.headers(),

      // headers: {
      //   // add auth token from secure storage
      //   HttpHeaders.authorizationHeader:
      //       'Bearer $token',
      // },
    );
    print("STATUS CODE: ${response.statusCode}");
    print("BODY: ${response.body}");
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);

      //final List tripsJson = data['trips'];  // 👈 FIX HERE

      // return tripsJson.map((e) => Trip.fromJson(e)).toList();
      return TripsResponse.fromJson(data);
    } else {
      throw Exception('Failed to load trips');
    }
  }

  Future<Trip> getTripById(int tripId) async {
    final uri = Uri.parse('$baseUrl/api/trips/$tripId');
    final response = await http.get(
      uri,
      headers: await api_service.ApiClient.headers(),

      // headers: {
      //   // add auth token from secure storage
      //   HttpHeaders.authorizationHeader:
      //   'Bearer $token',
      // },
    );
    print("STATUS CODE: ${response.statusCode}");
    print("BODY: ${response.body}");
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      //final List tripsJson = data['trips'];  // 👈 FIX HERE

      // return tripsJson.map((e) => Trip.fromJson(e)).toList();
      return Trip.fromJson(data['trip']);
    } else {
      throw Exception('Failed to load trip');
    }
  }

  Future<Trip> patchTrip(int tripId, TripStatus status) async {
    final body = jsonEncode({'status': status.name});
    final uri = Uri.parse('$baseUrl/api/trips/$tripId');
    final response = await http.patch(
      uri,
      headers: await api_service.ApiClient.headers(),

      //     headers: {
      //   // add auth token from secure storage
      //   HttpHeaders.authorizationHeader:
      //   'Bearer $token',
      //   HttpHeaders.contentTypeHeader: 'application/json',
      // },
      body: body,
    );
    print("STATUS CODE: ${response.statusCode}");
    print("BODY: ${response.body}");
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Trip.fromJson(data['trip']);
    } else {
      throw Exception('Failed to update trip');
    }
  }

  // ---------------- Trip Services ----------------
  void startTrip(int tripId) {
    // TODO: Start (predrive health check)
    vitalAggregator.start();
    // reading should be constant along the trip
    // vitalAggregator.onReading(reading);  // TODO: replaced with BLE stream later

    _vitalsSubscription = mockVitalsStream().listen((reading) {
      vitalAggregator.onReading(reading); // aggregation
      _vitalsController.add(
        reading,
      ); // broadcast to UI (to access in case of alert)
    });
  }

  Future<void> endTrip(int tripId) async {
    // Stop the stream    <<<<-------------- later would be stopping the BLE stream
    await _vitalsSubscription?.cancel();
    _vitalsSubscription = null;

    // Stop timers
    VitalReadings? totalReadings = await vitalAggregator.finalize();

    if (totalReadings == null) return;

    // send to user Service
    final readings = await UserService.createHealthReadings(
      totalReadings,
      tripId,
    );
    if (readings != null) {
      // or do it at finalize() ?
      HiveStore.clearAll();
    }
  }

  void dispose() {
    _vitalsController.close();
  }
}
