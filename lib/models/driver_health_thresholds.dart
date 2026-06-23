// models/driver_health_thresholds.dart

/// The driver's personal normal ranges, fetched once at trip start from Medical Information Table.
/// Mirrors MedicalInformation's min/max fields from the backend.
class DriverHealthThresholds {
  final double minHeartRate;
  final double maxHeartRate;
  final double avgHeartRate;
  final double minSpo2;
  final double maxSpo2;
  final double avgSpo2;
  final double minTemp;
  final double maxTemp;
  final double avgTemp;

  DriverHealthThresholds({
    required this.minHeartRate,
    required this.maxHeartRate,
    required this.minSpo2,
    required this.maxSpo2,
    required this.minTemp,
    required this.maxTemp,
    required this.avgHeartRate,
    required this.avgSpo2,
    required this.avgTemp,
  });

  factory DriverHealthThresholds.fromJson(Map<String, dynamic> json) {
    return DriverHealthThresholds(
      minHeartRate: (json['minHeartRate'] as num).toDouble(),
      maxHeartRate: (json['maxHeartRate'] as num).toDouble(),
      avgHeartRate: (json['avgHeartRate'] as num).toDouble(),
      minSpo2: (json['minSpo2'] as num).toDouble(),
      maxSpo2: (json['maxSpo2'] as num).toDouble(),
      avgSpo2: (json['avgSpo2'] as num).toDouble(),
      minTemp: (json['minTemp'] as num).toDouble(),
      maxTemp: (json['maxTemp'] as num).toDouble(),
      avgTemp: (json['avgTemp'] as num).toDouble(),
    );
  }
}
