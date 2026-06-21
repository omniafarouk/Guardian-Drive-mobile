
import 'dart:convert';
import 'package:guardian_drive_mobile/models/trip.dart';

Car carFromJson(String str) => Car.fromJson(json.decode(str));

String carToJson(Car data) => json.encode(data.toJson());

class Car {
  String engineId;
  String plateNo;
  String color;
  String status;

  Car({
    required this.engineId,
    required this.plateNo,
    required this.color,
    required this.status,
  });

  factory Car.fromJson(Map<String, dynamic> json) => Car(
    engineId: json["engineId"],
    plateNo: json["plateNo"],
    color: json["color"],
    status: json['status'],
  );

  Map<String, dynamic> toJson() => {
    "engineId": engineId,
    "plateNo": plateNo,
    "color": color,
    "status": status,
  };
}
enum carStatus { ACTIVE, IN_TRIP, DISABLED }
