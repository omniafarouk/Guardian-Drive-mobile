// models/driver_baseline_with_noise.dart
import 'package:guardian_drive_mobile/models/driver_health_thresholds.dart';

class DriverBaselineWithNoise {
  final double hr, hrNoise;
  final double spo2, spo2Noise;
  final double temp, tempNoise;

  const DriverBaselineWithNoise({
    required this.hr,
    required this.hrNoise,
    required this.spo2,
    required this.spo2Noise,
    required this.temp,
    required this.tempNoise,
  });

  // From your baseline table — replace with the actual driver's stored baseline later
  // The noise is the actual noise that my come from the data from the band

  factory DriverBaselineWithNoise.fromThresholds(
    DriverHealthThresholds thresholds,
  ) {
    return DriverBaselineWithNoise(
      hr: thresholds.avgHeartRate,
      spo2: thresholds.avgSpo2,
      temp: thresholds.avgTemp,
      hrNoise: 1.5, // sensor constant — update if band hardware changes
      spo2Noise: 0.4,
      tempNoise: 0.05,
    );
  }
}
