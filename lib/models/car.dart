
import 'dart:convert';
import 'package:guardian_drive_mobile/models/trip.dart';

Car carFromJson(String str) => Car.fromJson(json.decode(str));

String carToJson(Car data) => json.encode(data.toJson());

class Car {
  String engineId;
  String plateNo;
  String color;
  String status;
  List<Trip> trips;

  Car({
    required this.engineId,
    required this.plateNo,
    required this.color,
    required this.status,
    required this.trips,
  });

  factory Car.fromJson(Map<String, dynamic> json) => Car(
    engineId: json["engineId"],
    plateNo: json["plateNo"],
    color: json["color"],
    status: carStatus.values.firstWhere((e) => e.name == json['status']),
    trips: List<Trip>.from(json["trips"].map((x) => Trip.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "engineId": engineId,
    "plateNo": plateNo,
    "color": color,
    "status": status,
    "trips": List<dynamic>.from(trips.map((x) => x.toJson())),
  };
}
enum carStatus { ACTIVE, IN_TRIP, DISABLED }
