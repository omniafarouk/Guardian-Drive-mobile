// // services/threshold_checker.dart
// import 'package:guardian_drive_mobile/models/condition_breach_data.dart';
// import 'package:guardian_drive_mobile/models/continous_vital_readings.dart';
// import 'package:guardian_drive_mobile/models/driver_health_thresholds.dart';
// import 'package:guardian_drive_mobile/models/first_aid_guidance.dart';

// /// Compares a single VitalReadings against the driver's thresholds and
// /// returns every breach found. Pure function — same input always gives
// /// the same output, making it trivial to unit test.
// class ThresholdChecker {
//   final DriverHealthThresholds thresholds;

//   ThresholdChecker(this.thresholds);

//   List<ConditionBreach> check(VitalReadings reading) {
//     final breaches = <ConditionBreach>[];

//     _checkBound(
//       value: reading.heartRate,
//       min: thresholds.minHeartRate,
//       max: thresholds.maxHeartRate,
//       lowType: ConditionType.LOW_HEART_RATE,
//       highType: ConditionType.HIGH_HEART_RATE,
//       breaches: breaches,
//     );

//     _checkBound(
//       value: reading.spo2,
//       min: thresholds.minSpo2,
//       max: thresholds.maxSpo2,
//       lowType: ConditionType.LOW_SPO2,
//       highType: null, // SpO2 caps at 100% — no HIGH_SPO2 condition exists
//       breaches: breaches,
//     );

//     _checkBound(
//       value: reading.temp,
//       min: thresholds.minTemp,
//       max: thresholds.maxTemp,
//       lowType: ConditionType.LOW_TEMP,
//       highType: ConditionType.HIGH_TEMP,
//       breaches: breaches,
//     );

//     return breaches;
//   }

//   void _checkBound({
//     required double value,
//     required double min,
//     required double max,
//     required ConditionType lowType,
//     ConditionType? highType, // as there is no high spo2 range
//     required List<ConditionBreach> breaches,
//   }) {
//     if (value < min) {
//       breaches.add(
//         ConditionBreach(
//           type: lowType,
//           severity: _classifySeverity(value, min),
//           value: value,
//           thresholdLimit: min,
//         ),
//       );
//     } else if (highType != null && value > max) {
//       breaches.add(
//         ConditionBreach(
//           type: highType,
//           severity: _classifySeverity(value, max),
//           value: value,
//           thresholdLimit: max,
//         ),
//       );
//     }
//   }

//   /// How far outside the limit, as a percentage of the limit itself,
//   /// determines severity. Tune these cutoffs based on clinical input —
//   /// these are reasonable starting defaults, not medically validated.
//   ConditionSeverity _classifySeverity(double value, double limit) {
//     final deviation = (value - limit).abs() / limit;

//     if (deviation > 0.25) return ConditionSeverity.CRITICAL;
//     if (deviation > 0.10) return ConditionSeverity.MODERATE;
//     return ConditionSeverity.MILD;
//   }
// }
