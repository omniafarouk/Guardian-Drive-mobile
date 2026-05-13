import 'package:guardian_drive_mobile/models/health_event.dart';
import 'package:guardian_drive_mobile/models/location.dart';

class Alert {
  alertType type;
  List<Location> locations; // latitude and longitude
  alertStatus status;
  DateTime generatedAt;
  DateTime? solvedAt; // whole alert solved including towing
  HealthEvent? healthEvent;
  DateTime? requestTime; // emergency service request time
  DateTime? completionTime; // ambulance arrival

  int alertId;
  int tripId;

  Alert({
    required this.alertId,
    required this.tripId,
    required this.type,
    required this.status,
    required this.locations,
    required this.generatedAt,
    this.healthEvent,
    this.solvedAt,
    this.requestTime,
    this.completionTime,
  });
}

enum alertStatus { ACTIVE, RESOLVED }

enum alertType { HEALTH_ABNORMAL, SOS, VEHICLE_EMERGENCY }
