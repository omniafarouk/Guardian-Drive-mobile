import 'dart:async';
import 'dart:convert';
import 'package:guardian_drive_mobile/models/continous_vital_readings.dart';
import 'package:guardian_drive_mobile/models/driver_health_thresholds.dart';
import 'package:guardian_drive_mobile/services/health_monitoring_services/health_monitor.dart';
import 'package:guardian_drive_mobile/services/health_monitoring_services/pre_drive_check_models.dart';
import 'package:guardian_drive_mobile/services/health_monitoring_services/pre_drive_check_service.dart';
import 'package:guardian_drive_mobile/services/medical_info_service.dart';
import 'package:guardian_drive_mobile/services/mock_vitals_stream.dart';
import 'package:guardian_drive_mobile/services/user_service.dart';
import 'package:guardian_drive_mobile/services/vitals_aggregation/hive_store.dart';
import 'package:guardian_drive_mobile/services/vitals_aggregation/vitals_aggregator_service.dart';
import 'package:guardian_drive_mobile/utils/trace_log.dart';
import 'package:guardian_drive_mobile/widgets/health_alert_popup.dart';

import '../models/trip.dart';
import '../models/trips_response.dart';
import 'package:http/http.dart' as http;
import 'api_client_service.dart' as api_service;

class TripService {
  static const baseUrl = api_service.ApiClient.baseUrl;
  int? _activeTripId;

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

  Future<void> startTrip({required int tripId, bool testMode = false}) async {
    traceLog('TripService: trip started', tripId);
    _activeTripId = tripId;

    DriverHealthThresholds thresholds = await MedicalInfoService()
        .getDriverThresholds();

    // FOR NOW : SHOULD BE REMOVED
    thresholds = DriverHealthThresholds(
      avgHeartRate: 75,
      minHeartRate: 60,
      maxHeartRate: 100,
      avgSpo2: 98,
      minSpo2: 95,
      maxSpo2: 100,
      avgTemp: 36.5,
      minTemp: 36.0,
      maxTemp: 37.5,
    );

    // TODO: Start (predrive health check)

    // 1. Start aggregation
    await HiveStore.init();
    _vitalsAggregator = VitalsAggregator(testMode: testMode);
    _vitalsAggregator!.start();

    // 2. Start health monitoring
    _healthMonitor = HealthMonitorService(
      thresholds: thresholds,
      onAlertTriggered: (conditionName) {
        showHealthAlertDialog(conditionName);
      },
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

  Future<void> endTrip() async {
    if (_activeTripId == null) {
      traceLog('endTrip called but no active trip');
      return;
    }
    traceLog('TripService: trip ended', _activeTripId);
    // Stop the stream    <<<<-------------- later would be stopping the BLE stream
    await _vitalsSubscription?.cancel();
    _vitalsSubscription = null;

    // Stop timers
    VitalReadings? tripAvg = await _vitalsAggregator?.finalize();

    _healthMonitor?.stop();
    _healthMonitor = null;

    _activeTripId = null;

    if (tripAvg == null) return;

    const readings = 1;
    // send to user Service
    // final readings = await UserService.createHealthReadings(tripAvg, _activeTripId);
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

  // DESIGN: Timeout checking after 5 mins
  Future<bool> startPreDriveCheck({
    required DriverHealthThresholds thresholds,
    Duration timeout = const Duration(minutes: 5),
    bool testMode = false,
  }) async {
    final PreDriveCheckService preDriveService = PreDriveCheckService(
      thresholds: thresholds,
      timeout: timeout,
      testMode: testMode,
    );
    final result = await preDriveService.run(vitalsStream);
    if (result.canDrive) {
      traceLog('Driver passed preCheck Successfully, He may proceed');
      return true;
    } else {
      traceLog(
        'Driver didn\'t pass preCheck , Driver Blocked By: ',
        '${result.blockedBy}',
      );
      return false;
    }
    // Step 3 goes here — start the vitals stream
    // Step 4 goes here — create a fresh HealthMonitorService
    // Step 5 goes here — race timeout vs alert vs disconnect
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
