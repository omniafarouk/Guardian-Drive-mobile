import 'package:guardian_drive_mobile/models/alert.dart';
import 'package:guardian_drive_mobile/models/health_event.dart';
import 'package:guardian_drive_mobile/models/location.dart' as Location;

Alert alert1 = Alert(
  alertId: 1,
  tripId: 1,
  type: alertType.SOS,
  status: alertStatus.RESOLVED,
  locations: [Location.Location(latitude: 1.2878, longitude: 103.8566)],
  generatedAt: DateTime.now(),
  requestTime: DateTime.now(),
  completionTime: DateTime.now(),
  solvedAt: DateTime.now(),
  healthEvent: HealthEvent(
    visitId: 1,
    eventDate: DateTime.now(),
    heartRate: 133,
    heartStatus: HeartStatus.Critical,
    tempStatus: BodyTempStatus.Elevated,
    bodyTemp: 38.5,
  ),
);
