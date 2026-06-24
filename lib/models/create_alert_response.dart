import 'package:guardian_drive_mobile/models/first_aid_guidance.dart';
import 'package:guardian_drive_mobile/models/health_event.dart';
import 'package:guardian_drive_mobile/models/location.dart';

class AlertResponse {
  alertType type;
  DateTime generatedAt;

  int triggeredLocationId;
  Location triggeredLocation;
  int? stoppedLocationId;
  Location? stoppedLocation;

  HealthEvent? healthEvent;
  FirstAidGuidance guidances;

  AlertResponse({
    required this.type,
    required this.generatedAt,
    required this.triggeredLocationId,
    required this.triggeredLocation,
    this.stoppedLocationId,
    this.stoppedLocation,
    this.healthEvent,
    required this.guidances,
  });

  factory AlertResponse.fromJson(Map<String, dynamic> json) {
    return AlertResponse(
      type: alertType.values.firstWhere((e) => e.name == json['type']),
      generatedAt: DateTime.parse(json['generatedAt']),
      triggeredLocationId: json['triggeredLocationId'],
      triggeredLocation: Location.fromJson(json['triggeredLocation']),
      stoppedLocationId: json['stoppedLocationId'],
      stoppedLocation: json['stoppedLocation'] != null
          ? Location.fromJson(json['stoppedLocation'])
          : null,
      healthEvent: json['healthEvent'] != null
          ? HealthEvent.fromJson(json['healthEvent'])
          : null,
      guidances: json['guidanceStrings'],
    );
  }
}

enum alertStatus { ACTIVE, RESOLVED }

enum alertType { HEALTH_ABNORMAL, SOS, VEHICLE_EMERGENCY }
