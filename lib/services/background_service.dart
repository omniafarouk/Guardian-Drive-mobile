// // services/background_service_entry.dart
// import 'dart:async';
// import 'dart:ui';

// import 'package:flutter_background_service/flutter_background_service.dart';
// import 'package:guardian_drive_mobile/models/continuous_vital_readings.dart';
// import 'package:guardian_drive_mobile/models/driver_health_thresholds.dart';
// import 'package:guardian_drive_mobile/services/health_monitoring_services/health_monitor.dart';
// import 'package:guardian_drive_mobile/services/mock_vitals_stream.dart';
// import 'package:guardian_drive_mobile/services/vitals_aggregation/hive_store.dart';
// import 'package:guardian_drive_mobile/services/vitals_aggregation/vitals_aggregator_service.dart';
// import 'package:guardian_drive_mobile/utils/trace_log.dart';

// /// Entry point for the background isolate.
// /// MUST be a top-level function — not a class method.
// /// MUST be annotated with @pragma('vm:entry-point').
// @pragma('vm:entry-point')
// void onBackgroundServiceStart(ServiceInstance service) async {
//   DartPluginRegistrant.ensureInitialized();

//   // Re-initialize Hive in this isolate — it has its own memory space
//   await HiveStore.init();

//   // These will be set when the UI sends 'tripStarted'
//   HealthMonitorService? healthMonitor;
//   VitalsAggregator? vitalsAggregator;
//   StreamSubscription<VitalReadings>? vitalsSubscription;
//   StreamController<VitalReadings>? vitalsController;

//   // ── Listen for commands from the UI isolate ──────────────────────

//   service.on('tripStarted').listen((data) async {
//     if (data == null) return;

//     final thresholdsJson = Map<String, dynamic>.from(data['thresholds']);
//     final thresholds = DriverHealthThresholds.fromJson(thresholdsJson);
//     final testMode = data['testMode'] as bool? ?? false;

//     traceLog('Background: trip started', 'testMode=$testMode');

//     // Set up broadcast stream
//     vitalsController = StreamController<VitalReadings>.broadcast();

//     // Start aggregation
//     vitalsAggregator = VitalsAggregator(testMode: testMode);
//     vitalsAggregator!.start();

//     // Start health monitoring
//     healthMonitor = HealthMonitorService(
//       thresholds: thresholds,
//       testMode: testMode,
//       onAlertTriggered: (result, reading) {
//         // Send alert info back to UI isolate to handle POST and dialog
//         service.invoke('alertFired', {
//           'conditionName': result,
//           'reading': reading,
//         });
//       },
//       onWarning: (result, reading) {
//         service.invoke('warningFired', {
//           'conditionName': result,
//           'reading': reading,
//         });
//       },
//     );
//     healthMonitor!.start(vitalsController!.stream);

//     // Start vitals source (replace mockVitalsStream with WearableBandService later)
//     vitalsSubscription = mockVitalsStream().listen((reading) {
//       vitalsController!.add(reading);
//       vitalsAggregator!.onReading(reading);

//       // Send latest reading to UI for display
//       service.invoke('newReading', {
//         'heartRate': reading.heartRate,
//         'spo2': reading.spo2,
//         'temp': reading.temp,
//         'timestamp': reading.timestamp.toIso8601String(),
//       });
//     });
//   });

//   service.on('tripEnded').listen((_) async {
//     traceLog('Background: trip ending');

//     await vitalsSubscription?.cancel();
//     healthMonitor?.stop();

//     final tripAvg = await vitalsAggregator?.finalize();

//     if (tripAvg != null) {
//       // Send result to UI to handle the backend POST
//       service.invoke('tripAvgReady', {
//         'heartRate': tripAvg.heartRate,
//         'spo2': tripAvg.spo2,
//         'temp': tripAvg.temp,
//       });
//     }

//     await service.stopSelf();
//   });

//   service.on('stopService').listen((_) async {
//     await vitalsSubscription?.cancel();
//     healthMonitor?.stop();
//     vitalsAggregator?.stop();
//     await service.stopSelf();
//   });
// }
