import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/models/continuous_vital_readings.dart';
import 'package:guardian_drive_mobile/models/driver_health_thresholds.dart';
import 'package:guardian_drive_mobile/services/band_ble_service.dart';
import 'package:guardian_drive_mobile/services/device_auth_service.dart';
import 'package:guardian_drive_mobile/services/health_monitoring_services/health_monitor.dart';
import 'package:guardian_drive_mobile/services/user_service.dart';
import 'package:guardian_drive_mobile/services/vitals_aggregation/hive_store.dart';
import 'package:guardian_drive_mobile/services/vitals_aggregation/vitals_aggregator_service.dart';
import 'package:guardian_drive_mobile/utils/trace_log.dart';
import 'package:guardian_drive_mobile/widgets/health_alert_popup.dart';
import 'package:guardian_drive_mobile/widgets/health_warning_popup.dart';

import '../models/trip.dart';
import '../models/trips_response.dart';
import 'package:http/http.dart' as http;
import 'api_client_service.dart' as api_service;

import 'package:guardian_drive_mobile/services/band_ble_service.dart';
// import 'package:guardian_drive_mobile/services/band_ble_simulator_service.dart';

class TripService {
  static const baseUrl = api_service.ApiClient.baseUrl;
  int? activeTripId;
  bool isTripActive = false;

  // Singleton -- for one single instance shared across the entire app
  static final TripService instance = TripService._internal();
  factory TripService() => instance;
  TripService._internal();

  // ── Broadcast stream ──────────────────────────────────────────────
  // Single source of truth for live vitals during a trip.
  // Multiple subscribers (UI pages, HealthMonitorService, VitalsAggregator)
  // all listen to this same stream — one BLE/mock connection, distributed.

  Stream<VitalReadings> get vitalsStream =>
      BandBleService.instance.telemetryController.stream;

  // ── Internal services ─────────────────────────────────────────────
  StreamSubscription<VitalReadings>? _vitalsSubscription;
  VitalsAggregator? _vitalsAggregator;
  HealthMonitorService? _healthMonitor;

  // Notifier for the SOS Button Appereance
  final ValueNotifier<bool> tripIsActiveNotifier = ValueNotifier(false);

  // ---------------- Trip Services ----------------

  void activateTrip(int tripId) {
    if (activeTripId != null) {
      throw Exception("there is already an ongoing trip for this driver");
    }
    activeTripId = tripId;
    isTripActive = true;
    tripIsActiveNotifier.value = true;
  }

  void clearActiveTrip() {
    activeTripId = null;
    isTripActive = false;
    tripIsActiveNotifier.value = false;
  }

  Future<void> startTripTracking({
    required int tripId,
    required DriverHealthThresholds thresholds,
    bool testMode = false,
  }) async {
    try {
      traceLog('TripService: trip started', tripId);
      activateTrip(tripId);

      // 1. Start aggregation
      await HiveStore.init();
      _vitalsAggregator = VitalsAggregator(testMode: testMode);
      _vitalsAggregator!.start();

      // 2. Start health monitoring — subscribes to vitalsStream internally
      _healthMonitor = HealthMonitorService(
        thresholds: thresholds,
        onAlertTriggered: (conditionName, reading) {
          showHealthAlertDialog(conditionName, reading);
        },
        onWarning: (conditionName, reading) {
          showHealthWarningDialog(conditionName, reading);
        },
        testMode: testMode,
      );
      _healthMonitor!.start(vitalsStream);

      // 3. Feed aggregator manually — VitalsAggregator has no stream
      //    subscription of its own, it only exposes onReading()
      _vitalsSubscription = vitalsStream.listen((reading) {
        _vitalsAggregator!.onReading(reading);
      });
    } catch (e) {
      clearActiveTrip();
      throw Exception(e);
    }
  }

  // called to stop the tracking and update avgReading in database
  Future<void> endTripTracking() async {
    if (activeTripId == null) {
      clearActiveTrip();
      traceLog('endTrip called but no active trip');
      return;
    }
    traceLog('TripService: trip ended', activeTripId);

    // 1. Stop health monitor first — no more alerts while we're shutting down
    _healthMonitor?.stop();
    _healthMonitor = null;

    // 2. Stop feeding the aggregator
    await _vitalsSubscription?.cancel();
    _vitalsSubscription = null;

    // 3. Finalize aggregator — computes trip average from stored readings
    VitalReadings? tripAvg = await _vitalsAggregator?.finalize();

    if (tripAvg == null) {
      clearActiveTrip();
      return;
    }

    try {
      final success = await UserService.createHealthReadings(
        tripAvg,
        activeTripId!,
      );
      if (success) {
        traceLog(
          'Created health readings at database, deleting hive store',
          tripAvg.toString(),
        );
        HiveStore.clearAll(); // only wipe local data if POST succeeded
      }
    } catch (error) {
      throw Exception('End Trip Failed, Try Again');
    } finally {
      _vitalsAggregator = null;
      clearActiveTrip();
    }
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

      //final List tripsJson = data['trips'];

      // return tripsJson.map((e) => Trip.fromJson(e)).toList();
      return Trip.fromJson(data['trip']);
    } else {
      throw Exception('Failed to load trip');
    }
  }

  Future<Trip> patchTrip(int tripId, TripStatus status) async {
    final body = jsonEncode({'status': status.name});
    final uri = Uri.parse('$baseUrl/api/trips/$tripId');
    print('PATCH URL: $uri');
    print('PATCH BODY: $body');
    final response = await http.patch(
      uri,
      headers: await api_service.ApiClient.headers(),
      body: body,
    );
    traceLog("STATUS CODE: ${response.statusCode}");
    traceLog("BODY: ${response.body}");
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Trip.fromJson(data['trip']);
    } else {
      final error = json.decode(response.body);
      traceLog("failed to update trip", {error['error']});
      traceLog("failed to update trip", {error});
      throw Exception('Failed to update trip');
    }
  }

  Future<Trip> patchTripSystem(int tripId, TripStatus status) async {
    final body = jsonEncode({'status': status.name});
    final uri = Uri.parse('$baseUrl/api/trips/$tripId/system');
    print('PATCH URL: $uri');
    print('PATCH BODY: $body');
    final response = await http.patch(
      uri,
      headers: DeviceAuth.systemAuthHeader(),
      body: body,
    );
    traceLog("STATUS CODE: ${response.statusCode}");
    traceLog("BODY: ${response.body}");
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Trip.fromJson(data['trip']);
    } else {
      final error = json.decode(response.body);
      traceLog("failed to update trip", {error['error']});
      traceLog("failed to update trip", {error});
      throw Exception('Failed to update trip');
    }
  }
}
