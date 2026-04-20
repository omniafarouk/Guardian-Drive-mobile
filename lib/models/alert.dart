import 'package:guardian_drive_mobile/models/health_event.dart';
import 'package:guardian_drive_mobile/models/location.dart';

class Alert {
  alertType type;
  List<Location> locations; // latitude and longitude
  alertStatus status;
  DateTime generatedAt;
  DateTime? solvedAt;
  HealthEvent? healthEvent;
  DateTime? requestTime;
  DateTime? completionTime;

  int alertId;
  int tripId;
  String? locationName;
  Alert({
    required this.alertId,
    required this.tripId,
    required this.type,
    required this.status,
    required this.locations,
    required this.generatedAt,
    this.healthEvent,
    required this.solvedAt,
    this.requestTime,
    this.completionTime,
    this.locationName,
  });
}

enum alertStatus { ACTIVE, RESOLVED }

enum alertType { HEALTH_ABNORMAL, SOS, VEHICLE_EMERGENCY }
