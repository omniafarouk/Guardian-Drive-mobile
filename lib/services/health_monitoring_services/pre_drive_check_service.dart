import 'dart:async';

import 'package:guardian_drive_mobile/models/continuous_vital_readings.dart';
import 'package:guardian_drive_mobile/models/driver_health_thresholds.dart';
import 'package:guardian_drive_mobile/models/first_aid_guidance.dart';
import 'package:guardian_drive_mobile/services/band_ble_service.dart';
import 'package:guardian_drive_mobile/services/health_monitoring_services/threshold_checker_service.dart';
import 'package:guardian_drive_mobile/services/medical_info_service.dart';
import 'package:guardian_drive_mobile/utils/trace_log.dart';

class PreDriveCheckService {
  final DriverHealthThresholds thresholds;
  final int requiredCleanReadings;

  PreDriveCheckService({
    required this.thresholds,
    this.requiredCleanReadings = 3,
  });

  /// Returns a Future that resolves ONLY when the driver passes.
  /// Never times out — keeps checking until clean streak is reached.
  Future<void> run(Stream<VitalReadings> vitalsStream) async {
    final checker = ThresholdChecker(thresholds);
    final completer = Completer<void>();
    int cleanStreak = 0;

    final sub = vitalsStream.listen((reading) {
      if (completer.isCompleted) return;

      traceLog("pre-drive checking ...", reading.toString());

      final breaches = checker.check(reading);
      final isBad = breaches.any(
        (b) =>
            b.severity == ConditionSeverity.CRITICAL ||
            b.severity == ConditionSeverity.MODERATE,
      );

      if (isBad) {
        cleanStreak = 0;
        traceLog(
          'PreDrive: bad reading, streak reset',
          breaches.map((b) => b.type.name).join(', '),
        );
      } else {
        cleanStreak++;
        traceLog(
          'PreDrive: clean reading',
          '$cleanStreak / $requiredCleanReadings',
        );

        if (cleanStreak >= requiredCleanReadings) {
          completer.complete(); // passed — nothing else fires
        }
      }
    });

    await completer.future; // waits here forever until passed
    await sub.cancel();
  }

  static Future<bool> startPreDriveCheck({
    required DriverHealthThresholds thresholds,
    bool testMode = false,
  }) async {
    final preDriveService = PreDriveCheckService(thresholds: thresholds);

    await preDriveService.run(
      BandBleService.instance.telemetryController.stream,
    );
    // execution only reaches here when driver passes
    traceLog('PreDrive: passed — driver may start trip');
    return true;
  }
}
