// services/threshold_checker.dart
import 'package:guardian_drive_mobile/models/condition_breach_data.dart';
import 'package:guardian_drive_mobile/models/continuous_vital_readings.dart';
import 'package:guardian_drive_mobile/models/driver_health_thresholds.dart';
import 'package:guardian_drive_mobile/models/first_aid_guidance.dart';

/// Compares a single VitalReadings against the driver's thresholds and
/// pure logic, stateless, called on EVERY reading
class ThresholdChecker {
  final DriverHealthThresholds thresholds;

  ThresholdChecker(this.thresholds);

  List<ConditionBreach> check(VitalReadings reading) {
    final breaches = <ConditionBreach>[];

    // the warning buffer is the data noise that may come from the database
    // so the critical case of just equals to the critical data (min/max) would trigger a warning
    // past these data would trigger an alert

    _checkBound(
      value: reading.heartRate,
      min: thresholds.minHeartRate,
      max: thresholds.maxHeartRate,
      avg: thresholds.avgHeartRate,
      warningBuffer: 1.5,
      lowType: ConditionType.LOW_HEART_RATE,
      highType: ConditionType.HIGH_HEART_RATE,
      breaches: breaches,
    );

    _checkBound(
      value: reading.spo2,
      min: thresholds.minSpo2 - 0.4,
      max: thresholds.maxSpo2,
      avg: thresholds.avgSpo2,
      warningBuffer: 0,
      lowType: ConditionType.LOW_SPO2,
      highType: null, // SpO2 caps at 100% — no HIGH_SPO2 condition exists
      breaches: breaches,
    );

    _checkBound(
      value: reading.temp,
      min: thresholds.minTemp,
      max: thresholds.maxTemp,
      avg: thresholds.avgTemp,
      warningBuffer: 0.05,
      lowType: ConditionType.LOW_TEMP,
      highType: ConditionType.HIGH_TEMP,
      breaches: breaches,
    );

    return breaches;
  }

  void _checkBound({
    required double value,
    required double min,
    required double max,
    required double avg,
    required double warningBuffer, // ← add this
    required ConditionType lowType,
    ConditionType? highType,
    required List<ConditionBreach> breaches,
  }) {
    if (value < min) {
      // past the limit → alert
      breaches.add(
        ConditionBreach(
          type: lowType,
          severity: ConditionSeverity.CRITICAL,
          value: value,
          baselineBreached: min,
        ),
      );
    } else if (value <= min + warningBuffer) {
      // inside warning zone → warning
      breaches.add(
        ConditionBreach(
          type: lowType,
          severity: ConditionSeverity.MODERATE,
          value: value,
          baselineBreached: min,
        ),
      );
    }
    // same mirror logic for high side
    if (highType != null) {
      if (value > max) {
        breaches.add(
          ConditionBreach(
            type: highType,
            severity: ConditionSeverity.CRITICAL,
            value: value,
            baselineBreached: max,
          ),
        );
      } else if (value >= max - warningBuffer) {
        breaches.add(
          ConditionBreach(
            type: highType,
            severity: ConditionSeverity.MODERATE,
            value: value,
            baselineBreached: max,
          ),
        );
      }
    }
  }
}
