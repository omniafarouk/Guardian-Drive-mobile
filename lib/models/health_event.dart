// ignore_for_file: public_member_api_docs, sort_constructors_first
// enum HealthStatus { Mild, Moderate, Critical, Normal }

import 'package:guardian_drive_mobile/models/first_aid_guidance.dart';

ConditionSeverity parseHealthStatus(String? value) {
  if (value == null) return ConditionSeverity.NORMAL;
  return ConditionSeverity.values.firstWhere(
    (e) => e.name.toUpperCase() == value.toString().trim().toUpperCase(),
    orElse: () => ConditionSeverity.NORMAL,
  );
}

class HealthEvent {
  double heartRate;
  double bodyTemp;
  double spo2;
  ConditionSeverity heartRateStatus;
  ConditionSeverity tempStatus;
  ConditionSeverity spo2Status;
  HealthEvent({
    required this.heartRate,
    required this.bodyTemp,
    required this.spo2,
    required this.heartRateStatus,
    required this.tempStatus,
    required this.spo2Status,
  });

  factory HealthEvent.fromJson(Map<String, dynamic> json) {
    return HealthEvent(
      heartRate: (json['heartRate'] ?? 0).toDouble(),
      bodyTemp: (json['temp'] ?? 0).toDouble(),
      spo2: (json['spo2'] ?? 0).toDouble(),
      heartRateStatus: parseHealthStatus(json['heartRateStatus']),
      tempStatus: parseHealthStatus(json['tempStatus']),
      spo2Status: parseHealthStatus(json['spo2Status']),
    );
  }
}
