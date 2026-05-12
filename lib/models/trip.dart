import 'dart:ffi';

import 'package:guardian_drive_mobile/models/car.dart';

class Trip {
  int tripId;
  DateTime startTime;
  DateTime? endTime;
  tripStatus status;
  Car car;
  double startLatitude;
  double startLongitude;
  double destLatitude;
  double destLongitude;

  Trip({
    required this.tripId,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.car,
    required this.startLatitude,
    required this.startLongitude,
    required this.destLatitude,
    required this.destLongitude
  });
}

enum tripStatus { PLANNED, ONGOING, CANCELLED, COMPLETED }