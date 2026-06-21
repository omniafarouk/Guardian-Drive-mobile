import 'package:guardian_drive_mobile/models/alert_summary.dart';
import 'package:guardian_drive_mobile/models/car.dart';
import 'package:guardian_drive_mobile/models/health_event.dart';

class AlertDetails {
  AlertSummary alertSummary;
  alertStatus status;
  DateTime? solvedAt; // whole alert solved including towing
  Car? car;
  HealthEvent? healthEvent;
  DateTime? requestTime; // emergency service request time
  DateTime? completionTime; // ambulance arrival

  AlertDetails({
    required this.alertSummary,
    required this.status,
    this.solvedAt,
    this.healthEvent,
    this.requestTime,
    this.car,
    this.completionTime,
  });
  alertStatus parseAlertStatus(String? value) {
  return alertStatus.values.firstWhere(
    (e) =>
        e.name.toUpperCase() ==
        value.toString().trim().toUpperCase(),
    orElse: () => alertStatus.ACTIVE,
  );
}
  factory AlertDetails.fromJson(Map<String, dynamic> json) {
    print(json);
    return AlertDetails(
      alertSummary: AlertSummary.fromJson({
        'alertId': json['alertId'],
        'type': json['type'],
        'generatedAt': json['generatedAt'],
        'triggeredLocation': json['triggeredLocation'],
      }),
      status: alertStatus.values.firstWhere((e) => e.name == json['status']),
      solvedAt: json['solvedAt'] != null
          ? DateTime.parse(json['solvedAt'])
          : null,

      healthEvent: json['healthEvent'] != null
          ? HealthEvent.fromJson(json['healthEvent'])
          : null,
      car: json['trip'] != null && json['trip']['car'] != null
          ? Car.fromJson(json['trip']['car'])
          : null,
      requestTime:
          json['emergencyServiceRequest'] != null &&
              json['emergencyServiceRequest']['requestTime'] != null
          ? DateTime.parse(json['emergencyServiceRequest']['requestTime'])
          : null,
      completionTime:
          json['emergencyServiceRequest'] != null &&
              json['emergencyServiceRequest']['completionTime'] != null
          ? DateTime.parse(json['emergencyServiceRequest']['completionTime'])
          : null,
    );
  }
}

enum alertStatus { ACTIVE, RESOLVED }