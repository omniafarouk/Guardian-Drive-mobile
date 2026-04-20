class Car {
  String engineId;
  String plateNo;
  String color;
  carStatus status;
  Car({
    required this.engineId,
    required this.plateNo,
    required this.status,
    required this.color,
  });
}

enum carStatus { ACTIVE, IN_TRIP, DISABLED }
