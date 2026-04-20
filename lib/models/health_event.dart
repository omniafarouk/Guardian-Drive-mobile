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
  BodyTempStatus tempStatus;
  double bodyTemp;
  HealthEvent({
    required this.visitId,
    required this.eventDate,
    required this.heartRate,
    required this.heartStatus,
    required this.tempStatus,
    required this.bodyTemp,
  });
}