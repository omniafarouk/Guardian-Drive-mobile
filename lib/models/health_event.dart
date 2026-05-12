// ignore_for_file: public_member_api_docs, sort_constructors_first
enum HeartStatus { Critical }

enum BodyTempStatus { Critical, Elevated }

class HealthEvent {
  int eventId;
  DateTime eventDate;
  double heartRate;
  HeartStatus heartStatus;
  double bodyTemp;
  double spo2;
  BodyTempStatus tempStatus;
  HealthEvent({
    required this.eventId,
    required this.eventDate,
    required this.heartRate,
    required this.heartStatus,
    required this.bodyTemp,
    required this.spo2,
    required this.tempStatus,
  });

  factory HealthEvent.fromJson(Map<String, dynamic> json) {
    return HealthEvent(
      eventId: json['eventId'],
      eventDate: DateTime.parse(json['eventDate']),
      heartRate: (json['hearRate'] as num).toDouble(),
      heartStatus: HeartStatus.values.firstWhere((e) => e.name == json['heartStatus']),
      bodyTemp: (json['bodyTemp'] as num).toDouble(),
      spo2: (json['spo2'] as num).toDouble(),
      tempStatus: BodyTempStatus.values.firstWhere((e) => e.name == json['tempStatus']),
    );
  }
}
