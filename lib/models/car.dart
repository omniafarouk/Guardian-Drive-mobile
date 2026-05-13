// class Car {
//   String engineId;
//   String plateNo;
//   String color;
//   carStatus status;
//   Car({
//     required this.engineId,
//     required this.plateNo,
//     required this.status,
//     required this.color,
//   });
// }
// To parse this JSON data, do
//
//     final car = carFromJson(jsonString);

// import 'dart:convert';
// import 'package:guardian_drive_mobile/models/trip.dart';
// Car carFromJson(String str) => Car.fromJson(json.decode(str));
//
// String carToJson(Car data) => json.encode(data.toJson());
//
// class Car {
//   CarClass car;
//
//   Car({
//     required this.car,
//   });
//
//   factory Car.fromJson(Map<String, dynamic> json) => Car(
//     car: CarClass.fromJson(json["car"]),
//   );
//
//   Map<String, dynamic> toJson() => {
//     "car": car.toJson(),
//   };
// }
//
// class CarClass {
//   String engineId;
//   String plateNo;
//   String color;
//   String status;
//   List<Trip> trips;
//
//   CarClass({
//     required this.engineId,
//     required this.plateNo,
//     required this.color,
//     required this.status,
//     required this.trips,
//   });
//
//   factory CarClass.fromJson(Map<String, dynamic> json) => CarClass(
//     engineId: json["engineId"],
//     plateNo: json["plateNo"],
//     color: json["color"],
//     status: json["status"],
//     trips: List<Trip>.from(json["trips"].map((x) => Trip.fromJson(x))),
//   );
//
//   Map<String, dynamic> toJson() => {
//     "engineId": engineId,
//     "plateNo": plateNo,
//     "color": color,
//     "status": status,
//     "trips": List<dynamic>.from(trips.map((x) => x.toJson())),
//   };
// }
// To parse this JSON data, do
//
//     final car = carFromJson(jsonString);

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
    status: json["status"],
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
