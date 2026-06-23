import 'dart:async';
import 'dart:convert';
import 'package:guardian_drive_mobile/models/continous_vital_readings.dart';
import 'package:guardian_drive_mobile/models/driver_health_thresholds.dart';
import 'package:guardian_drive_mobile/services/health_monitoring_services/health_monitor.dart';
import 'package:guardian_drive_mobile/services/medical_info_service.dart';
import 'package:guardian_drive_mobile/services/mock_vitals_stream.dart';
import 'package:guardian_drive_mobile/services/user_service.dart';
import 'package:guardian_drive_mobile/services/vitals_aggregation/hive_store.dart';
import 'package:guardian_drive_mobile/services/vitals_aggregation/vitals_aggregator_service.dart';
import 'package:guardian_drive_mobile/utils/trace_log.dart';

import '../models/trip.dart';
import '../models/trips_response.dart';
import 'package:http/http.dart' as http;
import 'api_client_service.dart' as api_service;

class TripService {
  static const baseUrl = api_service.ApiClient.baseUrl;

  // Singleton -- for one single instance shared across the entire app
  static final TripService instance = TripService._internal();
  factory TripService() => instance;
  TripService._internal();

  // ── Broadcast stream ──────────────────────────────────────────────
  // Single source of truth for live vitals during a trip.
  // Multiple subscribers (UI pages, HealthMonitorService, VitalsAggregator)
  // all listen to this same stream — one BLE/mock connection, distributed.

  // Broadcast stream — multiple pages can listen to this
  final StreamController<VitalReadings> _vitalsController =
      StreamController<VitalReadings>.broadcast();

  // Public stream that any page can subscribe to
  Stream<VitalReadings> get vitalsStream => _vitalsController.stream;

  // ── Internal services ─────────────────────────────────────────────

  StreamSubscription<VitalReadings>? _vitalsSubscription;
  //  ---- readings and bluetooth stream things (currently just a mock stream) ---------
  VitalsAggregator? _vitalsAggregator;

  HealthMonitorService? _healthMonitor;

  // ---------------- Trip Services ----------------

  Future<void> startTrip({
    int? tripId,
    DriverHealthThresholds? staticThresholds,
    bool testMode = false,
  }) async {
    traceLog('TripService: trip started', tripId);

    DriverHealthThresholds thresholds = await MedicalInfoService()
        .getDriverThresholds();

    thresholds =
        staticThresholds ??
        thresholds; // SHOULD NOT BE THERE , ONLY FOR TESTING

    // TODO: Start (predrive health check)

    // 1. Start aggregation
    await HiveStore.init();
    _vitalsAggregator = VitalsAggregator(testMode: testMode);
    _vitalsAggregator!.start();

    // 2. Start health monitoring
    _healthMonitor = HealthMonitorService(
      thresholds: thresholds,
      // onAlertTriggered: (breach) {
      //   // TODO: POST alert to backend — same pattern as SOS flow
      //   traceLog('Alert triggered', breach.toString());
      // },
      testMode: testMode,
    );
    _healthMonitor!.start(vitalsStream);

    // 3. Connect the vitals source → feeds BOTH aggregator and monitor
    //    via the broadcast stream
    _vitalsSubscription = mockVitalsStream().listen((reading) {
      _vitalsController.add(reading); // → broadcast to all subscribers
      _vitalsAggregator!.onReading(reading); // → aggregation pipeline
    });
  }

  Future<void> endTrip(int? tripId) async {
    traceLog('TripService: trip ended', tripId);
    // Stop the stream    <<<<-------------- later would be stopping the BLE stream
    await _vitalsSubscription?.cancel();
    _vitalsSubscription = null;

    // Stop timers
    VitalReadings? tripAvg = await _vitalsAggregator?.finalize();

    _healthMonitor?.stop();
    _healthMonitor = null;

    if (tripAvg == null) return;

    const readings = 1;
    // send to user Service
    // final readings = await UserService.createHealthReadings(tripAvg, tripId);
    if (readings != null) {
      // or do it at finalize() ?
      _vitalsAggregator = null;
      traceLog(
        'created Health readings at database, Deleting hive store',
        tripAvg.toString(),
      );
      HiveStore.clearAll();
    }
  }

  void dispose() {
    _vitalsController.close();
  }

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
    // print("STATUS CODE: ${response.statusCode}");
    // print("BODY: ${response.body}");
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
    //print("STATUS CODE: ${response.statusCode}");
    //print("BODY: ${response.body}");
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
    //print("STATUS CODE: ${response.statusCode}");
    //print("BODY: ${response.body}");
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Trip.fromJson(data['trip']);
    } else {
      throw Exception('Failed to update trip');
    }
  }
}
