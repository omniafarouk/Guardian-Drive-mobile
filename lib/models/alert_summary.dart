import 'package:guardian_drive_mobile/models/location_coords.dart';

class AlertSummary {
  int alertId;
  alertType type;
  DateTime generatedAt;
  LocationCoords triggeredLocation;
  AlertSummary({
    required this.alertId,
    required this.type,
    required this.generatedAt,
    required this.triggeredLocation,
  });
  factory AlertSummary.fromJson(Map<String, dynamic> json) {
    return AlertSummary(
      alertId: json['alertId'],
      type: alertType.values.firstWhere((e) => e.name == json['type']),
      generatedAt: DateTime.parse(json['generatedAt']),
      triggeredLocation: LocationCoords.fromJson(json['triggeredLocation']),
    );
  }
}

enum alertType { HEALTH_ABNORMAL, SOS }