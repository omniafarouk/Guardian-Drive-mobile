// services/health_monitor.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/main.dart';
import 'package:guardian_drive_mobile/models/continuous_vital_readings.dart';
import 'package:guardian_drive_mobile/models/driver_health_thresholds.dart';
import 'package:guardian_drive_mobile/services/health_monitoring_services/condition_trigger_coordinator.dart';
import 'package:guardian_drive_mobile/services/health_monitoring_services/driver_baseline_with_noise_model.dart';
import 'package:guardian_drive_mobile/services/health_monitoring_services/threshold_checker_service.dart';
import 'package:guardian_drive_mobile/utils/trace_log.dart';

/// Listens to the vitals stream, checks each reading against the driver's
/// thresholds, and fires hardware + alert actions when the coordinator
/// decides a breach should trigger.

class HealthMonitorService {
  // final DriverBaselineWithNoise _baseline;
  final ThresholdChecker _checker;
  final BreachTriggerCoordinator _coordinator;
  final void Function(String conditionName, VitalReadings reading)
  onAlertTriggered;
  final void Function(String conditionName, VitalReadings reading) onWarning;
  StreamSubscription<VitalReadings>? _subscription;

  // Broadcast stream — multiple pages can listen to this
  final StreamController<VitalReadings> _vitalsController =
      StreamController<VitalReadings>.broadcast();

  // Public stream that any page can subscribe to
  Stream<VitalReadings> get vitalsStream => _vitalsController.stream;

  HealthMonitorService({
    required DriverHealthThresholds thresholds,
    //required HardwareController hardwareController,
    required this.onAlertTriggered,
    required this.onWarning,
    bool testMode = false,
  }) : _checker = ThresholdChecker(thresholds),
       //_hardwareController = hardwareController;
       _coordinator = BreachTriggerCoordinator(
         baseline: DriverBaselineWithNoise.fromThresholds(thresholds),
         testMode: testMode,
       );

  void start(Stream<VitalReadings> vitalsStream) {
    _subscription = vitalsStream.listen(_onReading);
    traceLog('Vitals Subscription Listening');
  }

  Future<void> _onReading(VitalReadings reading) async {
    final breaches = _checker.check(reading);
    if (breaches.isEmpty) return;
    final triggerEvaluation = _coordinator.evaluate(
      breaches,
      DateTime.now(),
      reading,
    );

    if (!triggerEvaluation.hasAction) return;

    traceLog(
      'HealthMonitor firing',
      'tier=${triggerEvaluation.tier!.name}, condition=${triggerEvaluation.conditionName}',
    );
    // just for logging , no functionality here
    for (final breach in triggerEvaluation.breaches) {
      traceLog('HealthMonitor firing for', breach.toString());
    }

    // TODO: add those to the alerts handlers
    // await _hardwareController
    //     .onHealthAbnormal(); // local-first, no network wait
    // onAlertTriggered(breach); // caller POSTs the alert to backend in parallel

    if (triggerEvaluation.tier == AlertTier.warning) {
      traceLog('Send Warning Notification To Driver :', reading.toString());
      String? conditionName = triggerEvaluation.conditionName;
      conditionName ??= "Unknown Condition?!!";
      onWarning(conditionName, reading);
    } else if (triggerEvaluation.tier == AlertTier.alertTrigger) {
      traceLog(
        'Check Driver For response if not Trigger Alert : ',
        reading.toString(),
      );
      String? conditionName = triggerEvaluation.conditionName;
      conditionName ??= "Unknown Condition?!!";
      onAlertTriggered(conditionName, reading);
    }
  }

  void stop() => _subscription?.cancel();
}
