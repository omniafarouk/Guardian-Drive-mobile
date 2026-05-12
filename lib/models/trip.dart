import 'package:guardian_drive_mobile/models/car.dart';

class Trip {
  int tripId;
  double startLatitude;
  double startLongitude;
  double destLatitude;
  double destLongitude;
  Car car;
  
  Trip({
    required this.tripId,
    required this.car,
    required this.startLatitude,
    required this.startLongitude,
    required this.destLatitude,
    required this.destLongitude,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      tripId: json['tripId'],
      car: Car.fromJson(json['car']),
      startLatitude: json['startLatitude'],
      startLongitude: json['startLongitude'],
      destLatitude: json['destLatitude'],
      destLongitude: json['destLongitude'],
    );
  }
}

enum tripStatus { PLANNED, ONGOING, CANCELLED, COMPLETED }
