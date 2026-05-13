// To parse this JSON data, do
//
//     final tripResponse = tripResponseFromJson(jsonString);

import 'dart:convert';
import 'package:guardian_drive_mobile/models/trip.dart';
TripsResponse tripResponseFromJson(String str) => TripsResponse.fromJson(json.decode(str));

String tripsResponseToJson(TripsResponse data) => json.encode(data.toJson());

class TripsResponse {
  int page;
  int limit;
  int total;
  int totalPages;
  List<Trip> trips;

  TripsResponse({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.trips,
  });

  factory TripsResponse.fromJson(Map<String, dynamic> json) => TripsResponse(
    page: json["page"],
    limit: json["limit"],
    total: json["total"],
    totalPages: json["totalPages"],
    trips: List<Trip>.from(json["trips"].map((x) => Trip.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "page": page,
    "limit": limit,
    "total": total,
    "totalPages": totalPages,
    "trips": List<dynamic>.from(trips.map((x) => x.toJson())),
  };
}
