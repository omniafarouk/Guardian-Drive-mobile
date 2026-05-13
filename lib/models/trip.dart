import 'dart:ffi';

import 'package:guardian_drive_mobile/models/car.dart';

class Trip {
  int tripId;
  int? driverId;
  int fleetManagerId;
  DateTime plannedStartTime;
  DateTime? startTime;
  DateTime? endTime;
  TripStatus status;
  String? engineId;
  double startLatitude;
  double startLongitude;
  double destLatitude;
  double destLongitude;

  Trip({
    required this.tripId,
    this.driverId,
    required this.fleetManagerId,
    required this.plannedStartTime,
    this.startTime,
    this.endTime,
    required this.status,
    this.engineId,
    required this.startLatitude,
    required this.startLongitude,
    required this.destLatitude,
    required this.destLongitude,
  });
  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
    tripId: json["tripId"],
    startLatitude: json["startLatitude"]?.toDouble(),
    startLongitude: json["startLongitude"]?.toDouble(),
    destLatitude: json["destLatitude"]?.toDouble(),
    destLongitude: json["destLongitude"]?.toDouble(),
    plannedStartTime: DateTime.parse(json["plannedStartTime"]),
    startTime: json["startTime"] != null
        ? DateTime.parse(json["startTime"])
        : null,

    endTime: json["endTime"] != null ? DateTime.parse(json["endTime"]) : null,
    status: tripStatusFromString(json["status"]),
    driverId: json["driverId"],
    engineId: json["engineId"],
    fleetManagerId: json["fleetManagerId"],
  );

  Map<String, dynamic> toJson() => {
    "tripId": tripId,
    "startLatitude": startLatitude,
    "startLongitude": startLongitude,
    "destLatitude": destLatitude,
    "destLongitude": destLongitude,
    "plannedStartTime": plannedStartTime.toIso8601String(),
    "startTime": startTime?.toIso8601String(),
    "endTime": endTime?.toIso8601String(),
    "status": status.name,
    "driverId": driverId,
    "engineId": engineId,
    "fleetManagerId": fleetManagerId,
  };
}

enum TripStatus { PLANNED, ONGOING, CANCELLED, COMPLETED }

TripStatus tripStatusFromString(String status) {
  return TripStatus.values.firstWhere((e) => e.name == status);
}
