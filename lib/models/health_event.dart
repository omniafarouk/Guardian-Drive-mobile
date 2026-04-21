// ignore_for_file: public_member_api_docs, sort_constructors_first
enum HeartStatus{
  Critical,

}

enum BodyTempStatus{
  Critical,
  Elevated, 
}
class HealthEvent {
  int visitId;
  DateTime eventDate;
  double heartRate;
  HeartStatus heartStatus;
  double bodyTemp;
  BodyTempStatus tempStatus;
  HealthEvent({
    required this.visitId,
    required this.eventDate,
    required this.heartRate,
    required this.heartStatus,
    required this.bodyTemp,
    required this.tempStatus,
  });
}