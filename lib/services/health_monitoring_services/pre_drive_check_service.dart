// services/pre_drive_check_service.dart
import 'dart:async';
import 'package:guardian_drive_mobile/models/continuous_vital_readings.dart';
import 'package:guardian_drive_mobile/models/driver_health_thresholds.dart';
import 'package:guardian_drive_mobile/services/health_monitoring_services/condition_trigger_coordinator.dart';
import 'package:guardian_drive_mobile/services/health_monitoring_services/driver_baseline_with_noise_model.dart';
import 'package:guardian_drive_mobile/services/health_monitoring_services/pre_drive_check_models.dart';
import 'package:guardian_drive_mobile/services/health_monitoring_services/threshold_checker_service.dart';
import 'package:guardian_drive_mobile/utils/trace_log.dart';

class PreDriveCheckService {
  final DriverHealthThresholds thresholds;
  final Duration timeout;
  final bool testMode;

  bool _cancelled = false;

  PreDriveCheckService({
    required this.thresholds,
    this.timeout = const Duration(minutes: 2),
    this.testMode = false,
  });

  /// Runs the pre-drive health scan.
  ///
  /// [vitalsStream] — the same broadcast stream from TripService,
  /// already running before this is called.
  ///
  /// Returns a [PreDriveResult] when one of three things happens:
  ///   1. An AlertTier pattern is detected → blocked
  ///   2. [timeout] expires with no serious match → passed
  ///   3. [cancel()] is called → cancelled
  Future<PreDriveResult> run(Stream<VitalReadings> vitalsStream) async {
    _cancelled = false;

    final checker = ThresholdChecker(thresholds);
    final baselineWithNoise = DriverBaselineWithNoise.fromThresholds(
      thresholds,
    );

    final coordinator = BreachTriggerCoordinator(
      baseline: baselineWithNoise,
      testMode: testMode,
    );

    // Completer resolves the Future the moment a result is determined
    final completer = Completer<PreDriveResult>();

    StreamSubscription<VitalReadings>? sub;

    // Timeout — if nothing serious found within the window, pass by default
    final timer = Timer(timeout, () {
      if (!completer.isCompleted) {
        traceLog('Pre-drive check timed out — passed by default');
        sub?.cancel();
        completer.complete(const PreDriveResult(status: PreDriveStatus.passed));
      }
    });

    sub = vitalsStream.listen((reading) {
      if (completer.isCompleted) return;

      if (_cancelled) {
        timer.cancel();
        sub?.cancel();
        completer.complete(
          const PreDriveResult(status: PreDriveStatus.cancelled),
        );
        return;
      }

      final breaches = checker.check(reading);
      final triggerEvaluation = coordinator.evaluate(
        breaches,
        DateTime.now(),
        reading,
      );

      if (!triggerEvaluation.hasAction) return;

      traceLog(
        'Pre-drive evaluation',
        'tier=${triggerEvaluation.tier!.name} + condition=${triggerEvaluation.conditionName}',
      );

      if (triggerEvaluation.tier == AlertTier.alertTrigger ||
          triggerEvaluation.tier == AlertTier.warning) {
        // alert condition detected — block the driver
        timer.cancel();
        sub?.cancel();
        completer.complete(
          PreDriveResult(
            status: PreDriveStatus.blocked,
            blockedBy: triggerEvaluation.conditionName,
          ),
        );
      }
    });

    return completer.future;
  }

  /// Call this when the driver taps "Cancel" on the pre-drive screen
  void cancel() {
    _cancelled = true;
  }
}
