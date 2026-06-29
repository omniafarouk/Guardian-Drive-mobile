// services/health_monitor.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:guardian_drive_mobile/main.dart';
import 'package:guardian_drive_mobile/models/continuous_vital_readings.dart';
import 'package:guardian_drive_mobile/models/driver_health_thresholds.dart';
import 'package:guardian_drive_mobile/models/alert_tier.dart';
import 'package:guardian_drive_mobile/services/health_monitoring_services/condition_pattern_matcher.dart';
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

    TriggerEvaluation triggerEvaluation;

    if (breaches.isEmpty) {
      // no threshold breach — check pattern directly on raw reading
      final patternMatched = _coordinator.classifyPattern(reading);

      if (patternMatched == null || patternMatched.tier == null) {
        return; // no breach, no pattern → do nothing
      }

      // pattern matched with no breach — fire alert/warning directly
      // still respect cooldown
      if (_coordinator.cooldownUntil != null &&
          DateTime.now().isBefore(_coordinator.cooldownUntil!)) {
        traceLog('Pattern match suppressed — cooldown active');
        return;
      }

      triggerEvaluation = TriggerEvaluation(
        tier: patternMatched.tier,
        conditionName: patternMatched.conditionName,
        breaches: [],
      );

      // start cooldown since we're about to fire
      _coordinator.cooldownUntil = DateTime.now().add(_coordinator.cooldown);
    } else {
      // breaches exist — go through full coordinator pipeline
      // (streak confirmation + pattern matching + cooldown)
      triggerEvaluation = _coordinator.evaluate(
        breaches,
        DateTime.now(),
        reading,
      );
    }

    if (!triggerEvaluation.hasAction) return;

    traceLog(
      'HealthMonitor firing',
      'tier=${triggerEvaluation.tier!.name}, condition=${triggerEvaluation.conditionName}',
    );

    if (triggerEvaluation.breaches != null) {
      for (final breach in triggerEvaluation.breaches!) {
        traceLog('HealthMonitor firing for', breach.toString());
      }
    }

    final conditionName =
        triggerEvaluation.conditionName ?? 'Unknown Condition';

    if (triggerEvaluation.tier == AlertTier.warning) {
      traceLog('Send Warning Notification To Driver:', reading.toString());
      onWarning(conditionName, reading);
    } else if (triggerEvaluation.tier == AlertTier.alertTrigger) {
      traceLog('Trigger Alert:', reading.toString());
      onAlertTriggered(conditionName, reading);
    }
  }

  void stop() => _subscription?.cancel();
}
