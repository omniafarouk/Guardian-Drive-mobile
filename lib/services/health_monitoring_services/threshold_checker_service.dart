// services/threshold_checker.dart
import 'package:guardian_drive_mobile/models/condition_breach_data.dart';
import 'package:guardian_drive_mobile/models/continous_vital_readings.dart';
import 'package:guardian_drive_mobile/models/driver_health_thresholds.dart';
import 'package:guardian_drive_mobile/models/first_aid_guidance.dart';

/// Compares a single VitalReadings against the driver's thresholds and
/// pure logic, stateless, called on EVERY reading
class ThresholdChecker {
  final DriverHealthThresholds thresholds;

  ThresholdChecker(this.thresholds);

  List<ConditionBreach> check(VitalReadings reading) {
    final breaches = <ConditionBreach>[];

    _checkBound(
      value: reading.heartRate,
      min: thresholds.minHeartRate,
      max: thresholds.maxHeartRate,
      avg: thresholds.avgHeartRate,
      lowType: ConditionType.LOW_HEART_RATE,
      highType: ConditionType.HIGH_HEART_RATE,
      breaches: breaches,
    );

    _checkBound(
      value: reading.spo2,
      min: thresholds.minSpo2,
      max: thresholds.maxSpo2,
      avg: thresholds.avgSpo2,
      lowType: ConditionType.LOW_SPO2,
      highType: null, // SpO2 caps at 100% — no HIGH_SPO2 condition exists
      breaches: breaches,
    );

    _checkBound(
      value: reading.temp,
      min: thresholds.minTemp,
      max: thresholds.maxTemp,
      avg: thresholds.avgTemp,
      lowType: ConditionType.LOW_TEMP,
      highType: ConditionType.HIGH_TEMP,
      breaches: breaches,
    );

    return breaches;
  }

  // check bound , checks if it bad reading
  void _checkBound({
    required double value,
    required double min,
    required double max,
    required double avg,
    required ConditionType lowType,
    ConditionType? highType, // as there is no high spo2 range
    required List<ConditionBreach> breaches,
  }) {
    if (value < min) {
      breaches.add(
        ConditionBreach(
          type: lowType,
          severity: _classifySeverity(value, avg),
          value: value,
          baselineBreached: min,
        ),
      );
    } else if (highType != null && value > max) {
      // highType might be null as there is no HIGH_SPO2 XX
      breaches.add(
        ConditionBreach(
          type: highType,
          severity: _classifySeverity(value, avg),
          value: value,
          baselineBreached: max,
        ),
      );
    }
  }

  /// How far outside the limit, as a percentage of the limit itself,
  /// determines severity. Tune these cutoffs based on clinical input —
  /// these are reasonable starting defaults, not medically validated.

  //  ----------- changed to match the pattern matcher logic somewhat ---------------
  ConditionSeverity _classifySeverity(
    double value,
    double avgBaseline, // the driver's typical value — used for severity
  ) {
    // How far from NORMAL (avg), not from the limit
    final deviation = (value - avgBaseline).abs() / avgBaseline;

    if (deviation > 0.25) return ConditionSeverity.CRITICAL;
    if (deviation > 0.10) return ConditionSeverity.MODERATE;
    return ConditionSeverity.NORMAL;
  }

  // ConditionSeverity _classifySeverity(double value, double limit) {
  //   final deviation = (value - limit).abs() / limit;

  //   if (deviation > 0.25) return ConditionSeverity.CRITICAL;
  //   if (deviation > 0.10) return ConditionSeverity.MODERATE;
  //   return ConditionSeverity.NORMAL;
  // }
}
