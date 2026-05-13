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
  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      engineId: json['engineId'],
      plateNo: json['plateNo'],
      status: carStatus.values.firstWhere((e) => e.name == json['status']),
      color: json['color'],
    );
  }
}

enum carStatus { ACTIVE, IN_TRIP, DISABLED }
