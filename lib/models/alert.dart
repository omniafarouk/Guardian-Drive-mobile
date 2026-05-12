import 'package:guardian_drive_mobile/models/health_event.dart';
import 'package:guardian_drive_mobile/models/location.dart';

class Alert {
  
  int alertId;
  alertType type;
  alertStatus status;

  DateTime generatedAt;
  DateTime? solvedAt;  // whole alert solved including towing 

  Trip? trip;

  int triggeredLocationId;
  Location triggeredLocation;
  
  int? stoppedLocationId;
  Location? stoppedLocation;

  HealthEvent? healthEvent;
  DateTime? requestTime; // emergency service request time
  DateTime? completionTime; // ambulance arrival

  Alert({
    required this.alertId,
    required this.type,
    required this.status,
    required this.generatedAt,
    this.solvedAt,
    required this.triggeredLocationId,
    required this.triggeredLocation,
    this.stoppedLocationId,
    this.stoppedLocation,
    this.healthEvent,
    this.requestTime,
    this.completionTime,
  });

  factory Alert.fromJson(Map<String, dynamic> json){
    return Alert(
      alertId: json['alertId'],
      type: alertType.values.firstWhere((e)=> e.name == json['type']),
      status: alertStatus.values.firstWhere((e)=> e.name == json['status']),
      generatedAt: DateTime.parse(json['generatedAt']),
      completionTime: json['completionTime'] != null ? DateTime.parse(json['completionTime']): null,
      solvedAt: json['solvedAt'] != null? DateTime.parse(json['solvedAt']): null,
      tripId: json['tripId'],
      triggeredLocationId: json['triggeredLocationId'],
      triggeredLocation: Location.fromJson(json['triggeredLocation']), 
      stoppedLocationId: json['stoppedLocationId'],
      stoppedLocation: json['stoppedLocation'] != null? Location.fromJson(json['stoppedLocation']) : null,
      healthEvent: json['healthEvent'] != null ? HealthEvent.fromJson(json['healthEvent']): null,
      trip: json['trip'] != null
          ? Trip.fromJson(json['trip']) : null,
      );
  }

}

enum alertStatus { ACTIVE, RESOLVED }

enum alertType { HEALTH_ABNORMAL, SOS, VEHICLE_EMERGENCY }
