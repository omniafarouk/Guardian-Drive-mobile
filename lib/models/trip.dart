import 'package:guardian_drive_mobile/models/car.dart';

class Trip {
  int tripId;
  String startPoint;
  String destPoint;
  DateTime startTime;
  DateTime? endTime;
  tripStatus status;
  Car car;

  Trip({
    required this.tripId,
    required this.startPoint,
    required this.destPoint,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.car,
  });
}

enum tripStatus { PLANNED, ONGOING, CANCELLED, COMPLETED }
